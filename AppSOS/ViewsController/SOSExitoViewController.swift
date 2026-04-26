import UIKit

class SOSExitoViewController: UIViewController {
    
    @IBOutlet weak var tarjetaExito: UIView!
    @IBOutlet weak var btnVerSeguimiento: UIButton!
    @IBOutlet weak var btnCerrar: UIButton!
    
    var onSeguimientoTapped: (() -> Void)?
    var onCerrarTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        tarjetaExito.applyCardStyle(radius: 30, shadow: true)
        btnVerSeguimiento.applyPrimaryStyle(title: "Ver Seguimiento")
        
        btnCerrar.setTitle("Cerrar", for: .normal)
        btnCerrar.setTitleColor(WayraTheme.textPrimary, for: .normal)
        btnCerrar.titleLabel?.font = .boldSystemFont(ofSize: 16)
    }
    
    @IBAction func btnSeguimientoTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onSeguimientoTapped?()
        }
    }
    
    @IBAction func btnCerrarTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onCerrarTapped?()
        }
    }
}
