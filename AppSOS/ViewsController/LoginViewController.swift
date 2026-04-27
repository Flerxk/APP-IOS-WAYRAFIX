//
//  LoginViewController.swift
//  AppSOS
//
//  Created by user286450 on 4/19/26.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore

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
    
    private var haIntentadoEnviar = false
    private var placeholdersOriginales: [UITextField: String] = [:]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarEstilos()
        configurarLabelsError()
        
        // Validación en tiempo real
        [emailTextField, passwordTextField].forEach {
            $0?.addTarget(self, action: #selector(campoEditado(_:)), for: .editingChanged)
        }
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

        view.addSubview(lblErrorEmail)
        view.addSubview(lblErrorPassword)

        NSLayoutConstraint.activate([
            lblErrorEmail.topAnchor.constraint(equalTo: VistaEmail.bottomAnchor, constant: 2),
            lblErrorEmail.leadingAnchor.constraint(equalTo: VistaEmail.leadingAnchor, constant: 8),
            lblErrorEmail.trailingAnchor.constraint(equalTo: VistaEmail.trailingAnchor, constant: -8),

            lblErrorPassword.topAnchor.constraint(equalTo: VistaPassword.bottomAnchor, constant: 2),
            lblErrorPassword.leadingAnchor.constraint(equalTo: VistaPassword.leadingAnchor, constant: 8),
            lblErrorPassword.trailingAnchor.constraint(equalTo: VistaPassword.trailingAnchor, constant: -8)
        ])
    }

    private func crearLabelError() -> UILabel {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = WayraTheme.brand
        lbl.numberOfLines = 0
        lbl.isHidden = true
        return lbl
    }

    @objc private func campoEditado(_ sender: UITextField) {
        if haIntentadoEnviar {
            _ = validarCampos()
        } else {
            if sender == emailTextField { ocultarError(lblErrorEmail, en: emailTextField) }
            if sender == passwordTextField { ocultarError(lblErrorPassword, en: passwordTextField) }
        }
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
            mostrarError(lblErrorEmail, en: emailTextField, mensaje: "El correo no puede estar vacío.")
            resaltarBorde(VistaEmail, error: true)
            valido = false
        } else if !esEmailValido(email) {
            mostrarError(lblErrorEmail, en: emailTextField, mensaje: "Ingresa un correo válido (ej: usuario@mail.com).")
            resaltarBorde(VistaEmail, error: true)
            valido = false
        } else {
            ocultarError(lblErrorEmail, en: emailTextField)
            resaltarBorde(VistaEmail, error: false)
        }

        // Contraseña
        if password.isEmpty {
            mostrarError(lblErrorPassword, en: passwordTextField, mensaje: "La contraseña no puede estar vacía.")
            resaltarBorde(VistaPassword, error: true)
            valido = false
        } else if password.count < 6 {
            mostrarError(lblErrorPassword, en: passwordTextField, mensaje: "Mínimo 6 caracteres.")
            resaltarBorde(VistaPassword, error: true)
            valido = false
        } else {
            ocultarError(lblErrorPassword, en: passwordTextField)
            resaltarBorde(VistaPassword, error: false)
        }

        return valido
    }

    private func esEmailValido(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func mostrarError(_ label: UILabel?, en campo: UITextField, mensaje: String) {
        label?.text = mensaje
        label?.isHidden = false
        
        // Guardar y ocultar placeholder
        if let placeholder = campo.placeholder, !placeholder.isEmpty {
            placeholdersOriginales[campo] = placeholder
        }
        campo.placeholder = nil
    }

    private func ocultarError(_ label: UILabel?, en campo: UITextField) {
        label?.isHidden = true
        
        // Restaurar placeholder si existía
        if let original = placeholdersOriginales[campo] {
            campo.placeholder = original
        }
    }

    private func resaltarBorde(_ vista: UIView?, error: Bool) {
        vista?.layer.borderColor = error
            ? WayraTheme.brand.cgColor
            : UIColor.lightGray.withAlphaComponent(0.5).cgColor
        vista?.layer.borderWidth = error ? 1.5 : 1.0
    }

    // MARK: - Login Email/Password
    @IBAction func loginTapped(_ sender: UIButton) {
        haIntentadoEnviar = true
        guard validarCampos() else { return }

        let email    = emailTextField.text!
        let password = passwordTextField.text!

        // Usamos nuestro Manager encapsulado (Tema 10)
        FirebaseManager.shared.iniciarSesion(email: email, contrasena: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let uid):
                    self?.verificarYSincronizarUsuario(uid: uid)
                case .failure(let error):
                    self?.mostrarAlerta(titulo: "Error de acceso", mensaje: error.localizedDescription)
                }
            }
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
        FirebaseManager.shared.verificarEstadoUsuario(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self?.mostrarAlerta(titulo: "Error de red", mensaje: error.localizedDescription)
                    
                case .success(let datos):
                    let activo = datos["is_active"] as? Bool ?? false
                    guard activo else {
                        try? FirebaseManager.shared.cerrarSesion()
                        self?.mostrarAlerta(titulo: "Usuario no registrado",
                                            mensaje: "Tu cuenta está inactiva o fue eliminada. Contacta al soporte.")
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
                    ) { _, _ in
                        DispatchQueue.main.async { self?.irAlTabBar() }
                    }
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
        if let escena = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            let ventana = escena.windows.first(where: { $0.isKeyWindow }) ?? escena.windows.first
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
