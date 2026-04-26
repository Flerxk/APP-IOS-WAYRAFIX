//
//  RastreoViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
import MapKit
import CoreData
import FirebaseDatabase

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
    
    // Firebase Realtime Database
    private var ref: DatabaseReference!
    private var gruaAnnotation: MKPointAnnotation?
    
    let context = ControladorPersistencia.compartido.contextoVista
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setupUI()
        configurarMapa()
        iniciarRastreoEnTiempoReal()
    }
    
    deinit {
        guard let idServicio = sosData?.id_servicio else { return }
        ref.child("activos/\(idServicio)").removeAllObservers()
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

    // MARK: - Lógica de Rastreo Realtime
    
    private func configurarMapa() {
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    private func iniciarRastreoEnTiempoReal() {
        guard let idServicio = sosData?.id_servicio else {
            print("Error: No hay ID de servicio para rastrear.")
            return
        }
        
        // El backend guarda en: activos/{id_servicio}
        let rutaRastreo = "activos/\(idServicio)"
        print("Escuchando rastreo en: \(rutaRastreo)")
        
        ref.child(rutaRastreo).observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: Any] else { return }
            
            // 1. Actualizar Estado
            if let estado = dict["estado"] as? String {
                self.lblEstadoServicio.text = "Estado: \(estado.capitalized)"
            }
            
            // 2. Obtener Coordenadas de la Grúa
            if let ubicacion = dict["ubicacion_grua"] as? [String: Any],
               let lat = ubicacion["lat"] as? Double,
               let lng = ubicacion["lng"] as? Double {
                self.actualizarUbicacionGrua(lat: lat, lng: lng)
            }
        }
    }
    
    private func actualizarUbicacionGrua(lat: Double, lng: Double) {
        let coordenada = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        if let annotation = gruaAnnotation {
            // Animar movimiento
            UIView.animate(withDuration: 1.0) {
                annotation.coordinate = coordenada
            }
        } else {
            // Crear por primera vez
            let annotation = MKPointAnnotation()
            annotation.title = sosData?.nombre_grua ?? "Grúa de Asistencia"
            annotation.coordinate = coordenada
            mapView.addAnnotation(annotation)
            gruaAnnotation = annotation
            
            // Centrar el mapa la primera vez
            let region = MKCoordinateRegion(center: coordenada, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - MKMapViewDelegate
extension RastreoViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let identifier = "GruaMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            // Icono de grúa (SF Symbol o imagen personalizada)
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            let imagen = UIImage(systemName: "box.truck.fill", withConfiguration: config)
            
            let imageView = UIImageView(image: imagen)
            imageView.tintColor = WayraTheme.brand
            imageView.backgroundColor = .white
            imageView.layer.cornerRadius = 20
            imageView.layer.borderWidth = 3
            imageView.layer.borderColor = WayraTheme.brand.cgColor
            imageView.contentMode = .center
            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            
            annotationView?.addSubview(imageView)
            annotationView?.frame = imageView.frame
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}
