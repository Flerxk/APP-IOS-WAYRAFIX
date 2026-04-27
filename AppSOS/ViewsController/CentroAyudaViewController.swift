//
//  CentroAyudaViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 24/04/26.
//


import UIKit

class CentroAyudaViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var lblTitulo: UILabel!
    @IBOutlet weak var tblPreguntas: UITableView!
    
    let faqs = [
        "¿Cómo solicito una grúa?",
        "¿Qué incluye mi membresía?",
        "¿Cómo cambio mi contraseña?",
        "Tengo problemas con el pago",
        "¿Cómo cancelar un servicio?"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
    }
    
    private func setupUI() {
        self.view.aplicarFondoRosadoRadial()
        lblTitulo.text = "Centro de ayuda"
    }
    
    private func setupTable() {
        tblPreguntas.dataSource = self
        tblPreguntas.delegate = self
        tblPreguntas.backgroundColor = .clear
        tblPreguntas.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faqs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = faqs[indexPath.row]
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
