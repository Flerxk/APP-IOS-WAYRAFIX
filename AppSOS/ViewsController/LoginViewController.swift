//
//  LoginViewController.swift
//  AppSOS
//
//  Created by user286450 on 4/19/26.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var VistaEmail: UIView!
    @IBOutlet weak var VistaPassword: UIView!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setupStyles() // Desactivado para priorizar Storyboard
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // if let gradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) {
        //     gradientLayer.frame = view.bounds
        // }
    }

    private func setupStyles() {
        // Fondo radial (Blanco a rosado muy sutil)
        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .radial
        gradientLayer.colors = [UIColor.white.cgColor, UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.3)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Bordes de contenedor
        VistaEmail.layer.cornerRadius = 16
        VistaEmail.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        VistaEmail.layer.borderWidth = 1
        
        VistaPassword.layer.cornerRadius = 16
        VistaPassword.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        VistaPassword.layer.borderWidth = 1
        
        applyStyleToButtons(en: view)
    }
    
    private func applyStyleToButtons(en root: UIView) {
        if let button = root as? UIButton {
            let title = button.titleLabel?.text ?? button.configuration?.title ?? ""
            if title.contains("Iniciar Sesión") {
                button.layer.cornerRadius = 25
                button.backgroundColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
                button.tintColor = .white
                button.layer.shadowColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0).cgColor
                button.layer.shadowOffset = CGSize(width: 0, height: 6)
                button.layer.shadowOpacity = 0.4
                button.layer.shadowRadius = 10
                button.layer.masksToBounds = false
            }
        }
        for sub in root.subviews {
            applyStyleToButtons(en: sub)
        }
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("Por favor, llena todos los campos")
            return
        }
        //Esto es el método de firebase para inciar session
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let e = error{
                print("Error en el login: \(e.localizedDescription)")  
                return       
            } 

            print("Login EXitoso")
            //En estre caso si el login es exitoso vamos al home
            self?.performSegue(withIdentifier:"toHomeSegue", sender:nil)
        }    
    }
}
