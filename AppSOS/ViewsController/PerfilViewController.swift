//
//  PerfilViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 16/04/26.
//

import UIKit

class PerfilViewController: UIViewController {

    @IBOutlet weak var txtNombres: UITextField!
    @IBOutlet weak var txtApellidos: UITextField!
    @IBOutlet weak var txtCelular: UITextField!
    @IBOutlet weak var btnGuardar: UIButton!
    
    private let proveedorSesion: ProveedorSesionPerfilProtocol = ProveedorSesionPerfilLocal()
    private weak var summaryStack: UIStackView?
    private weak var stackOpcionesCuenta: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Perfil"
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
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnCerrar)
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
        let perfil = proveedorSesion.obtenerPerfilActual()
        construirResumen(perfil: perfil)
        construirOpcionesPerfil()
    }
    
    func construirResumen(perfil: PerfilSesion) {
        summaryStack?.removeFromSuperview()
        
        let stackVertical = UIStackView()
        stackVertical.translatesAutoresizingMaskIntoConstraints = false
        stackVertical.axis = .vertical
        stackVertical.spacing = 6
        
        let lblNombre = UILabel()
        lblNombre.text = perfil.nombreCompleto
        lblNombre.font = .boldSystemFont(ofSize: 34)
        
        let lblCorreo = UILabel()
        lblCorreo.text = perfil.estaLogueado ? perfil.correo : ""
        lblCorreo.font = .systemFont(ofSize: 16, weight: .medium)
        lblCorreo.textColor = WayraTheme.textSecondary
        lblCorreo.isHidden = !perfil.estaLogueado
        
        let imgPerfil = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        imgPerfil.translatesAutoresizingMaskIntoConstraints = false
        imgPerfil.tintColor = .lightGray
        imgPerfil.contentMode = .scaleAspectFill
        
        stackVertical.addArrangedSubview(lblNombre)
        stackVertical.addArrangedSubview(lblCorreo)
        view.addSubview(stackVertical)
        view.addSubview(imgPerfil)
        
        NSLayoutConstraint.activate([
            stackVertical.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackVertical.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            imgPerfil.widthAnchor.constraint(equalToConstant: 72),
            imgPerfil.heightAnchor.constraint(equalToConstant: 72),
            view.trailingAnchor.constraint(equalTo: imgPerfil.trailingAnchor, constant: 24),
            imgPerfil.centerYAnchor.constraint(equalTo: stackVertical.centerYAnchor)
        ])
        
        summaryStack = stackVertical
    }
    
    func construirOpcionesPerfil() {
        stackOpcionesCuenta?.removeFromSuperview()
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        
        let tituloCuenta = crearTituloSeccion("Ajustes de cuenta")
        let tituloAsistencia = crearTituloSeccion("Asistencia")
        
        let filasCuenta = crearFilas([
            ("person.circle", "Información personal"),
            ("car", "Mis vehículos"),
            ("creditcard", "Pagos y cobros")
        ])
        
        let filasAsistencia = crearFilas([
            ("questionmark.circle", "Centro de ayuda"),
            ("shield", "Privacidad y seguridad")
        ])
        
        [tituloCuenta, filasCuenta, tituloAsistencia, filasAsistencia].forEach { stack.addArrangedSubview($0) }
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: summaryStack?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 36),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 24)
        ])
        
        stackOpcionesCuenta = stack
    }
    
    func crearTituloSeccion(_ texto: String) -> UILabel {
        let lblTitulo = UILabel()
        lblTitulo.text = texto
        lblTitulo.font = .boldSystemFont(ofSize: 18)
        return lblTitulo
    }
    
    func crearFilas(_ filas: [(String, String)]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        
        for (indice, fila) in filas.enumerated() {
            let vistaFila = UIView()
            vistaFila.translatesAutoresizingMaskIntoConstraints = false
            
            let icono = UIImageView(image: UIImage(systemName: fila.0))
            icono.translatesAutoresizingMaskIntoConstraints = false
            icono.tintColor = WayraTheme.textPrimary
            
            let etiquetaTitulo = UILabel()
            etiquetaTitulo.translatesAutoresizingMaskIntoConstraints = false
            etiquetaTitulo.text = fila.1
            etiquetaTitulo.font = .systemFont(ofSize: 18, weight: .medium)
            
            let iconoChevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            iconoChevron.translatesAutoresizingMaskIntoConstraints = false
            iconoChevron.tintColor = WayraTheme.textSecondary
            
            vistaFila.addSubview(icono)
            vistaFila.addSubview(etiquetaTitulo)
            vistaFila.addSubview(iconoChevron)
            
            NSLayoutConstraint.activate([
                vistaFila.heightAnchor.constraint(equalToConstant: 66),
                icono.leadingAnchor.constraint(equalTo: vistaFila.leadingAnchor),
                icono.centerYAnchor.constraint(equalTo: vistaFila.centerYAnchor),
                icono.widthAnchor.constraint(equalToConstant: 24),
                icono.heightAnchor.constraint(equalToConstant: 24),
                
                etiquetaTitulo.leadingAnchor.constraint(equalTo: icono.trailingAnchor, constant: 16),
                etiquetaTitulo.centerYAnchor.constraint(equalTo: vistaFila.centerYAnchor),
                
                iconoChevron.trailingAnchor.constraint(equalTo: vistaFila.trailingAnchor),
                iconoChevron.centerYAnchor.constraint(equalTo: vistaFila.centerYAnchor)
            ])
            
            stack.addArrangedSubview(vistaFila)
            
            if indice < filas.count - 1 {
                let divisor = UIView()
                divisor.backgroundColor = WayraTheme.divider
                divisor.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([divisor.heightAnchor.constraint(equalToConstant: 1)])
                stack.addArrangedSubview(divisor)
            }
        }
        
        return stack
    }
}
