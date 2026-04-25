//
//  LoginViewController.swift
//  AppSOS
//
//  Created by user286450 on 4/19/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class LoginViewController: UIViewController {

    // MARK: - Outlets de campos
    @IBOutlet weak var VistaEmail: UIView!
    @IBOutlet weak var VistaPassword: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    // MARK: - Labels de error (créalos en Storyboard ocultos debajo de cada campo)
    // Si no tienes outlets, se crean dinámicamente en configurarLabelsError()
    private var lblErrorEmail: UILabel!
    private var lblErrorPassword: UILabel!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarEstilos()
        configurarLabelsError()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }

    // MARK: - UI
    private func configurarEstilos() {
        view.configurarIdentidadWayra()
        VistaEmail.aplicarBordeContenedor()
        VistaPassword.aplicarBordeContenedor()
        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
    }

    /// Crea labels de error dinámicos debajo de cada campo si no existen en Storyboard
    private func configurarLabelsError() {
        lblErrorEmail    = crearLabelError()
        lblErrorPassword = crearLabelError()

        // Los insertamos en los contenedores de campo para que queden bien posicionados
        if let vistaE = VistaEmail {
            vistaE.addSubview(lblErrorEmail)
            NSLayoutConstraint.activate([
                lblErrorEmail.leadingAnchor.constraint(equalTo: vistaE.leadingAnchor, constant: 12),
                lblErrorEmail.trailingAnchor.constraint(equalTo: vistaE.trailingAnchor, constant: -12),
                lblErrorEmail.bottomAnchor.constraint(equalTo: vistaE.bottomAnchor, constant: -4)
            ])
        }
        if let vistaP = VistaPassword {
            vistaP.addSubview(lblErrorPassword)
            NSLayoutConstraint.activate([
                lblErrorPassword.leadingAnchor.constraint(equalTo: vistaP.leadingAnchor, constant: 12),
                lblErrorPassword.trailingAnchor.constraint(equalTo: vistaP.trailingAnchor, constant: -12),
                lblErrorPassword.bottomAnchor.constraint(equalTo: vistaP.bottomAnchor, constant: -4)
            ])
        }
    }

    private func crearLabelError() -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = WayraTheme.brand       // Rojo de marca
        lbl.numberOfLines = 1
        lbl.isHidden = true
        return lbl
    }

    // MARK: - Validación dinámica
    /// Valida los campos de login y muestra mensajes en rojo bajo cada campo.
    /// Devuelve true si todo es válido.
    @discardableResult
    private func validarCampos() -> Bool {
        var valido = true

        let email    = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        // Email
        if email.isEmpty {
            mostrarError(lblErrorEmail, mensaje: "El correo no puede estar vacío.")
            resaltarBorde(VistaEmail, error: true)
            valido = false
        } else if !esEmailValido(email) {
            mostrarError(lblErrorEmail, mensaje: "Ingresa un correo válido (ej: usuario@mail.com).")
            resaltarBorde(VistaEmail, error: true)
            valido = false
        } else {
            ocultarError(lblErrorEmail)
            resaltarBorde(VistaEmail, error: false)
        }

        // Contraseña
        if password.isEmpty {
            mostrarError(lblErrorPassword, mensaje: "La contraseña no puede estar vacía.")
            resaltarBorde(VistaPassword, error: true)
            valido = false
        } else if password.count < 6 {
            mostrarError(lblErrorPassword, mensaje: "Mínimo 6 caracteres.")
            resaltarBorde(VistaPassword, error: true)
            valido = false
        } else {
            ocultarError(lblErrorPassword)
            resaltarBorde(VistaPassword, error: false)
        }

        return valido
    }

    private func esEmailValido(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func mostrarError(_ label: UILabel?, mensaje: String) {
        label?.text = mensaje
        label?.isHidden = false
    }

    private func ocultarError(_ label: UILabel?) {
        label?.isHidden = true
    }

    private func resaltarBorde(_ vista: UIView?, error: Bool) {
        vista?.layer.borderColor = error
            ? WayraTheme.brand.cgColor
            : UIColor.lightGray.withAlphaComponent(0.5).cgColor
        vista?.layer.borderWidth = error ? 1.5 : 1.0
    }

    // MARK: - Login Email/Password
    @IBAction func loginTapped(_ sender: UIButton) {
        guard validarCampos() else { return }

        let email    = emailTextField.text!
        let password = passwordTextField.text!

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let e = error {
                DispatchQueue.main.async {
                    self?.mostrarAlerta(titulo: "Error de acceso", mensaje: e.localizedDescription)
                }
                return
            }
            guard let uid = authResult?.user.uid else { return }
            self?.verificarYSincronizarUsuario(uid: uid)
        }
    }

    // MARK: - Login con Google
    @IBAction func googleSignInTapped(_ sender: UIButton) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] resultado, error in
            if let e = error {
                DispatchQueue.main.async {
                    self?.mostrarAlerta(titulo: "Error con Google", mensaje: e.localizedDescription)
                }
                return
            }

            guard let usuario = resultado?.user,
                  let idToken = usuario.idToken?.tokenString else { return }

            let credencial = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: usuario.accessToken.tokenString
            )

            Auth.auth().signIn(with: credencial) { [weak self] authResult, error in
                if let e = error {
                    DispatchQueue.main.async {
                        self?.mostrarAlerta(titulo: "Error de autenticación", mensaje: e.localizedDescription)
                    }
                    return
                }
                guard let uid = authResult?.user.uid else { return }

                // Flujo híbrido: verificar si ya existe en Firestore
                self?.manejarFlujoGoogle(uid: uid, usuarioGoogle: usuario)
            }
        }
    }

    // MARK: - Flujo Híbrido Google
    /// Si el usuario no existe en Firestore → lo crea (primer ingreso).
    /// Si ya existe y is_active == true → va al TabBar.
    private func manejarFlujoGoogle(uid: String, usuarioGoogle: GIDGoogleUser) {
        let db = Firestore.firestore()
        db.collection("usuarios").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.mostrarAlerta(titulo: "Error de red", mensaje: error.localizedDescription)
                }
                return
            }

            if let datos = snapshot?.data(), !datos.isEmpty {
                // Usuario existente — verificar is_active
                let activo = datos["is_active"] as? Bool ?? false
                guard activo else {
                    DispatchQueue.main.async {
                        try? Auth.auth().signOut()
                        self?.mostrarAlerta(
                            titulo: "Usuario no registrado",
                            mensaje: "Tu cuenta está inactiva o fue eliminada. Contacta al soporte."
                        )
                    }
                    return
                }
                // Sincronizar localmente y navegar
                let nombre  = datos["nombre"]  as? String ?? ""
                let email   = datos["email"]   as? String ?? ""
                let celular = datos["celular"] as? String ?? ""
                let pais    = datos["pais"]    as? String ?? ""
                let rol     = datos["rol"]     as? String ?? "cliente"
                ControladorPersistencia.compartido.sincronizarUsuario(
                    id: uid, nombre: nombre, email: email,
                    celular: celular, pais: pais, rol: rol
                ) { [weak self] _, _ in
                    DispatchQueue.main.async { self?.irAlTabBar() }
                }

            } else {
                // Primer ingreso con Google → crear documento en Firestore
                let nombre = usuarioGoogle.profile?.name ?? "Usuario Google"
                let email  = usuarioGoogle.profile?.email ?? ""
                ControladorPersistencia.compartido.sincronizarUsuario(
                    id: uid, nombre: nombre, email: email,
                    celular: "", pais: "", rol: "cliente"
                ) { [weak self] exito, errorSync in
                    DispatchQueue.main.async {
                        if let e = errorSync {
                            self?.mostrarAlerta(titulo: "Error al crear cuenta", mensaje: e.localizedDescription)
                            return
                        }
                        // Navegar al TabBar directamente (Google ya valida el email)
                        self?.irAlTabBar()
                    }
                }
            }
        }
    }

    // MARK: - Verificación is_active + Sincronización (Email/Password)
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

            let activo = datos["is_active"] as? Bool ?? false
            guard activo else {
                DispatchQueue.main.async {
                    try? Auth.auth().signOut()
                    self?.mostrarAlerta(titulo: "Usuario no registrado",
                                        mensaje: "Tu cuenta está inactiva o fue eliminada. Contacta al soporte.")
                }
                return
            }

            let nombre  = datos["nombre"]  as? String ?? ""
            let email   = datos["email"]   as? String ?? ""
            let celular = datos["celular"] as? String ?? ""
            let pais    = datos["pais"]    as? String ?? ""
            let rol     = datos["rol"]     as? String ?? "cliente"

            ControladorPersistencia.compartido.sincronizarUsuario(
                id: uid, nombre: nombre, email: email,
                celular: celular, pais: pais, rol: rol
            ) { [weak self] _, errorSync in
                DispatchQueue.main.async {
                    if let e = errorSync {
                        print("Advertencia: Error al sincronizar localmente: \(e.localizedDescription)")
                    }
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
        if let escena = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // keyWindow es el método preferido en iOS 15+; windows.first como fallback
            let ventana = escena.keyWindow ?? escena.windows.first
            guard let ventana = ventana else { return }
            ventana.rootViewController = tabBar
            ventana.makeKeyAndVisible()
            UIView.transition(with: ventana, duration: 0.35,
                              options: .transitionCrossDissolve, animations: nil)
        }
    }

    // MARK: - Alertas
    private func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }
}
