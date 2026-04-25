import UIKit
import FirebaseAuth

class InformacionPersonalViewController: UIViewController {

    @IBOutlet weak var lblTitulo: UILabel!
    @IBOutlet weak var imgPerfil: UIImageView!
    @IBOutlet weak var txtNombres: UITextField!
    @IBOutlet weak var txtApellido: UITextField!
    @IBOutlet weak var txtCorreo: UITextField!
    @IBOutlet weak var txtCelular: UITextField!
    @IBOutlet weak var btnGuardar: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarDatosUsuario()
    }
    
    private func setupUI() {
        self.view.aplicarFondoRosadoRadial()
        btnGuardar.aplicarEstiloPrincipalRoja()
        
        imgPerfil.layer.cornerRadius = 50
        imgPerfil.clipsToBounds = true
        imgPerfil.layer.borderWidth = 2
        imgPerfil.layer.borderColor = UIColor.white.cgColor
        
        lblTitulo.text = "Información personal"
    }
    
    private func cargarDatosUsuario() {
        if let user = Auth.auth().currentUser {
            let fullParts = user.displayName?.split(separator: " ")
            if let parts = fullParts, parts.count >= 2 {
                txtNombres.text = String(parts[0])
                txtApellido.text = parts.dropFirst().joined(separator: " ")
            } else {
                txtNombres.text = user.displayName
                txtApellido.text = ""
            }
            
            txtCorreo.text = user.email
            txtCelular.text = user.phoneNumber ?? ""
        }
    }
    
    @IBAction func btnGuardarTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Guardar", message: "¿Deseas guardar los cambios?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }
}
