//
//  GarageViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
internal import CoreData
import FirebaseAuth

class GarageViewController: UIViewController {

    @IBOutlet weak var btnAgregarVehiculo: UIButton!
    @IBOutlet weak var btnEscanearVIN: UIButton!
    @IBOutlet weak var viewVacía: UIView!
    @IBOutlet weak var tblVehiculos: UITableView!
    
    var listaVehiculos: [VehiculoEntity] = []
    private let context = ControladorPersistencia.compartido.contextoVista
    private lazy var repositorioVehiculo: RepositorioVehiculoProtocol = RepositorioVehiculoCoreData()
    private weak var botonAgregarVacio: UIButton?
    private weak var botonAgregarPrincipal: UIButton?
    private weak var etiquetaTituloVacio: UILabel?
    private weak var etiquetaSubtituloVacio: UILabel?
    private weak var etiquetaEstadoVacio: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        tblVehiculos.delegate = self
        tblVehiculos.dataSource = self
        setupUI()
        // Forzar consistencia global de estilos
        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cargarVehiculos()
        
        // Sincronizar desde Firebase en segundo plano
        repositorioVehiculo.descargarVehiculosDeFirestore { _ in
            // El observador ya disparará cargarVehiculos() si hay cambios
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        repositorioVehiculo.agregarObservador(self, selector: #selector(contextDidChange))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        repositorioVehiculo.quitarObservador(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }
    
    func cargarVehiculos() {
        do {
            listaVehiculos = try repositorioVehiculo.obtenerVehiculos()
            actualizarEstadoGarage()
        } catch {
            print("Error al cargar los vehículos: \(error)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mostrarDetalleVehiculo",
           let destino = segue.destination as? DetalleVehiculoViewController,
           let vehiculoElegido = sender as? VehiculoEntity {
            destino.vehiculo = vehiculoElegido
        } else if let destino = segue.destination as? AgregarVehiculoViewController,
                  let vehiculo = sender as? VehiculoEntity {
            destino.vehiculoAEditar = vehiculo
        }
    }
    
    func setupUI() {
        view.backgroundColor = .clear
        view.aplicarFondoRosadoRadial()
        title = "Mi Garage"
        tblVehiculos.backgroundColor = .clear
        tblVehiculos.separatorStyle = .none
        tblVehiculos.showsVerticalScrollIndicator = false
        tblVehiculos.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 18, right: 0)
        tblVehiculos.register(GarageVehiculoCell.self, forCellReuseIdentifier: GarageVehiculoCell.reuseId)
        
        botonAgregarPrincipal = btnAgregarVehiculo
        btnAgregarVehiculo.setTitle("Agregar", for: .normal)
        btnAgregarVehiculo.backgroundColor = UIColor(red: 0.92, green: 0.22, blue: 0.21, alpha: 1.0) // Rojo del wireframe
        btnAgregarVehiculo.tintColor = .white
        btnAgregarVehiculo.layer.cornerRadius = 24
        btnAgregarVehiculo.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btnAgregarVehiculo.addTarget(self, action: #selector(irAEscanearVIN), for: .touchUpInside)
        
        btnEscanearVIN.isHidden = true // Ocultar según wireframe
        
        if let boton = buscarBotonEnEstadoVacio() {
            botonAgregarVacio = boton
            boton.setTitle("Agregar", for: .normal)
            boton.backgroundColor = UIColor(red: 0.92, green: 0.22, blue: 0.21, alpha: 1.0)
            boton.tintColor = .white
            boton.layer.cornerRadius = 20
            boton.addTarget(self, action: #selector(irAEscanearVIN), for: .touchUpInside)
        }
        
        mapearEtiquetasEstadoVacio()
        actualizarTextosEstadoVacio()
    }
    
    func mapearEtiquetasEstadoVacio() {
        let etiquetas = viewVacía.subviews.compactMap { $0 as? UILabel }
        etiquetaEstadoVacio = etiquetas.first
        etiquetaTituloVacio = etiquetas.dropFirst().first
        etiquetaSubtituloVacio = etiquetas.dropFirst(2).first
    }
    
    func actualizarTextosEstadoVacio() {
        etiquetaEstadoVacio?.text = "Aún no hay vehículos"
        etiquetaTituloVacio?.text = "Empieza a construir tu garage"
        etiquetaSubtituloVacio?.text = "Registra un vehículo manualmente o adminístralo cuando quieras desde tu garage."
        etiquetaTituloVacio?.numberOfLines = 0
        etiquetaSubtituloVacio?.numberOfLines = 0
        etiquetaEstadoVacio?.textAlignment = .center
        etiquetaTituloVacio?.textAlignment = .center
        etiquetaSubtituloVacio?.textAlignment = .center
        etiquetaEstadoVacio?.font = .boldSystemFont(ofSize: 13)
        etiquetaTituloVacio?.font = .boldSystemFont(ofSize: 22)
        etiquetaSubtituloVacio?.font = .systemFont(ofSize: 17)
        etiquetaSubtituloVacio?.textColor = WayraTheme.textSecondary
    }
    
    func actualizarEstadoGarage() {
        let hasVehicles = !listaVehiculos.isEmpty
        viewVacía.isHidden = hasVehicles
        tblVehiculos.isHidden = !hasVehicles
        tblVehiculos.reloadData()
        botonAgregarPrincipal?.isHidden = false
    }
    
    func buscarBotonEnEstadoVacio() -> UIButton? {
        for subview in viewVacía.subviews {
            if let button = subview as? UIButton { return button }
        }
        return nil
    }
    
    @objc func contextDidChange(_ notification: Notification) {
        cargarVehiculos()
    }
    
    @objc func irAAgregarVehiculo() {
        performSegue(withIdentifier: "mostrarAgregarVehiculo", sender: nil)
    }
    
    @objc func irAEscanearVIN() {
        performSegue(withIdentifier: "mostrarScanVIN", sender: nil)
    }
}

extension GarageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listaVehiculos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: GarageVehiculoCell.reuseId, for: indexPath)
        let vehiculo = listaVehiculos[indexPath.row]

        let placa = vehiculo.placa ?? "Sin placa"
        let marca = vehiculo.marca ?? ""
        let modelo = vehiculo.modelo ?? ""
        let titulo = "\(marca) \(modelo)".trimmingCharacters(in: .whitespaces)
        let badge = indexPath.row == 0 ? "Principal" : "Secundario"
        let colorBadge = indexPath.row == 0 ? WayraTheme.accent : WayraTheme.primary
        (celda as? GarageVehiculoCell)?.configurar(
            titulo: titulo.isEmpty ? "Vehículo" : titulo,
            placa: placa,
            badge: badge,
            colorBadge: colorBadge
        )
        return celda
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        126
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vehiculo = listaVehiculos[indexPath.row]
        
        performSegue(withIdentifier: "mostrarDetalleVehiculo", sender: vehiculo)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let autoAEliminar = listaVehiculos[indexPath.row]
            
            // Sincronizar eliminación en Firestore
            if let uid = Auth.auth().currentUser?.uid, let vin = autoAEliminar.vin {
                FirebaseManager.shared.eliminarVehiculo(uidUsuario: uid, idVehiculo: vin) { _ in }
            }
            
            context.delete(autoAEliminar)
            
            do {
                try context.save()
                listaVehiculos.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                actualizarEstadoGarage()
            } catch {
                print("Error al borrar: \(error)")
            }
        }
    }
}

final class GarageVehiculoCell: UITableViewCell {
    static let reuseId = "GarageVehiculoCell"
    
    private let card = UIView()
    private let imgVehiculo = UIImageView()
    private let lblTitulo = UILabel()
    private let lblPlaca = UILabel()
    private let lblBadge = UILabel()
    private let imgMas = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = WayraTheme.divider.cgColor
        
        imgVehiculo.translatesAutoresizingMaskIntoConstraints = false
        imgVehiculo.image = UIImage(systemName: "car.fill")
        // Ícono del auto: Gris oscuro (paleta oficial, sin azul genérico)
        imgVehiculo.tintColor = WayraTheme.textPrimary
        imgVehiculo.contentMode = .scaleAspectFit
        imgVehiculo.backgroundColor = UIColor(white: 0.96, alpha: 1)
        imgVehiculo.layer.cornerRadius = 10
        imgVehiculo.clipsToBounds = true
        
        lblTitulo.translatesAutoresizingMaskIntoConstraints = false
        lblTitulo.font = .boldSystemFont(ofSize: 20)
        lblTitulo.textColor = WayraTheme.textPrimary
        
        lblPlaca.translatesAutoresizingMaskIntoConstraints = false
        lblPlaca.font = .systemFont(ofSize: 17, weight: .medium)
        lblPlaca.textColor = WayraTheme.textSecondary
        
        lblBadge.translatesAutoresizingMaskIntoConstraints = false
        lblBadge.font = .boldSystemFont(ofSize: 13)
        lblBadge.textColor = .white
        lblBadge.textAlignment = .center
        lblBadge.layer.cornerRadius = 8
        lblBadge.layer.masksToBounds = true
        
        imgMas.translatesAutoresizingMaskIntoConstraints = false
        imgMas.image = UIImage(systemName: "ellipsis")
        imgMas.tintColor = WayraTheme.textSecondary
        imgMas.contentMode = .scaleAspectFit
        
        contentView.addSubview(card)
        card.addSubview(imgVehiculo)
        card.addSubview(lblTitulo)
        card.addSubview(lblPlaca)
        card.addSubview(lblBadge)
        card.addSubview(imgMas)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            contentView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 10),
            contentView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 8),
            
            imgVehiculo.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            imgVehiculo.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            imgVehiculo.widthAnchor.constraint(equalToConstant: 106),
            imgVehiculo.heightAnchor.constraint(equalToConstant: 86),
            
            lblTitulo.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            lblTitulo.leadingAnchor.constraint(equalTo: imgVehiculo.trailingAnchor, constant: 16),
            
            lblPlaca.topAnchor.constraint(equalTo: lblTitulo.bottomAnchor, constant: 8),
            lblPlaca.leadingAnchor.constraint(equalTo: lblTitulo.leadingAnchor),
            
            lblBadge.topAnchor.constraint(equalTo: lblPlaca.bottomAnchor, constant: 10),
            lblBadge.leadingAnchor.constraint(equalTo: lblTitulo.leadingAnchor),
            lblBadge.heightAnchor.constraint(equalToConstant: 28),
            lblBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),
            
            imgMas.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            card.trailingAnchor.constraint(equalTo: imgMas.trailingAnchor, constant: 14),
            imgMas.widthAnchor.constraint(equalToConstant: 18),
            imgMas.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    func configurar(titulo: String, placa: String, badge: String, colorBadge: UIColor) {
        lblTitulo.text = titulo
        lblPlaca.text = placa
        lblBadge.text = "  \(badge)  "
        lblBadge.backgroundColor = colorBadge
    }
}
