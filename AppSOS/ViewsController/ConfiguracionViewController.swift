import UIKit
import FirebaseAuth

class ConfiguracionViewController: UIViewController {

    @IBOutlet weak var lblTitulo: UILabel!
    @IBOutlet weak var lblNombreUsuario: UILabel!
    @IBOutlet weak var lblCorreoUsuario: UILabel!
    @IBOutlet weak var imgPerfil: UIImageView!
    @IBOutlet weak var btnInformacionPersonal: UIButton!
    @IBOutlet weak var btnMisVehiculos: UIButton!
    @IBOutlet weak var btnPagosCobros: UIButton!
    @IBOutlet weak var btnCentroAyuda: UIButton!
    @IBOutlet weak var btnPrivacidadSeguridad: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarDatosUsuario()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.aplicarFondoRosadoRadial()
        navigationItem.title = "Configuración"
        
        lblTitulo.text = "Configuración"
        lblTitulo.font = .boldSystemFont(ofSize: 34)
        lblNombreUsuario.font = .boldSystemFont(ofSize: 22)
        lblCorreoUsuario.font = .systemFont(ofSize: 15)
        lblCorreoUsuario.textColor = WayraTheme.textSecondary
        
        imgPerfil.layer.cornerRadius = 36
        imgPerfil.layer.borderWidth = 1.5
        imgPerfil.layer.borderColor = UIColor.white.cgColor
        imgPerfil.clipsToBounds = true
        imgPerfil.tintColor = WayraTheme.textSecondary
        
        // Corregir solapamiento añadiendo espacio programático
        lblTitulo.translatesAutoresizingMaskIntoConstraints = false
        imgPerfil.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            lblTitulo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            lblTitulo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            imgPerfil.topAnchor.constraint(equalTo: lblTitulo.bottomAnchor, constant: 30),
            imgPerfil.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            imgPerfil.widthAnchor.constraint(equalToConstant: 72),
            imgPerfil.heightAnchor.constraint(equalToConstant: 72)
        ])
        
        [btnInformacionPersonal, btnMisVehiculos, btnPagosCobros, btnCentroAyuda, btnPrivacidadSeguridad].forEach { boton in
            boton?.configuration?.baseForegroundColor = WayraTheme.textPrimary
            boton?.configuration?.imagePadding = 12
            boton?.contentHorizontalAlignment = .leading
        }
    }
    
    private func cargarDatosUsuario() {
        guard let user = Auth.auth().currentUser else {
            lblNombreUsuario.text = "Usuario WayraFix"
            lblCorreoUsuario.text = "Inicia sesión para ver tu perfil"
            return
        }
        
        // Cargar desde Firestore para consistencia de datos persistentes
        FirebaseManager.shared.verificarEstadoUsuario(uid: user.uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let datos):
                    self?.lblNombreUsuario.text = datos["nombre"] as? String ?? user.displayName ?? "Usuario WayraFix"
                    self?.lblCorreoUsuario.text = datos["email"] as? String ?? user.email ?? "Correo no disponible"
                case .failure(_):
                    self?.lblNombreUsuario.text = user.displayName ?? "Usuario WayraFix"
                    self?.lblCorreoUsuario.text = user.email ?? "Correo no disponible"
                }
            }
        }
    }
}
