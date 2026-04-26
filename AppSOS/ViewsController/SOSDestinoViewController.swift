import UIKit

class SOSDestinoViewController: UIViewController {
    
    @IBOutlet weak var tarjetaDestino: UIView!
    @IBOutlet weak var btnSolicitarAyuda: UIButton!
    @IBOutlet weak var btnCancelar: UIButton!
    
    var onSolicitarTapped: (() -> Void)?
    var onCancelarTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        tarjetaDestino.applyCardStyle(radius: 30, shadow: true)
        btnSolicitarAyuda.applyPrimaryStyle(title: "Solicitar Ayuda Ahora")
        
        btnCancelar.setTitle("Cancelar", for: .normal)
        btnCancelar.setTitleColor(WayraTheme.textPrimary, for: .normal)
        btnCancelar.titleLabel?.font = .boldSystemFont(ofSize: 16)
    }
    
    @IBAction func btnSolicitarTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onSolicitarTapped?()
        }
    }
    
    @IBAction func btnCancelarTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onCancelarTapped?()
        }
    }
}
