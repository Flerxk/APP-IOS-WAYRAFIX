import UIKit

class PrivacidadSeguridadViewController: UIViewController {

    @IBOutlet weak var lblTitulo: UILabel!
    @IBOutlet weak var stackOpciones: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        self.view.aplicarFondoRosadoRadial()
        lblTitulo.text = "Privacidad y seguridad"
    }
    
    @IBAction func switchPrivacidadCambiado(_ sender: UISwitch) {
        print("Preferencia de privacidad cambiada")
    }
}
