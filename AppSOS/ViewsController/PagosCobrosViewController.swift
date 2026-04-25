import UIKit

class PagosCobrosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var lblTitulo: UILabel!
    @IBOutlet weak var tblMetodosPago: UITableView!
    @IBOutlet weak var btnAnadirTarjeta: UIButton!
    
    let metodos = ["Visa **** 4567", "MasterCard **** 8901", "Apple Pay"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
    }
    
    private func setupUI() {
        self.view.aplicarFondoRosadoRadial()
        btnAnadirTarjeta.aplicarEstiloPrincipalRoja()
        lblTitulo.text = "Pagos y cobros"
    }
    
    private func setupTable() {
        tblMetodosPago.dataSource = self
        tblMetodosPago.delegate = self
        tblMetodosPago.backgroundColor = .clear
        tblMetodosPago.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metodos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = metodos[indexPath.row]
        cell.backgroundColor = .clear
        cell.imageView?.image = UIImage(systemName: "creditcard.fill")
        cell.imageView?.tintColor = .systemRed
        return cell
    }
}
