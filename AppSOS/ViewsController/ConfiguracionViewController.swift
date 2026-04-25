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
        
        lblNombreUsuario.text = user.displayName?.isEmpty == false ? user.displayName : "Usuario WayraFix"
        lblCorreoUsuario.text = user.email ?? "Correo no disponible"
    }
}
