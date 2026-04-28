//
//  RastreoViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
import MapboxMaps
import CoreData
import FirebaseDatabase

class RastreoViewController: UIViewController {

    @IBOutlet weak var mapView: UIView! // Contenedor para Mapbox
    private var mapboxView: MapView!
    private var pointAnnotationManager: PointAnnotationManager?
    
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
    private var gruaAnnotation: PointAnnotation?
    
    let context = ControladorPersistencia.compartido.contextoVista
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        setupUI()
        configurarMapa()
        iniciarRastreoEnTiempoReal()
        
        // Asegurar que el mapa esté al fondo
        view.sendSubviewToBack(mapView)
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
        
        btnCancelar.isHidden = true 
        
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
        let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ?? ""
        let myResourceOptions = ResourceOptions(accessToken: accessToken)
        let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions, styleURI: .streets)
        
        mapboxView = MapView(frame: mapView.bounds, mapInitOptions: myMapInitOptions)
        mapboxView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(mapboxView)
        
        NSLayoutConstraint.activate([
            mapboxView.topAnchor.constraint(equalTo: mapView.topAnchor),
            mapboxView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            mapboxView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor),
            mapboxView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor)
        ])
        
        mapboxView.location.options.puckType = .puck2D()
        pointAnnotationManager = mapboxView.annotations.makePointAnnotationManager()
    }
    
    private func iniciarRastreoEnTiempoReal() {
        guard let idServicio = sosData?.id_servicio else {
            print("Error: No hay ID de servicio para rastrear.")
            return
        }
        
        let rutaRastreo = "activos/\(idServicio)"
        print("Escuchando rastreo en: \(rutaRastreo)")
        
        ref.child(rutaRastreo).observe(.value) { [weak self] snapshot in
            guard let self = self, let dict = snapshot.value as? [String: Any] else { return }
            
            // 1. Manejar Estado y Detener Rastreo si es necesario
            if let estado = dict["estado"] as? String {
                let estadoLimpio = estado.lowercased()
                self.lblEstadoServicio.text = "Estado: \(estado.capitalized)"
                
                if estadoLimpio == "finalizado" || estadoLimpio == "rechazado" {
                    print("Servicio \(estadoLimpio). Deteniendo rastreo.")
                    self.ref.child(rutaRastreo).removeAllObservers()
                    
                    let mensaje = estadoLimpio == "finalizado" ? "Tu servicio ha finalizado con éxito." : "Tu servicio ha sido rechazado o cancelado."
                    self.mostrarAlertaFinalizacion(mensaje: mensaje)
                }
            }
            
            // 2. Actualizar Ubicación de la Grúa
            if let ubicacion = dict["ubicacion_grua"] as? [String: Any],
               let lat = ubicacion["lat"] as? Double,
               let lng = ubicacion["lng"] as? Double {
                self.actualizarUbicacionGrua(lat: lat, lng: lng)
            }
            
            // 3. Actualizar Info Adicional (Nombre grúa si cambió)
            if let nombreGrua = dict["nombre_grua"] as? String {
                self.lblNombreMecanico.text = nombreGrua
            }
        }
    }
    
    private func mostrarAlertaFinalizacion(mensaje: String) {
        let alerta = UIAlertController(title: "Servicio Actualizado", message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
        self.present(alerta, animated: true)
    }
    
    private var markerAnimationTimer: Timer?
    private var currentMarkerCoordinate: CLLocationCoordinate2D?

    private func actualizarUbicacionGrua(lat: Double, lng: Double) {
        let coordenadaFinal = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        guard let annotation = gruaAnnotation else {
            // Primera vez: crear anotación
            var newAnnotation = PointAnnotation(coordinate: coordenadaFinal)
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
            if let imagen = UIImage(systemName: "car.side.fill", withConfiguration: config) {
                newAnnotation.image = .init(image: imagen, name: "grua-marker")
            }
            
            pointAnnotationManager?.annotations = [newAnnotation]
            gruaAnnotation = newAnnotation
            currentMarkerCoordinate = coordenadaFinal
            
            mapboxView.camera.ease(to: CameraOptions(center: coordenadaFinal, zoom: 15), duration: 1.5)
            return
        }
        
        // Si ya existe, animamos desde la posición actual a la nueva
        markerAnimationTimer?.invalidate()
        let startCoord = currentMarkerCoordinate ?? annotation.point.coordinates
        let duration: TimeInterval = 2.0 // Duración de la animación entre puntos
        let startTime = Date()
        
        markerAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let fraction = min(elapsed / duration, 1.0)
            
            // Interpolación lineal simple
            let interpolatedLat = startCoord.latitude + (coordenadaFinal.latitude - startCoord.latitude) * fraction
            let interpolatedLng = startCoord.longitude + (coordenadaFinal.longitude - startCoord.longitude) * fraction
            let currentCoord = CLLocationCoordinate2D(latitude: interpolatedLat, longitude: interpolatedLng)
            
            self.currentMarkerCoordinate = currentCoord
            var updatedAnnotation = annotation
            updatedAnnotation.point = Point(currentCoord)
            self.pointAnnotationManager?.annotations = [updatedAnnotation]
            self.gruaAnnotation = updatedAnnotation
            
            if fraction >= 1.0 {
                timer.invalidate()
            }
        }
        
        // Centrar cámara suavemente
        mapboxView.camera.ease(to: CameraOptions(center: coordenadaFinal), duration: 2.0)
    }
}

