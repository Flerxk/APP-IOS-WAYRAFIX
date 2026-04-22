//
//  SignUpViewController.swift
//  AppSOS
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {

    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var contrasenaTextField: UITextField!
    @IBOutlet weak var confirmarContraseniaTextFiel: UITextField!
    @IBOutlet weak var terminosCheckbox: UIButton!
    
    @IBOutlet private var camposConBorde: [UIView]?

    @IBAction func volverAtras(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func irIniciarSesion(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let cajas = camposConBorde, !cajas.isEmpty {
            cajas.forEach { $0.layer.borderColor = UIColor.lightGray.cgColor }
        } else {
            aplicarBordeGrisAContenedoresDeCampos(en: view)
        }
    }
    
    let datadabase = Firestore.firestore()
    
    @IBAction func registrarTappet(_ sender: UIButton){
        guard let email = emailTextField.text, !email.isEmpty,
              let password = contrasenaTextField.text, !password.isEmpty,
              let nombre = nombreTextField.text,
              let
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func aplicarBordeGrisAContenedoresDeCampos(en root: UIView) {
        for sub in root.subviews {
            if sub.layer.cornerRadius >= 12, sub.layer.borderWidth >= 1,
               sub.subviews.contains(where: { $0 is UIStackView }) {
                sub.layer.borderColor = UIColor.lightGray.cgColor
            }
            aplicarBordeGrisAContenedoresDeCampos(en: sub)
        }
    }
}
