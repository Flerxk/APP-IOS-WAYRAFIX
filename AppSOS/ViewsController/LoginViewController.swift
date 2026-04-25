//
//  LoginViewController.swift
//  AppSOS
//
//  Created by user286450 on 4/19/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

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

    // MARK: - UI
    private func configurarEstilos() {
        // Motor global: fondo radial + todos los estilos de identidad WayraFix
        view.configurarIdentidadWayra()

        // Bordes de los contenedores de campo (redundante pero explícito)
        VistaEmail.aplicarBordeContenedor()
        VistaPassword.aplicarBordeContenedor()

        // Estilos de botones por texto
        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
    }

    // MARK: - Login
    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            mostrarAlerta(titulo: "Campos vacíos", mensaje: "Por favor, ingresa tu correo y contraseña.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let e = error {
                DispatchQueue.main.async {
                    self?.mostrarAlerta(titulo: "Error de acceso", mensaje: e.localizedDescription)
                }
                return
            }

            guard let uid = authResult?.user.uid else { return }

            // Verificar is_active en Firestore y sincronizar datos
            self?.verificarYSincronizarUsuario(uid: uid)
        }
    }

    // MARK: - Verificación is_active + Sincronización
    private func verificarYSincronizarUsuario(uid: String) {
        let db = Firestore.firestore()
        db.collection("usuarios").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.mostrarAlerta(titulo: "Error de red", mensaje: error.localizedDescription)
                }
                return
            }

            guard let datos = snapshot?.data() else {
                DispatchQueue.main.async {
                    self?.mostrarAlerta(titulo: "Usuario no encontrado",
                                        mensaje: "No se encontraron datos para este usuario.")
                }
                return
            }

            // Verificar campo is_active
            let activo = datos["is_active"] as? Bool ?? false
            guard activo else {
                DispatchQueue.main.async {
                    // Cerrar sesión de Firebase para que no quede autenticado
                    try? Auth.auth().signOut()
                    self?.mostrarAlerta(titulo: "Usuario no registrado",
                                        mensaje: "Tu cuenta está inactiva o fue eliminada. Contacta al soporte.")
                }
                return
            }

            // Sincronizar datos locales en Core Data
            let nombre   = datos["nombre"]   as? String ?? ""
            let email    = datos["email"]    as? String ?? ""
            let celular  = datos["celular"]  as? String ?? ""
            let pais     = datos["pais"]     as? String ?? ""
            let rol      = datos["rol"]      as? String ?? "cliente"

            ControladorPersistencia.compartido.sincronizarUsuario(
                id: uid,
                nombre: nombre,
                email: email,
                celular: celular,
                pais: pais,
                rol: rol
            ) { [weak self] exito, errorSync in
                DispatchQueue.main.async {
                    if let e = errorSync {
                        // Error de sincronización local — no critico, igual navegamos
                        print("Advertencia: Error al sincronizar localmente: \(e.localizedDescription)")
                    }
                    // Navegar al TabBarController
                    self?.irAlTabBar()
                }
            }
        }
    }

    // MARK: - Navegación
    private func irAlTabBar() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBar = storyboard.instantiateViewController(withIdentifier: "MainTabBar") as? UITabBarController else {
            print("Error: no se encontró el TabBarController con Storyboard ID 'MainTabBar'")
            return
        }
        if let escena = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let ventana = escena.windows.first {
            ventana.rootViewController = tabBar
            ventana.makeKeyAndVisible()
            UIView.transition(with: ventana,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: nil)
        }
    }

    // MARK: - Alertas
    private func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }
}
