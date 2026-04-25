//
//  PerfilViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 16/04/26.
//

import UIKit
import FirebaseAuth

class PerfilViewController: UIViewController {

    @IBOutlet weak var txtNombres: UITextField!
    @IBOutlet weak var txtApellidos: UITextField!
    @IBOutlet weak var txtCelular: UITextField!
    @IBOutlet weak var btnGuardar: UIButton!
    
    private weak var summaryStack: UIStackView?
    private weak var stackOpcionesCuenta: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "" 
        view.backgroundColor = .clear
        view.aplicarFondoRosadoRadial()
        prepararVista()
        setupNavigationStyle()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ocultarTeclado))
        view.addGestureRecognizer(tap)
        
        actualizarVistaPerfil()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }
    
    func setupNavigationStyle() {
        let btnCerrar = UIButton(type: .system)
        btnCerrar.setImage(UIImage(systemName: "xmark"), for: .normal)
        btnCerrar.tintColor = WayraTheme.textPrimary
        btnCerrar.backgroundColor = .clear
        btnCerrar.addAction(UIAction { [weak self] _ in
            if let nav = self?.navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                self?.dismiss(animated: true)
            }
        }, for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnCerrar)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @objc func ocultarTeclado() {
        view.endEditing(true)
    }

    @IBAction func btnGuardarTapped(_ sender: UIButton) {
        mostrarAlerta(titulo: "Pendiente", mensaje: "La edición del perfil se conectará con Firebase más adelante.")
    }
    
    func prepararVista() {
        [txtNombres, txtApellidos, txtCelular, btnGuardar].forEach { $0?.isHidden = true }
    }
    
    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }
    
    func actualizarVistaPerfil() {
        let user = Auth.auth().currentUser
        construirResumen(nombre: user?.displayName ?? "Carlos Mendoza", correo: user?.email ?? "carlos.mendoza@gmail.com")
        construirOpcionesPerfil()
    }
    
    func construirResumen(nombre: String, correo: String) {
        summaryStack?.removeFromSuperview()
        
        let btnCerrar = UIButton(type: .system)
        btnCerrar.translatesAutoresizingMaskIntoConstraints = false
        btnCerrar.setImage(UIImage(systemName: "xmark"), for: .normal)
        btnCerrar.tintColor = .black
        btnCerrar.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        view.addSubview(btnCerrar)

        let lblTituloPerfil = UILabel()
        lblTituloPerfil.translatesAutoresizingMaskIntoConstraints = false
        lblTituloPerfil.text = "Perfil"
        lblTituloPerfil.font = .boldSystemFont(ofSize: 34)
        view.addSubview(lblTituloPerfil)
        
        let stackVerticalInfo = UIStackView()
        stackVerticalInfo.translatesAutoresizingMaskIntoConstraints = false
        stackVerticalInfo.axis = .vertical
        stackVerticalInfo.spacing = 4
        
        let lblNombre = UILabel()
        lblNombre.text = nombre
        lblNombre.font = .boldSystemFont(ofSize: 22)
        
        let lblCorreo = UILabel()
        lblCorreo.text = correo
        lblCorreo.font = .systemFont(ofSize: 16)
        lblCorreo.textColor = .systemGray
        
        stackVerticalInfo.addArrangedSubview(lblNombre)
        stackVerticalInfo.addArrangedSubview(lblCorreo)
        
        let imgPerfil = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        imgPerfil.translatesAutoresizingMaskIntoConstraints = false
        imgPerfil.tintColor = .lightGray
        imgPerfil.contentMode = .scaleAspectFill
        imgPerfil.layer.cornerRadius = 36
        imgPerfil.clipsToBounds = true
        
        view.addSubview(stackVerticalInfo)
        view.addSubview(imgPerfil)
        
        NSLayoutConstraint.activate([
            btnCerrar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            btnCerrar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            btnCerrar.widthAnchor.constraint(equalToConstant: 24),
            btnCerrar.heightAnchor.constraint(equalToConstant: 24),

            lblTituloPerfil.topAnchor.constraint(equalTo: btnCerrar.bottomAnchor, constant: 24),
            lblTituloPerfil.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            stackVerticalInfo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackVerticalInfo.topAnchor.constraint(equalTo: lblTituloPerfil.bottomAnchor, constant: 28),
            stackVerticalInfo.trailingAnchor.constraint(equalTo: imgPerfil.leadingAnchor, constant: -16),
            
            imgPerfil.widthAnchor.constraint(equalToConstant: 72),
            imgPerfil.heightAnchor.constraint(equalToConstant: 72),
            view.trailingAnchor.constraint(equalTo: imgPerfil.trailingAnchor, constant: 24),
            imgPerfil.centerYAnchor.constraint(equalTo: stackVerticalInfo.centerYAnchor)
        ])
        
        summaryStack = stackVerticalInfo
    }
    
    func construirOpcionesPerfil() {
        stackOpcionesCuenta?.removeFromSuperview()
        
        let stackPrincipal = UIStackView()
        stackPrincipal.translatesAutoresizingMaskIntoConstraints = false
        stackPrincipal.axis = .vertical
        stackPrincipal.spacing = 32
        
        let seccionCuenta = crearSeccion(titulo: "Ajustes de cuenta", filas: [
            ("person.circle", "Información personal", #selector(irAPersonalInfo)),
            ("car", "Mis vehículos", #selector(irAGarage)),
            ("creditcard", "Pagos y cobros", #selector(irAPagos))
        ])
        
        let seccionAsistencia = crearSeccion(titulo: "Asistencia", filas: [
            ("questionmark.circle", "Centro de ayuda", #selector(irAAyuda)),
            ("shield", "Privacidad y seguridad", #selector(irAPrivacidad))
        ])
        
        stackPrincipal.addArrangedSubview(seccionCuenta)
        stackPrincipal.addArrangedSubview(seccionAsistencia)
        
        view.addSubview(stackPrincipal)
        
        NSLayoutConstraint.activate([
            stackPrincipal.topAnchor.constraint(equalTo: summaryStack?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 50),
            stackPrincipal.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: stackPrincipal.trailingAnchor, constant: 24)
        ])
        
        stackOpcionesCuenta = stackPrincipal
    }
    
    func crearSeccion(titulo: String, filas: [(String, String, Selector)]) -> UIStackView {
        let stackSeccion = UIStackView()
        stackSeccion.axis = .vertical
        stackSeccion.spacing = 16
        
        let lblTitulo = UILabel()
        lblTitulo.text = titulo
        lblTitulo.font = .boldSystemFont(ofSize: 22)
        stackSeccion.addArrangedSubview(lblTitulo)
        
        let stackFilas = UIStackView()
        stackFilas.axis = .vertical
        stackFilas.spacing = 0
        
        for (indice, fila) in filas.enumerated() {
            let vistaFila = UIView()
            vistaFila.translatesAutoresizingMaskIntoConstraints = false
            
            let icono = UIImageView(image: UIImage(systemName: fila.0))
            icono.translatesAutoresizingMaskIntoConstraints = false
            icono.tintColor = .black
            icono.contentMode = .scaleAspectFit
            
            let etiquetaTitulo = UILabel()
            etiquetaTitulo.translatesAutoresizingMaskIntoConstraints = false
            etiquetaTitulo.text = fila.1
            etiquetaTitulo.font = .systemFont(ofSize: 18, weight: .regular)
            
            let iconoChevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            iconoChevron.translatesAutoresizingMaskIntoConstraints = false
            iconoChevron.tintColor = .systemGray3
            
            vistaFila.addSubview(icono)
            vistaFila.addSubview(etiquetaTitulo)
            vistaFila.addSubview(iconoChevron)
            
            NSLayoutConstraint.activate([
                vistaFila.heightAnchor.constraint(equalToConstant: 54),
                icono.leadingAnchor.constraint(equalTo: vistaFila.leadingAnchor),
                icono.centerYAnchor.constraint(equalTo: vistaFila.centerYAnchor),
                icono.widthAnchor.constraint(equalToConstant: 28),
                icono.heightAnchor.constraint(equalToConstant: 28),
                
                etiquetaTitulo.leadingAnchor.constraint(equalTo: icono.trailingAnchor, constant: 16),
                etiquetaTitulo.centerYAnchor.constraint(equalTo: vistaFila.centerYAnchor),
                
                iconoChevron.trailingAnchor.constraint(equalTo: vistaFila.trailingAnchor),
                iconoChevron.centerYAnchor.constraint(equalTo: vistaFila.centerYAnchor),
                iconoChevron.widthAnchor.constraint(equalToConstant: 14)
            ])
            
            let btnInvisible = UIButton(type: .custom)
            btnInvisible.translatesAutoresizingMaskIntoConstraints = false
            btnInvisible.addTarget(self, action: fila.2, for: .touchUpInside)
            vistaFila.addSubview(btnInvisible)
            NSLayoutConstraint.activate([
                btnInvisible.topAnchor.constraint(equalTo: vistaFila.topAnchor),
                btnInvisible.leadingAnchor.constraint(equalTo: vistaFila.leadingAnchor),
                btnInvisible.trailingAnchor.constraint(equalTo: vistaFila.trailingAnchor),
                btnInvisible.bottomAnchor.constraint(equalTo: vistaFila.bottomAnchor)
            ])
            
            stackFilas.addArrangedSubview(vistaFila)
            
            if indice < filas.count - 1 {
                let divisor = UIView()
                divisor.backgroundColor = UIColor(white: 0.92, alpha: 1)
                divisor.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([divisor.heightAnchor.constraint(equalToConstant: 1)])
                stackFilas.addArrangedSubview(divisor)
            }
        }
        
        stackSeccion.addArrangedSubview(stackFilas)
        return stackSeccion
    }
    
    @objc func irAPersonalInfo() {
        if let infoVC = storyboard?.instantiateViewController(withIdentifier: "vc-personal-info") {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.pushViewController(infoVC, animated: true)
        }
    }
    
    @objc func irAGarage() {
        if let garageVC = storyboard?.instantiateViewController(withIdentifier: "vc-garage") {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.pushViewController(garageVC, animated: true)
        }
    }
    
    @objc func irAPagos() {
        if let pagosVC = storyboard?.instantiateViewController(withIdentifier: "vc-pagos") {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.pushViewController(pagosVC, animated: true)
        }
    }
    
    @objc func irAAyuda() {
        if let ayudaVC = storyboard?.instantiateViewController(withIdentifier: "vc-ayuda") {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.pushViewController(ayudaVC, animated: true)
        }
    }
    
    @objc func irAPrivacidad() {
        if let privVC = storyboard?.instantiateViewController(withIdentifier: "vc-privacidad") {
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.pushViewController(privVC, animated: true)
        }
    }
}
