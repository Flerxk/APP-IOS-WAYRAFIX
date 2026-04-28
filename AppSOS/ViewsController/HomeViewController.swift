//
//  HomeViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 9/04/26.
//

import UIKit
import CoreLocation
import CoreData
import FirebaseAuth
import MapboxMaps

protocol SeleccionVehiculoDelegate: AnyObject {
    func vehiculoElegidoParaSOS(_ vehiculo: VehiculoEntity)
}

class HomeViewController: UIViewController, CLLocationManagerDelegate {

    // Cambiamos MKMapView por una vista de Mapbox
    private var mapboxView: MapView!
    @IBOutlet weak var mapView: UIView! // Ahora lo tratamos como un contenedor
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var bottomPanel: UIView!
    @IBOutlet weak var catScrollView: UIScrollView!
    @IBOutlet weak var btnSOS: UIButton!
    @IBOutlet weak var lblTituloDireccion: UILabel!
    @IBOutlet weak var lblDireccionActual: UILabel!
    
    let locationManager = CLLocationManager()
    private var vehiculoSeleccionado: VehiculoEntity?
    private var ultimaUbicacionGeocodificada: CLLocation?
    private var direccionActual: String = "Selecciona tu ubicación actual"
    private var categoriaSeleccionada: Int = 0
    
    // UI adicional para selección de vehículo
    private let btnSeleccionarVehiculo: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Seleccionar Vehículo", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btn.tintColor = WayraTheme.brand
        btn.backgroundColor = WayraTheme.brandSoft.withAlphaComponent(0.2)
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    private let lblVehiculoInfo: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = WayraTheme.textSecondary
        lbl.text = "Ningún vehículo seleccionado"
        lbl.textAlignment = .center
        return lbl
    }()
    
    private let lblNeedHelp: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .boldSystemFont(ofSize: 22)
        lbl.textColor = .black
        lbl.text = "Need help?"
        return lbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocation()
        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
        
        // Asegurar que el mapa esté al fondo
        view.sendSubviewToBack(mapView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(actualizarDesdeSesion), name: .vehicleSelectionChanged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        actualizarDesdeSesion()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
        
        // Asegurar que el botón SOS sea perfectamente circular
        btnSOS.layer.cornerRadius = btnSOS.frame.height / 2
        btnSOS.configuration?.background.cornerRadius = btnSOS.frame.height / 2
        
        // El mapa debe ocupar todo su contenedor
        mapboxView?.frame = mapView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Forzar visibilidad del mapa y traerlo al frente de la capa de fondo
        mapView.alpha = 1.0
        mapView.isHidden = false
        view.bringSubviewToFront(mapView)
        view.bringSubviewToFront(topBarView)
        view.bringSubviewToFront(bottomPanel)
    }
    
    @objc private func actualizarDesdeSesion() {
        guard let uid = Auth.auth().currentUser?.uid,
              let selectedVin = VehicleSessionManager.shared.getSelectedVehicleVin() else {
            // Si no hay VIN seleccionado, intentar cargar el primero disponible
            cargarPrimerVehiculoDisponible()
            return
        }
        
        let context = ControladorPersistencia.compartido.contextoVista
        let request: NSFetchRequest<VehiculoEntity> = VehiculoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "vin == %@ AND propietario.id == %@", selectedVin, uid)
        
        do {
            if let vehiculo = try context.fetch(request).first {
                self.vehiculoElegidoParaSOS(vehiculo)
            } else {
                cargarPrimerVehiculoDisponible()
            }
        } catch {
            print("Error cargando vehículo de sesión: \(error)")
        }
    }
    
    private func cargarPrimerVehiculoDisponible() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let context = ControladorPersistencia.compartido.contextoVista
        let request: NSFetchRequest<VehiculoEntity> = VehiculoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "propietario.id == %@", uid)
        request.fetchLimit = 1
        
        do {
            if let primero = try context.fetch(request).first {
                VehicleSessionManager.shared.setSelectedVehicleVin(primero.vin)
            } else {
                // Limpiar UI si no hay vehículos
                self.vehiculoSeleccionado = nil
                self.lblVehiculoInfo.text = "Ningún vehículo seleccionado"
                self.lblVehiculoInfo.textColor = WayraTheme.textSecondary
                self.btnSeleccionarVehiculo.setTitle("Seleccionar Vehículo", for: .normal)
            }
        } catch {
            print("Error cargando primer vehículo: \(error)")
        }
    }

    func setupUI() {
        view.backgroundColor = .clear
        view.aplicarFondoRosadoRadial()
        topBarView.applyCardStyle(radius: 24)
        topBarView.layer.borderWidth = 1
        topBarView.layer.borderColor = UIColor(white: 0.94, alpha: 1).cgColor
        bottomPanel.layer.cornerRadius = 34
        bottomPanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomPanel.backgroundColor = WayraTheme.card
        bottomPanel.layer.shadowColor = UIColor.black.cgColor
        bottomPanel.layer.shadowOpacity = 0.06
        bottomPanel.layer.shadowOffset = CGSize(width: 0, height: -6)
        bottomPanel.layer.shadowRadius = 16
        
        btnSOS.applyBrandStyle(title: "SOS")
        btnSOS.titleLabel?.font = .boldSystemFont(ofSize: 28)
        
        // Configuración para que sea perfectamente redondo y tenga sombra
        btnSOS.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btnSOS.widthAnchor.constraint(equalToConstant: 110),
            btnSOS.heightAnchor.constraint(equalToConstant: 110)
        ])
        
        // Usar la configuración de fondo para el radio de la esquina
        btnSOS.configuration?.cornerStyle = .fixed
        btnSOS.configuration?.background.cornerRadius = 55
        
        // Sombra (no usar masksToBounds = true para que se vea la sombra)
        btnSOS.layer.shadowColor = WayraTheme.brand.cgColor
        btnSOS.layer.shadowOpacity = 0.4
        btnSOS.layer.shadowOffset = CGSize(width: 0, height: 8)
        btnSOS.layer.shadowRadius = 12
        btnSOS.layer.masksToBounds = false
        
        btnSOS.addTarget(self, action: #selector(btnSOSTapped(_:)), for: .touchUpInside)
        
        let gestoPresionadoSOS = UILongPressGestureRecognizer(target: self, action: #selector(manejarPresionadoSOS(_:)))
        gestoPresionadoSOS.minimumPressDuration = 0.45
        btnSOS.addGestureRecognizer(gestoPresionadoSOS)
        
        lblTituloDireccion.text = "WAYRAFIX Assistance"
        lblTituloDireccion.font = .boldSystemFont(ofSize: 18)
        lblDireccionActual.text = direccionActual
        lblDireccionActual.font = .systemFont(ofSize: 15, weight: .medium)
        lblDireccionActual.textColor = WayraTheme.textSecondary
        
        setupVehicleSelectionUI()
        styleCategorias()
        styleTopActionButton()
    }
    
    func setupVehicleSelectionUI() {
        bottomPanel.addSubview(lblNeedHelp)
        bottomPanel.addSubview(btnSeleccionarVehiculo)
        bottomPanel.addSubview(lblVehiculoInfo)
        
        btnSeleccionarVehiculo.addTarget(self, action: #selector(btnSeleccionarVehiculoTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            lblNeedHelp.topAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: 24),
            lblNeedHelp.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 24),
            
            lblVehiculoInfo.topAnchor.constraint(equalTo: lblNeedHelp.bottomAnchor, constant: 16),
            lblVehiculoInfo.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 24),
            
            btnSeleccionarVehiculo.centerYAnchor.constraint(equalTo: lblVehiculoInfo.centerYAnchor),
            btnSeleccionarVehiculo.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -24),
            btnSeleccionarVehiculo.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Ajustar el scroll de categorías para que empiece debajo de la info
        if let topCat = bottomPanel.constraints.first(where: { $0.firstItem as? UIView == catScrollView && $0.firstAttribute == .top }) {
            topCat.constant = 100 
        }
    }
    
    @objc func btnSeleccionarVehiculoTapped() {
        performSegue(withIdentifier: "irAGarage", sender: nil)
    }

    func styleCategorias() {
        guard let stack = catScrollView.subviews.first(where: { $0 is UIStackView }) as? UIStackView else { return }
        for (indice, vista) in stack.arrangedSubviews.enumerated() {
            vista.layer.cornerRadius = 18
            vista.layer.masksToBounds = true
            
            let seleccionado = (indice == categoriaSeleccionada)
            vista.backgroundColor = seleccionado ? WayraTheme.brandSoft : .white
            vista.layer.borderWidth = seleccionado ? 2 : 1
            vista.layer.borderColor = seleccionado ? WayraTheme.brand.cgColor : UIColor(white: 0.94, alpha: 1).cgColor
            
            if let img = vista.subviews.compactMap({ $0 as? UIImageView }).first {
                img.tintColor = seleccionado ? WayraTheme.brand : WayraTheme.textSecondary
                img.contentMode = .scaleAspectFit
                
                // Actualizar las restricciones existentes del Storyboard para hacerlos más pequeños (24x24)
                for constraint in img.constraints {
                    if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                        constraint.constant = 24
                    }
                }
            }
            
            if let label = vista.subviews.compactMap({ $0 as? UILabel }).first {
                label.textColor = seleccionado ? WayraTheme.textPrimary : WayraTheme.textSecondary
                label.font = seleccionado ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13, weight: .medium)
                label.textAlignment = .center
            }
            
            vista.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(categoriaTapped(_:)))
            vista.gestureRecognizers?.forEach { vista.removeGestureRecognizer($0) }
            vista.addGestureRecognizer(tap)
            vista.tag = indice
        }
    }
    
    @objc func categoriaTapped(_ gesture: UITapGestureRecognizer) {
        guard let vista = gesture.view else { return }
        categoriaSeleccionada = vista.tag
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        styleCategorias()
    }
    
    func styleTopActionButton() {
        if let btn = topBarView.subviews.compactMap({ $0 as? UIButton }).first {
            btn.configuration = .plain()
            btn.configuration?.image = UIImage(systemName: "slider.horizontal.3")
            btn.tintColor = WayraTheme.textPrimary
            btn.backgroundColor = .white
            btn.layer.cornerRadius = 18
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor(white: 0.93, alpha: 1).cgColor
            btn.clipsToBounds = true
        }
    }
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Configurar Mapbox MapView
        let myResourceOptions = ResourceOptions(accessToken: Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ?? "")
        let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions, styleURI: .streets)
        
        mapboxView = MapView(frame: mapView.bounds, mapInitOptions: myMapInitOptions)
        mapboxView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(mapboxView)
        
        // Usar constraints para que el mapa ocupe todo el contenedor
        NSLayoutConstraint.activate([
            mapboxView.topAnchor.constraint(equalTo: mapView.topAnchor),
            mapboxView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            mapboxView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor),
            mapboxView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor)
        ])
        
        // Asegurar que el contenedor del mapa esté visible y no cubierto
        mapView.backgroundColor = .white
        view.bringSubviewToFront(mapView)
        view.bringSubviewToFront(topBarView)
        view.bringSubviewToFront(bottomPanel)
        
        // Configurar el indicador de ubicación de Mapbox
        mapboxView.location.options.puckType = .puck2D()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else {
            lblDireccionActual.text = "Activa la ubicación para ver tu dirección"
            return
        }
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let ubicacion = locations.last else { return }
        
        // Centrar cámara en Mapbox
        mapboxView.camera.ease(
            to: CameraOptions(center: ubicacion.coordinate, zoom: 15),
            duration: 1.3
        )
        
        if let ultimaUbicacionGeocodificada,
           ubicacion.distance(from: ultimaUbicacionGeocodificada) < 120 {
            return
        }
        
        self.ultimaUbicacionGeocodificada = ubicacion
        
        Task { [weak self] in
            guard let self = self else { return }
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(ubicacion)
                if let lugar = placemarks.first {
                    let nombre = lugar.name ?? ""
                    let calle = lugar.thoroughfare ?? ""
                    let ciudad = lugar.locality ?? ""
                    
                    let partes = [nombre, calle, ciudad].filter { !$0.isEmpty }
                    let texto = partes.joined(separator: ", ")
                    self.direccionActual = texto.isEmpty ? "Ubicación detectada" : texto
                }
                
                DispatchQueue.main.async {
                    self.lblDireccionActual.text = self.direccionActual
                }
            } catch {
                print("Error en geocodificación: \(error.localizedDescription)")
                self.lblDireccionActual.text = "Ubicación actual"
            }
        }
    }
    
    @objc func manejarPresionadoSOS(_ gesto: UILongPressGestureRecognizer) {
        if gesto.state == .began {
            btnSOSTapped(btnSOS)
        }
    }
    
    @IBAction func btnSOSTapped(_ sender: UIButton) {
        guard let _ = Auth.auth().currentUser else {
            mostrarAlertaValidacion(mensaje: "Debes estar logueado para enviar un SOS.")
            return
        }
        
        guard let vehiculo = vehiculoSeleccionado else {
            // Usamos el segue que va al Garage
            performSegue(withIdentifier: "irAGarage", sender: nil)
            return
        }
        
        // ENVÍO DIRECTO: Sin confirmación intermedia como solicitó el usuario
        prepararYEnviarSOS(vehiculo: vehiculo)
    }
    
    private func prepararYEnviarSOS(vehiculo: VehiculoEntity) {
        guard let usuarioFirebase = Auth.auth().currentUser else { return }
        let tipoSiniestro = obtenerNombreCategoriaSeleccionada()
        
        guard let ubicacion = locationManager.location else {
            mostrarAlertaValidacion(mensaje: "No se pudo obtener tu ubicación actual.")
            return
        }
        
        // Obtener datos del usuario desde Core Data para tener el nombre real y celular
        var nombreReal = usuarioFirebase.displayName ?? usuarioFirebase.email ?? "Usuario"
        var celularReal = ""
        
        let context = ControladorPersistencia.compartido.contextoVista
        let request: NSFetchRequest<UsuarioEntity> = UsuarioEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", usuarioFirebase.uid)
        
        if let usuario = try? context.fetch(request).first {
            nombreReal = usuario.nombre ?? nombreReal
            celularReal = usuario.celular ?? ""
        }
        
        let requestPayload = SOSRequest(
            uid_usuario: usuarioFirebase.uid,
            nombre_cliente: nombreReal,
            celular: celularReal,
            vehiculo_id: VehiculoInfo(
                modelo: vehiculo.modelo ?? "N/A",
                placa: vehiculo.placa ?? "N/A",
                marca: vehiculo.marca ?? "N/A",
                color: vehiculo.color ?? "N/A",
                vin: vehiculo.vin ?? "N/A",
                transmision: vehiculo.transmision ?? "N/A"
            ),
            tipo_siniestro: tipoSiniestro,
            latitud: ubicacion.coordinate.latitude,
            longitud: ubicacion.coordinate.longitude
        )
        
        enviarSolicitudSOS(requestPayload, vehiculo: vehiculo)
    }
    
    private func obtenerNombreCategoriaSeleccionada() -> String {
        guard let stack = catScrollView.subviews.first(where: { $0 is UIStackView }) as? UIStackView,
              categoriaSeleccionada < stack.arrangedSubviews.count else {
            return "General"
        }
        
        let vista = stack.arrangedSubviews[categoriaSeleccionada]
        if let label = vista.subviews.compactMap({ $0 as? UILabel }).first {
            return label.text ?? "Incidente"
        }
        return "Incidente"
    }
    
    private func enviarSolicitudSOS(_ payload: SOSRequest, vehiculo: VehiculoEntity) {
        // Mostrar un pequeño feedback visual de carga si fuera necesario, o proceder directo
        
        // 1. Enviar al Backend (API)
        APIService.shared.crearAsistencia(payload: payload) { [weak self] resultado in
            guard let self = self else { return }
            
            switch resultado {
            case .success(let respuesta):
                // 2. Guardar también en Firebase (Directo)
                self.guardarSOSEnFirebase(payload: payload)
                
                // 3. Mostrar alerta de éxito directa
                self.mostrarAlertaExitoDirecta(para: vehiculo, sosResponse: respuesta)
                
            case .failure(let error):
                print("Error enviando SOS: \(error.localizedDescription)")
                self.mostrarAlertaValidacion(mensaje: "No se pudo conectar con el servidor.")
            }
        }
    }
    
    private func mostrarAlertaExitoDirecta(para vehiculo: VehiculoEntity, sosResponse: SOSResponse?) {
        let alerta = UIAlertController(
            title: "¡Ayuda Enviada! 🚨",
            message: "Tu solicitud de auxilio mecánico ha sido recibida. Un agente se pondrá en contacto contigo pronto.",
            preferredStyle: .alert
        )
        
        alerta.addAction(UIAlertAction(title: "Ver Seguimiento", style: .default) { _ in
            let contexto: [String: Any?] = ["vehiculo": vehiculo, "sos": sosResponse]
            self.performSegue(withIdentifier: "irARastreo", sender: contexto)
        })
        
        alerta.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        self.present(alerta, animated: true)
    }
    
    private func guardarSOSEnFirebase(payload: SOSRequest) {
        // Convertir SOSRequest a Diccionario para Firestore
        let datos: [String: Any] = [
            "uid_usuario": payload.uid_usuario,
            "nombre_cliente": payload.nombre_cliente,
            "celular": payload.celular,
            "tipo_siniestro": payload.tipo_siniestro,
            "latitud": payload.latitud,
            "longitud": payload.longitud,
            "fecha_creacion": FieldValue.serverTimestamp(),
            "estado": "pendiente",
            "vehiculo": [
                "marca": payload.vehiculo_id.marca,
                "modelo": payload.vehiculo_id.modelo,
                "placa": payload.vehiculo_id.placa,
                "color": payload.vehiculo_id.color,
                "vin": payload.vehiculo_id.vin,
                "transmision": payload.vehiculo_id.transmision
            ]
        ]
        
        FirebaseManager.shared.crearAsistencia(payload: datos) { error in
            if let error = error {
                print("Error guardando SOS en Firebase: \(error.localizedDescription)")
            } else {
                print("SOS guardado exitosamente en Firebase")
            }
        }
    }
    
    private func mostrarAlertaValidacion(mensaje: String) {
        let alerta = UIAlertController(title: "Atención", message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mostrarElegirVehiculo",
           let destino = segue.destination as? ElegirVehiculoViewController {
            destino.delegado = self
        } else if segue.identifier == "irARastreo",
                  let destino = segue.destination as? RastreoViewController {
            
            if let contexto = sender as? [String: Any?] {
                destino.vehiculoAveriado = contexto["vehiculo"] as? VehiculoEntity
                destino.sosData = contexto["sos"] as? SOSResponse
            }
            destino.direccionServicio = direccionActual
        }
    }
}

extension HomeViewController: SeleccionVehiculoDelegate {
    func vehiculoElegidoParaSOS(_ vehiculo: VehiculoEntity) {
        if self.vehiculoSeleccionado?.vin != vehiculo.vin {
            VehicleSessionManager.shared.setSelectedVehicleVin(vehiculo.vin)
        }
        
        self.vehiculoSeleccionado = vehiculo
        let placa = vehiculo.placa ?? "N/A"
        let marca = vehiculo.marca ?? ""
        let modelo = vehiculo.modelo ?? ""
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lblVehiculoInfo.text = "Vehículo: \(marca) \(modelo) (\(placa))"
            self.lblVehiculoInfo.textColor = WayraTheme.accent
            self.btnSeleccionarVehiculo.setTitle("Cambiar Vehículo", for: .normal)
        }
    }
}
