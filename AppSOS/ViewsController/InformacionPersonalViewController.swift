//
//  InformacionPersonalViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 24/04/26.
//


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
        
        btnGuardar.applyPrimaryStyle(title: "Guardar cambios")
        btnGuardar.configuration?.baseBackgroundColor = WayraTheme.brand
        btnGuardar.layer.cornerRadius = 25
        
        imgPerfil.layer.cornerRadius = 60
        imgPerfil.clipsToBounds = true
        imgPerfil.layer.borderWidth = 4
        imgPerfil.layer.borderColor = UIColor.white.cgColor
        
        lblTitulo.font = .systemFont(ofSize: 34, weight: .bold)
        lblTitulo.text = "Información personal"
        
        [txtNombres, txtApellido, txtCorreo, txtCelular].forEach { field in
            field?.backgroundColor = .white
            field?.layer.cornerRadius = 12
            field?.layer.borderWidth = 1
            field?.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
            field?.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 10))
            field?.leftViewMode = .always
        }
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
