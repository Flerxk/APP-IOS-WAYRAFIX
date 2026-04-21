//
//  RastreoViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
import MapKit
import CoreData

class RastreoViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var infoPanelView: UIView!
    @IBOutlet weak var perfilImageView: UIImageView!
    @IBOutlet weak var lblNombreMecanico: UILabel!
    @IBOutlet weak var lblEstadoServicio: UILabel!
    @IBOutlet weak var btnCancelar: UIButton!
    
    var vehiculoAveriado: VehiculoEntity?
    var direccionServicio: String?
    private weak var lblEtaMinutos: UILabel?
    private weak var lblEtaHora: UILabel?
    private weak var barraProgreso: UIProgressView?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
        
    func setupUI() {
        view.backgroundColor = WayraTheme.background
        infoPanelView.layer.cornerRadius = 30
        infoPanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        infoPanelView.layer.shadowColor = UIColor.black.cgColor
        infoPanelView.layer.shadowOpacity = 0.08
        infoPanelView.layer.shadowOffset = CGSize(width: 0, height: -6)
        infoPanelView.layer.shadowRadius = 16
        perfilImageView.layer.cornerRadius = perfilImageView.frame.height / 2
        perfilImageView.clipsToBounds = true
        perfilImageView.tintColor = WayraTheme.accent
        
        lblNombreMecanico.text = "Carlos Mendoza"
        lblNombreMecanico.font = .boldSystemFont(ofSize: 24)
        lblEstadoServicio.text = "Grúa Plataforma • \(vehiculoAveriado?.placa ?? "ABC-123")"
        lblEstadoServicio.textColor = WayraTheme.textSecondary
        if let direccionServicio, !direccionServicio.isEmpty {
            lblEstadoServicio.text = "Grúa Plataforma • \(vehiculoAveriado?.placa ?? "ABC-123")\n\(direccionServicio)"
            lblEstadoServicio.numberOfLines = 2
        }
        
        btnCancelar.configuration = .filled()
        btnCancelar.configuration?.title = "Enviar Mensaje"
        btnCancelar.configuration?.baseBackgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        btnCancelar.configuration?.baseForegroundColor = .white
        btnCancelar.configuration?.cornerStyle = .large
        btnCancelar.titleLabel?.font = .boldSystemFont(ofSize: 20)
        btnCancelar.addTarget(self, action: #selector(btnCancelar(_:)), for: .touchUpInside)
        
        construirBloqueETA()
        
        if let auto = vehiculoAveriado {
            self.title = "En camino"
            guardarEnHistorial(estado: "Unidad asignada para \(auto.placa ?? "")")
        }
    }
    
    func construirBloqueETA() {
        guard lblEtaMinutos == nil else { return }
        
        let lblMin = UILabel()
        lblMin.translatesAutoresizingMaskIntoConstraints = false
        lblMin.text = "12 min"
        lblMin.font = .boldSystemFont(ofSize: 50)
        lblMin.textColor = WayraTheme.textPrimary
        
        let lblHora = UILabel()
        lblHora.translatesAutoresizingMaskIntoConstraints = false
        lblHora.text = "Llegada estimada a las 14:30"
        lblHora.font = .systemFont(ofSize: 16, weight: .medium)
        lblHora.textColor = WayraTheme.textSecondary
        
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0.6
        progress.trackTintColor = UIColor(white: 0.9, alpha: 1)
        progress.progressTintColor = WayraTheme.accent
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        progress.transform = CGAffineTransform(scaleX: 1, y: 3)
        
        infoPanelView.addSubview(lblMin)
        infoPanelView.addSubview(lblHora)
        infoPanelView.addSubview(progress)
        
        NSLayoutConstraint.activate([
            lblMin.leadingAnchor.constraint(equalTo: infoPanelView.leadingAnchor, constant: 24),
            lblMin.topAnchor.constraint(equalTo: infoPanelView.topAnchor, constant: 16),
            
            lblHora.leadingAnchor.constraint(equalTo: lblMin.leadingAnchor),
            lblHora.topAnchor.constraint(equalTo: lblMin.bottomAnchor, constant: 4),
            
            progress.leadingAnchor.constraint(equalTo: infoPanelView.leadingAnchor, constant: 24),
            infoPanelView.trailingAnchor.constraint(equalTo: progress.trailingAnchor, constant: 24),
            progress.topAnchor.constraint(equalTo: lblHora.bottomAnchor, constant: 20)
        ])
        
        lblEtaMinutos = lblMin
        lblEtaHora = lblHora
        barraProgreso = progress
    }

    func guardarEnHistorial(estado: String) {
        let nuevoServicio = ServicioEntity(context: self.context)
        
        let marca = vehiculoAveriado?.marca ?? "Vehículo"
        let placa = vehiculoAveriado?.placa ?? "Sin Placa"
        
        nuevoServicio.titulo = "Asistencia para \(marca) (\(placa))"
        nuevoServicio.fecha = Date()
        nuevoServicio.estado = estado
        
        do {
            try context.save()
            print("Servicio guardado en el historial con éxito")
        } catch {
            print("Error al guardar historial: \(error)")
        }
    }

    @IBAction func btnCancelar(_ sender: UIButton) {
        let alerta = UIAlertController(title: "Mensaje enviado", message: "Tu mensaje fue enviado al conductor asignado.", preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }

}
