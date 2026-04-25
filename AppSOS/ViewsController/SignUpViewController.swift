import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {

    // MARK: - Outlets de campos
    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var celularTextField: UITextField!
    @IBOutlet weak var contrasenaTextField: UITextField!
    @IBOutlet weak var confirmarContraseniaTextFiel: UITextField!
    @IBOutlet weak var terminosCheckbox: UIButton!

    @IBOutlet private var camposConBorde: [UIView]?

    // MARK: - Labels de error (creados dinámicamente)
    private var lblErrorNombre: UILabel!
    private var lblErrorEmail: UILabel!
    private var lblErrorCelular: UILabel!
    private var lblErrorContrasena: UILabel!
    private var lblErrorConfirmar: UILabel!

    // MARK: - Actions
    @IBAction func volverAtras(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func irIniciarSesion(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func registrarTappet(_ sender: UIButton) {
        guard validarCampos() else { return }

        let email    = emailTextField.text!
        let password = contrasenaTextField.text!
        let nombre   = nombreTextField.text!
        let celular  = celularTextField.text!

        // Crear usuario en Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let e = error {
                self?.mostrarAlerta(titulo: "Error de Registro", mensaje: e.localizedDescription)
                return
            }

            guard let userId = authResult?.user.uid else { return }

            // Guardar en Firestore + Core Data
            ControladorPersistencia.compartido.sincronizarUsuario(
                id: userId,
                nombre: nombre,
                email: email,
                celular: celular,
                pais: "+51",
                rol: "cliente"
            ) { exito, errorDeSincronizacion in
                DispatchQueue.main.async {
                    if let e = errorDeSincronizacion {
                        self?.mostrarAlerta(titulo: "Error al Sincronizar", mensaje: e.localizedDescription)
                    } else if exito {
                        print("Registro y sincronización exitosos (Firestore + Core Data)")
                        try? Auth.auth().signOut()
                        let alerta = UIAlertController(
                            title: "¡Registro Exitoso! 🎉",
                            message: "Tu cuenta fue creada correctamente.\nInicia sesión con tus nuevas credenciales para continuar.",
                            preferredStyle: .alert
                        )
                        alerta.addAction(UIAlertAction(title: "Ir a Iniciar Sesión", style: .default) { _ in
                            self?.navigationController?.popViewController(animated: true)
                        })
                        self?.present(alerta, animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarEstilos()
        configurarLabelsError()

        // Evitar modal de "Contraseña Fuerte" de iOS
        contrasenaTextField.textContentType          = .oneTimeCode
        confirmarContraseniaTextFiel.textContentType = .oneTimeCode

        // Alinear verticalmente el placeholder "Celular"
        celularTextField.contentVerticalAlignment = .center

        // Validación en tiempo real al escribir
        [nombreTextField, emailTextField, celularTextField,
         contrasenaTextField, confirmarContraseniaTextFiel].forEach {
            $0?.addTarget(self, action: #selector(campoEditado(_:)), for: .editingChanged)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Validación en tiempo real
    @objc private func campoEditado(_ sender: UITextField) {
        // Solo limpiar el error del campo que se está editando
        switch sender {
        case nombreTextField:         limpiarError(lblErrorNombre,    en: sender)
        case emailTextField:          limpiarError(lblErrorEmail,     en: sender)
        case celularTextField:        limpiarError(lblErrorCelular,   en: sender)
        case contrasenaTextField:     limpiarError(lblErrorContrasena, en: sender)
        case confirmarContraseniaTextFiel: limpiarError(lblErrorConfirmar, en: sender)
        default: break
        }
    }

    private func limpiarError(_ label: UILabel?, en campo: UITextField) {
        label?.isHidden = true
        // Restaurar borde normal al empezar a escribir
        campo.superview?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        campo.superview?.layer.borderWidth = 1.0
    }

    // MARK: - Validación completa
    /// Valida todos los campos y muestra mensajes en rojo bajo cada uno.
    /// Devuelve true si todos son válidos.
    @discardableResult
    private func validarCampos() -> Bool {
        var valido = true

        let nombre    = nombreTextField.text ?? ""
        let email     = emailTextField.text ?? ""
        let celular   = celularTextField.text ?? ""
        let password  = contrasenaTextField.text ?? ""
        let confirmar = confirmarContraseniaTextFiel.text ?? ""

        // Nombre
        if nombre.trimmingCharacters(in: .whitespaces).isEmpty {
            mostrarError(lblErrorNombre, en: nombreTextField, mensaje: "El nombre es obligatorio.")
            valido = false
        } else {
            ocultarError(lblErrorNombre, en: nombreTextField)
        }

        // Email
        if email.isEmpty {
            mostrarError(lblErrorEmail, en: emailTextField, mensaje: "El correo no puede estar vacío.")
            valido = false
        } else if !esEmailValido(email) {
            mostrarError(lblErrorEmail, en: emailTextField, mensaje: "Formato de correo inválido.")
            valido = false
        } else {
            ocultarError(lblErrorEmail, en: emailTextField)
        }

        // Celular
        if celular.trimmingCharacters(in: .whitespaces).isEmpty {
            mostrarError(lblErrorCelular, en: celularTextField, mensaje: "El celular es obligatorio.")
            valido = false
        } else if celular.count < 7 {
            mostrarError(lblErrorCelular, en: celularTextField, mensaje: "Número de celular muy corto.")
            valido = false
        } else {
            ocultarError(lblErrorCelular, en: celularTextField)
        }

        // Contraseña
        if password.count < 6 {
            mostrarError(lblErrorContrasena, en: contrasenaTextField, mensaje: "Mínimo 6 caracteres.")
            valido = false
        } else {
            ocultarError(lblErrorContrasena, en: contrasenaTextField)
        }

        // Confirmar contraseña (orden correcto: primero vacío, luego no coincide)
        if confirmar.isEmpty {
            mostrarError(lblErrorConfirmar, en: confirmarContraseniaTextFiel, mensaje: "Confirma tu contraseña.")
            valido = false
        } else if confirmar != password {
            mostrarError(lblErrorConfirmar, en: confirmarContraseniaTextFiel, mensaje: "Las contraseñas no coinciden.")
            valido = false
        } else {
            ocultarError(lblErrorConfirmar, en: confirmarContraseniaTextFiel)
        }

        return valido
    }

    // MARK: - Helpers de error
    private func esEmailValido(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func mostrarError(_ label: UILabel?, en campo: UITextField, mensaje: String) {
        label?.text = mensaje
        label?.isHidden = false
        // Borde rojo en el contenedor del campo
        campo.superview?.layer.borderColor = WayraTheme.brand.cgColor
        campo.superview?.layer.borderWidth = 1.5
    }

    private func ocultarError(_ label: UILabel?, en campo: UITextField) {
        label?.isHidden = true
        campo.superview?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        campo.superview?.layer.borderWidth = 1.0
    }

    // MARK: - Labels de error dinámicos
    private func configurarLabelsError() {
        lblErrorNombre     = crearYAnclarLabel(en: nombreTextField)
        lblErrorEmail      = crearYAnclarLabel(en: emailTextField)
        lblErrorCelular    = crearYAnclarLabel(en: celularTextField)
        lblErrorContrasena = crearYAnclarLabel(en: contrasenaTextField)
        lblErrorConfirmar  = crearYAnclarLabel(en: confirmarContraseniaTextFiel)
    }

    private func crearYAnclarLabel(en campo: UITextField?) -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = WayraTheme.brand
        lbl.numberOfLines = 1
        lbl.isHidden = true

        guard let campo = campo, let contenedor = campo.superview else { return lbl }
        contenedor.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: contenedor.leadingAnchor, constant: 8),
            lbl.trailingAnchor.constraint(equalTo: contenedor.trailingAnchor, constant: -8),
            lbl.bottomAnchor.constraint(equalTo: contenedor.bottomAnchor, constant: -3)
        ])
        return lbl
    }

    // MARK: - UI Helpers
    private func configurarEstilos() {
        view.aplicarFondoRosadoRadial()

        if let cajas = camposConBorde, !cajas.isEmpty {
            cajas.forEach { $0.aplicarBordeContenedor() }
        } else {
            aplicarBordeGrisAContenedoresDeCampos(en: view)
        }

        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
    }

    private func aplicarBordeGrisAContenedoresDeCampos(en root: UIView) {
        for sub in root.subviews {
            if sub.layer.cornerRadius >= 12, sub.layer.borderWidth >= 1,
               sub.subviews.contains(where: { $0 is UIStackView }) {
                sub.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
            }
            aplicarBordeGrisAContenedoresDeCampos(en: sub)
        }
    }

    // MARK: - Alertas
    private func mostrarAlerta(titulo: String, mensaje: String) {
        DispatchQueue.main.async {
            let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alerta, animated: true)
        }
    }
}