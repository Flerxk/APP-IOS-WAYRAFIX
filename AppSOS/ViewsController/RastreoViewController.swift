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
    var sosData: SOSResponse?
    
    @IBOutlet weak var lblEtaMinutos: UILabel!
    @IBOutlet weak var lblEtaHora: UILabel!
    @IBOutlet weak var barraProgreso: UIProgressView!
    @IBOutlet weak var btnMensaje: UIButton!
    @IBOutlet weak var btnLlamar: UIButton!
    @IBOutlet weak var btnCerrarRastreo: UIButton!
    
    let context = ControladorPersistencia.compartido.contextoVista
    
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
        
        lblNombreMecanico.text = sosData?.nombre_grua ?? "Unidad en Camino"
        lblNombreMecanico.font = .boldSystemFont(ofSize: 24)
        
        let subInfo = sosData?.id_servicio ?? (vehiculoAveriado?.placa ?? "WayraFix")
        lblEstadoServicio.text = "Grúa Asignada • \(subInfo)"
        lblEstadoServicio.textColor = WayraTheme.textSecondary
        if let direccionServicio, !direccionServicio.isEmpty {
            lblEstadoServicio.text = "Grúa Plataforma • \(vehiculoAveriado?.placa ?? "ABC-123")\n\(direccionServicio)"
            lblEstadoServicio.numberOfLines = 2
        }
        
        btnCancelar.isHidden = true // Usaremos los nuevos botones
        
        btnMensaje.applyPrimaryStyle(title: "Enviar Mensaje")
        btnMensaje.configuration?.image = UIImage(systemName: "bubble.left.fill")
        btnMensaje.configuration?.imagePadding = 8
        
        btnLlamar.configuration = .plain()
        btnLlamar.configuration?.image = UIImage(systemName: "phone.fill")
        btnLlamar.backgroundColor = UIColor(white: 0.95, alpha: 1)
        btnLlamar.layer.cornerRadius = 22
        btnLlamar.tintColor = WayraTheme.textPrimary
        
        btnCerrarRastreo.configuration = .plain()
        btnCerrarRastreo.configuration?.image = UIImage(systemName: "xmark")
        btnCerrarRastreo.layer.borderWidth = 1
        btnCerrarRastreo.layer.borderColor = WayraTheme.divider.cgColor
        btnCerrarRastreo.layer.cornerRadius = 22
        btnCerrarRastreo.tintColor = WayraTheme.textPrimary
        
        // UI configurada vía Storyboard
        
        if let auto = vehiculoAveriado {
            self.title = "En camino"
            guardarEnHistorial(estado: "Unidad asignada para \(auto.placa ?? "")")
        }
    }
    
    func actualizarProgreso(minutos: Int, hora: String, progreso: Float) {
        lblEtaMinutos.text = "\(minutos) min"
        lblEtaHora.text = "Llegada estimada a las \(hora)"
        barraProgreso.progress = progreso
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

    @IBAction func btnMensajeTapped(_ sender: UIButton) {
        // Lógica para enviar mensaje
    }
    
    @IBAction func btnLlamarTapped(_ sender: UIButton) {
        // Lógica para llamar
    }
    
    @IBAction func btnCerrarTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func btnCancelar(_ sender: Any) {
        let alerta = UIAlertController(title: "Cancelar Servicio",
                                      message: "¿Estás seguro que deseas cancelar el servicio?",
                                      preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "No", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Sí, Cancelar", style: .destructive) { _ in
            self.guardarEnHistorial(estado: "Cancelado")
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alerta, animated: true)
    }

}
