import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {

    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var celularTextField: UITextField!
    @IBOutlet weak var contrasenaTextField: UITextField!
    // Nota: Asegúrate de que en el Storyboard este Outlet se llame exactamente así
    @IBOutlet weak var confirmarContraseniaTextFiel: UITextField!
    @IBOutlet weak var terminosCheckbox: UIButton!
    
    @IBOutlet private var camposConBorde: [UIView]?

    // MARK: - Actions
    @IBAction func volverAtras(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func irIniciarSesion(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func registrarTappet(_ sender: UIButton) {
        // 1. Validación de campos
        guard let email = emailTextField.text, !email.isEmpty,
              let password = contrasenaTextField.text, !password.isEmpty,
              let nombre = nombreTextField.text, !nombre.isEmpty,
              let celular = celularTextField.text, !celular.isEmpty,
              let confirmPassword = confirmarContraseniaTextFiel.text,
              password == confirmPassword else {
            mostrarAlerta(titulo: "Datos Incompletos", mensaje: "Por favor completa todos los campos y asegúrate de que las contraseñas coincidan.")
            return 
        }

        // 2. Crear usuario en Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in 
            if let e = error {
                self?.mostrarAlerta(titulo: "Error de Registro", mensaje: e.localizedDescription)
                return
            }

            // 3. Guardar en Firestore y Core Data usando ControladorPersistencia
            if let userId = authResult?.user.uid {
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
                            print("Registro y guardado sincronizado exitoso (Nube y Local)")
                            // 4. Cerrar sesión de Firebase y volver al Login para validación manual
                            try? Auth.auth().signOut()
                            let alerta = UIAlertController(
                                title: "¡Registro Exitoso!",
                                message: "Tu cuenta fue creada correctamente. Inicia sesión con tus nuevas credenciales para continuar.",
                                preferredStyle: .alert
                            )
                            let accionContinuar = UIAlertAction(title: "Ir a Iniciar Sesión", style: .default) { _ in
                                // Regresa al LoginViewController (validación manual de credenciales)
                                self?.navigationController?.popViewController(animated: true)
                            }
                            alerta.addAction(accionContinuar)
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
        
        // Evitar que iOS muestre el modal de "Contraseña Fuerte"
        contrasenaTextField.textContentType = .oneTimeCode
        confirmarContraseniaTextFiel.textContentType = .oneTimeCode
        
        // Alinear verticalmente el placeholder "Celular"
        celularTextField.contentVerticalAlignment = .center
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
                // Usamos el mismo color para que sea consistente con aplicarBordeContenedor
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

// MARK: - Extensions
extension UIView {
    @IBInspectable var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}