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
        VistaEmail.layer.borderColor = UIColor.lightGray.cgColor
        VistaPassword.layer.borderColor = UIColor.lightGray.cgColor

        super.viewDidLoad()
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        guard var email = emailTextField.text, !email.isEmpty,
              var password = passwordTextField.text, !password.isEmpty else {
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
