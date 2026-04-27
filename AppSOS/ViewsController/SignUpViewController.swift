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

    @IBOutlet var camposConBorde: [UIView]!
    private var haIntentadoEnviar = false
    private var placeholdersOriginales: [UITextField: String] = [:]

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

    @IBAction func registrarTapped(_ sender: Any) {
        haIntentadoEnviar = true
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

            // Preparamos el payload y guardamos en Firestore
            let datosUsuario: [String: Any] = [
                "nombre": nombre,
                "email": email,
                "celular": celular,
                "rol": "cliente",
                "is_active": true
            ]
            
            FirebaseManager.shared.crearUsuario(uid: userId, datos: datosUsuario) { errorFs in
                // Guardar en Core Data (Sincronización local)
                ControladorPersistencia.compartido.sincronizarUsuario(
                    id: userId, nombre: nombre, email: email, celular: celular, pais: "+51", rol: "cliente"
                ) { exito, errorDeSincronizacion in
                    DispatchQueue.main.async {
                        if let e = errorDeSincronizacion ?? errorFs {
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
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Validación en tiempo real
    @objc private func campoEditado(_ sender: UITextField) {
        // Si ya intentó enviar, validamos en tiempo real. 
        // Si no, solo limpiamos el error si existía.
        if haIntentadoEnviar {
            _ = validarCampos()
        } else {
            switch sender {
            case nombreTextField:         limpiarError(lblErrorNombre,    en: sender)
            case emailTextField:          limpiarError(lblErrorEmail,     en: sender)
            case celularTextField:        limpiarError(lblErrorCelular,   en: sender)
            case contrasenaTextField:     limpiarError(lblErrorContrasena, en: sender)
            case confirmarContraseniaTextFiel: limpiarError(lblErrorConfirmar, en: sender)
            default: break
            }
        }
    }

    private func limpiarError(_ label: UILabel?, en campo: UITextField) {
        label?.isHidden = true
        
        // Restaurar placeholder si existía
        if let original = placeholdersOriginales[campo] {
            campo.placeholder = original
        }

        // El contenedor real es el superview del stackview (SU-nm-bg, etc.)
        let contenedor = campo.superview?.superview ?? campo.superview
        contenedor?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        contenedor?.layer.borderWidth = 1.0
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
        
        // Guardar y ocultar placeholder
        if let placeholder = campo.placeholder, !placeholder.isEmpty {
            placeholdersOriginales[campo] = placeholder
        }
        campo.placeholder = nil
        
        // Borde rojo en el contenedor real
        let contenedor = campo.superview?.superview ?? campo.superview
        contenedor?.layer.borderColor = WayraTheme.brand.cgColor
        contenedor?.layer.borderWidth = 1.5
    }

    private func ocultarError(_ label: UILabel?, en campo: UITextField) {
        label?.isHidden = true
        
        // Restaurar placeholder
        if let original = placeholdersOriginales[campo] {
            campo.placeholder = original
        }
        
        let contenedor = campo.superview?.superview ?? campo.superview
        contenedor?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        contenedor?.layer.borderWidth = 1.0
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
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = WayraTheme.brand
        lbl.numberOfLines = 0
        lbl.isHidden = true

        guard let campo = campo, 
              let contenedor = campo.superview?.superview, 
              let stackView = contenedor.superview as? UIStackView else { 
            return lbl 
        }
        
        // Insertamos el label justo después del contenedor del campo en el StackView
        if let index = stackView.arrangedSubviews.firstIndex(of: contenedor) {
            stackView.insertArrangedSubview(lbl, at: index + 1)
            
            // Ajustar espaciado personalizado para que el error esté pegado al campo
            stackView.setCustomSpacing(4, after: contenedor)
            stackView.setCustomSpacing(16, after: lbl)
        }
        
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