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
            
            if let estado = dict["estado"] as? String {
                self.lblEstadoServicio.text = "Estado: \(estado.capitalized)"
            }
            
            if let ubicacion = dict["ubicacion_grua"] as? [String: Any],
               let lat = ubicacion["lat"] as? Double,
               let lng = ubicacion["lng"] as? Double {
                self.actualizarUbicacionGrua(lat: lat, lng: lng)
            }
        }
    }
    
    private func actualizarUbicacionGrua(lat: Double, lng: Double) {
        let coordenada = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        if var annotation = gruaAnnotation {
            annotation.point = Point(coordenada)
            pointAnnotationManager?.annotations = [annotation]
        } else {
            var annotation = PointAnnotation(coordinate: coordenada)
            
            // Personalizar icono de la grúa
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            if let imagen = UIImage(systemName: "box.truck.fill", withConfiguration: config) {
                // Para simplificar en Mapbox v10+, usamos una imagen registrada o cargada
                // Aquí asignamos la imagen directamente a la anotación
                annotation.image = .init(image: imagen, name: "grua-marker")
            }
            
            pointAnnotationManager?.annotations = [annotation]
            gruaAnnotation = annotation
            
            // Centrar el mapa la primera vez
            mapboxView.camera.ease(
                to: CameraOptions(center: coordenada, zoom: 14),
                duration: 1.5
            )
        }
    }
}

