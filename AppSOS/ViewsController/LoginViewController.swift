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
        configurarEstilos()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }

    private func configurarEstilos() {
        view.aplicarFondoRosadoRadial()

        VistaEmail.aplicarBordeContenedor()
        VistaPassword.aplicarBordeContenedor()

        // Aplicar bordes y radios estándar a todos los contenedores
        aplicarEstilosWayra(a: view)
        // Aplicar estilos de botón por contexto (Registrarme, Iniciar Sesión, etc.)
        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("Por favor, llena todos los campos")
            return
        }
        
        //Esto es el método de firebase para inciar session
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let e = error {
                print("Error en el login: \(e.localizedDescription)")  
                return       
            } 

            print("Login Exitoso")
            // Navegar al TabBarController (Tab 1: CarLinkSOS / Tab 2: Mi Garage)
            // Asegúrate de que el segue "toTabBarSegue" apunte al UITabBarController en el Storyboard
            self?.performSegue(withIdentifier: "toTabBarSegue", sender: nil)
        }    
    }
}
