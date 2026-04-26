//
//  HomeViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 9/04/26.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import FirebaseAuth

protocol SeleccionVehiculoDelegate: AnyObject {
    func vehiculoElegidoParaSOS(_ vehiculo: VehiculoEntity)
}

class HomeViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        setupUI()
        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
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
        btnSOS.layer.cornerRadius = 55
        btnSOS.layer.borderWidth = 8
        btnSOS.layer.borderColor = WayraTheme.brandSoft.cgColor
        btnSOS.clipsToBounds = true
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
        bottomPanel.addSubview(btnSeleccionarVehiculo)
        bottomPanel.addSubview(lblVehiculoInfo)
        
        btnSeleccionarVehiculo.addTarget(self, action: #selector(btnSeleccionarVehiculoTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            btnSeleccionarVehiculo.bottomAnchor.constraint(equalTo: btnSOS.topAnchor, constant: -16),
            btnSeleccionarVehiculo.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            btnSeleccionarVehiculo.widthAnchor.constraint(equalToConstant: 200),
            btnSeleccionarVehiculo.heightAnchor.constraint(equalToConstant: 40),
            
            lblVehiculoInfo.bottomAnchor.constraint(equalTo: btnSeleccionarVehiculo.topAnchor, constant: -8),
            lblVehiculoInfo.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            lblVehiculoInfo.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20)
        ])
    }
    
    @objc func btnSeleccionarVehiculoTapped() {
        performSegue(withIdentifier: "mostrarElegirVehiculo", sender: nil)
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
            }
            
            if let label = vista.subviews.compactMap({ $0 as? UILabel }).first {
                label.textColor = seleccionado ? WayraTheme.textPrimary : WayraTheme.textSecondary
                label.font = seleccionado ? .boldSystemFont(ofSize: 14) : .systemFont(ofSize: 14, weight: .medium)
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
        mapView.showsUserLocation = true
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
        
        let region = MKCoordinateRegion(
            center: ubicacion.coordinate,
            latitudinalMeters: 700,
            longitudinalMeters: 700
        )
        mapView.setRegion(region, animated: true)
        
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
            performSegue(withIdentifier: "mostrarElegirVehiculo", sender: nil)
            return
        }
        
        presentarOverlayDestino(para: vehiculo)
    }
    
    private func prepararYEnviarSOS(vehiculo: VehiculoEntity) {
        guard let usuarioFirebase = Auth.auth().currentUser else { return }
        let tipoSiniestro = obtenerNombreCategoriaSeleccionada()
        
        guard let ubicacion = locationManager.location else {
            mostrarAlertaValidacion(mensaje: "No se pudo obtener tu ubicación actual.")
            return
        }
        
        let requestPayload = SOSRequest(
            uid_usuario: usuarioFirebase.uid,
            nombre_cliente: usuarioFirebase.displayName ?? usuarioFirebase.email ?? "Usuario",
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
        APIService.shared.crearAsistencia(payload: payload) { [weak self] resultado in
            guard let self = self else { return }
            
            switch resultado {
            case .success(let respuesta):
                self.presentarOverlayExito(para: vehiculo, sosResponse: respuesta)
            case .failure(let error):
                print("Error enviando SOS: \(error.localizedDescription)")
                self.mostrarAlertaValidacion(mensaje: "No se pudo conectar con el servidor.")
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
    
    func presentarOverlayDestino(para vehiculo: VehiculoEntity) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "SOSDestinoVC") as? SOSDestinoViewController else { return }
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        
        vc.onSolicitarTapped = { [weak self] in
            self?.prepararYEnviarSOS(vehiculo: vehiculo)
        }
        
        present(vc, animated: true)
    }
    
    func presentarOverlayExito(para vehiculo: VehiculoEntity, sosResponse: SOSResponse? = nil) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "SOSExitoVC") as? SOSExitoViewController else { return }
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        
        vc.onSeguimientoTapped = { [weak self] in
            let contexto: [String: Any?] = ["vehiculo": vehiculo, "sos": sosResponse]
            self?.performSegue(withIdentifier: "irARastreo", sender: contexto)
        }
        
        present(vc, animated: true)
    }
}

extension HomeViewController: SeleccionVehiculoDelegate {
    func vehiculoElegidoParaSOS(_ vehiculo: VehiculoEntity) {
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

// MARK: - Clases Integradas para evitar errores de Scope en Xcode
class SOSDestinoViewController: UIViewController {
    @IBOutlet weak var tarjetaDestino: UIView!
    @IBOutlet weak var btnSolicitarAyuda: UIButton!
    @IBOutlet weak var btnCancelar: UIButton!
    
    var onSolicitarTapped: (() -> Void)?
    var onCancelarTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        tarjetaDestino?.applyCardStyle(radius: 30, shadow: true)
        btnSolicitarAyuda?.applyPrimaryStyle(title: "Solicitar Ayuda Ahora")
        btnCancelar?.setTitle("Cancelar", for: .normal)
        btnCancelar?.setTitleColor(WayraTheme.textPrimary, for: .normal)
    }
    
    @IBAction func btnSolicitarTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onSolicitarTapped?()
        }
    }
    
    @IBAction func btnCancelarTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onCancelarTapped?()
        }
    }
}

class SOSExitoViewController: UIViewController {
    @IBOutlet weak var tarjetaExito: UIView!
    @IBOutlet weak var btnVerSeguimiento: UIButton!
    @IBOutlet weak var btnCerrar: UIButton!
    
    var onSeguimientoTapped: (() -> Void)?
    var onCerrarTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        tarjetaExito?.applyCardStyle(radius: 30, shadow: true)
        btnVerSeguimiento?.applyPrimaryStyle(title: "Ver Seguimiento")
        btnCerrar?.setTitle("Cerrar", for: .normal)
        btnCerrar?.setTitleColor(WayraTheme.textPrimary, for: .normal)
    }
    
    @IBAction func btnSeguimientoTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onSeguimientoTapped?()
        }
    }
    
    @IBAction func btnCerrarTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.onCerrarTapped?()
        }
    }
}
