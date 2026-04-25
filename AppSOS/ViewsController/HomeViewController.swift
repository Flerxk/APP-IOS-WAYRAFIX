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
    private let geocoder = CLGeocoder()
    private var vehiculoSeleccionado: VehiculoEntity?
    private var ultimaUbicacionGeocodificada: CLLocation?
    private var direccionActual: String = "Selecciona tu ubicación actual"
    private weak var vistaOverlayActiva: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        setupUI()
        // Forzar consistencia de fuentes y colores en toda la jerarquía
        BuscadorDeElementosGraficos.rastrearYAplicarEstilos(en: view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }

    func setupUI() {
        view.backgroundColor = .clear // Limpiar el color sólido previo
        view.aplicarFondoRosadoRadial() // Fondo radial estándar
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
        
        // Botón SOS: estilo de marca rojo/naranja (= "Registrarme")
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

        styleCategorias()
        styleTopActionButton()
    }

    func styleCategorias() {
        guard let stack = catScrollView.subviews.first(where: { $0 is UIStackView }) as? UIStackView else { return }
        for (indice, vista) in stack.arrangedSubviews.enumerated() {
            vista.layer.cornerRadius = 18
            vista.layer.masksToBounds = true
            // Primera categoría seleccionada usa el color suave de marca; el resto blanco
            vista.backgroundColor = indice == 0 ? WayraTheme.brandSoft : .white
            if let img = vista.subviews.compactMap({ $0 as? UIImageView }).first {
                // Íconos (llanta, batería, herramientas) con el color del botón SOS
                img.tintColor = WayraTheme.brand
            }
        }
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
        
        ultimaUbicacionGeocodificada = ubicacion
        geocoder.reverseGeocodeLocation(ubicacion) { [weak self] placemarks, _ in
            guard let self else { return }
            guard let lugar = placemarks?.first else { return }
            
            let calle = lugar.thoroughfare ?? lugar.name ?? "Ubicación actual"
            let numero = lugar.subThoroughfare ?? ""
            let distrito = lugar.locality ?? lugar.subAdministrativeArea ?? ""
            let direccion = [calle + (numero.isEmpty ? "" : " \(numero)"), distrito]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            
            let texto = direccion.isEmpty ? "Ubicación actual" : direccion
            self.direccionActual = texto
            DispatchQueue.main.async {
                self.lblDireccionActual.text = texto
            }
        }
    }
    
    @objc func manejarPresionadoSOS(_ gesto: UILongPressGestureRecognizer) {
        if gesto.state == .began {
            btnSOSTapped(btnSOS)
        }
    }
    
    @IBAction func btnSOSTapped(_ sender: UIButton) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let conteo = try context.count(for: VehiculoEntity.fetchRequest())
            if conteo == 0 {
                // Sin vehículos → redirigir automáticamente a "Mi Garage" (Tab 1)
                if let tabBarController = self.tabBarController {
                    tabBarController.selectedIndex = 1
                } else {
                    // Fallback: segue directo a Agregar Vehículo
                    performSegue(withIdentifier: "mostrarAgregarVehiculo", sender: nil)
                }
            } else {
                performSegue(withIdentifier: "mostrarElegirVehiculo", sender: nil)
            }
        } catch {
            print("Error: \(error)")
        }
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mostrarElegirVehiculo",
           let destino = segue.destination as? ElegirVehiculoViewController {
            destino.delegado = self
        } else if segue.identifier == "irARastreo",
                  let destino = segue.destination as? RastreoViewController,
                  let vehiculoElegido = sender as? VehiculoEntity {
            destino.vehiculoAveriado = vehiculoElegido
            destino.direccionServicio = direccionActual
        }
    }
    
    func presentarOverlayDestino(para vehiculo: VehiculoEntity) {
        removerOverlayActivo()
        
        let fondoOscuro = UIView(frame: view.bounds)
        fondoOscuro.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        fondoOscuro.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let tarjeta = UIView()
        tarjeta.translatesAutoresizingMaskIntoConstraints = false
        tarjeta.applyCardStyle(radius: 30, shadow: true)
        
        let contenedorIcono = UIView()
        contenedorIcono.translatesAutoresizingMaskIntoConstraints = false
        contenedorIcono.backgroundColor = WayraTheme.accentSoft
        contenedorIcono.layer.cornerRadius = 28
        
        let icono = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        icono.translatesAutoresizingMaskIntoConstraints = false
        icono.tintColor = WayraTheme.accent
        icono.contentMode = .scaleAspectFit
        
        let etiquetaTitulo = UILabel()
        etiquetaTitulo.translatesAutoresizingMaskIntoConstraints = false
        etiquetaTitulo.text = "Confirmar Asistencia"
        etiquetaTitulo.font = .boldSystemFont(ofSize: 17)
        etiquetaTitulo.textAlignment = .center
        
        let etiquetaPregunta = UILabel()
        etiquetaPregunta.translatesAutoresizingMaskIntoConstraints = false
        etiquetaPregunta.text = "¿A dónde llevamos tu vehículo?"
        etiquetaPregunta.font = .boldSystemFont(ofSize: 24)
        etiquetaPregunta.textAlignment = .center
        etiquetaPregunta.numberOfLines = 0
        
        let etiquetaSubtitulo = UILabel()
        etiquetaSubtitulo.translatesAutoresizingMaskIntoConstraints = false
        etiquetaSubtitulo.text = "Selecciona el destino para continuar con tu solicitud de ayuda."
        etiquetaSubtitulo.font = .systemFont(ofSize: 17)
        etiquetaSubtitulo.textColor = WayraTheme.textSecondary
        etiquetaSubtitulo.textAlignment = .center
        etiquetaSubtitulo.numberOfLines = 0
        
        let botonTallerSugerido = crearBotonOpcion(titulo: "Taller Sugerido", subtitulo: "Mecánica Express • 2.5 km", icono: "wrench.and.screwdriver", seleccionado: true)
        let botonDomicilio = crearBotonOpcion(titulo: "Mi Domicilio", subtitulo: "Calle Las Flores 123", icono: "house")
        let botonMapa = crearBotonOpcion(titulo: "Elegir punto en el mapa", subtitulo: "Selecciona una ubicación personalizada", icono: "mappin.and.ellipse")
        
        let botonSolicitar = UIButton(type: .system)
        botonSolicitar.translatesAutoresizingMaskIntoConstraints = false
        botonSolicitar.applyPrimaryStyle(title: "Solicitar Ayuda Ahora")
        botonSolicitar.addAction(UIAction { [weak self] _ in
            self?.vehiculoSeleccionado = vehiculo
            self?.presentarOverlayExito(para: vehiculo)
        }, for: .touchUpInside)
        
        let botonCancelar = UIButton(type: .system)
        botonCancelar.translatesAutoresizingMaskIntoConstraints = false
        botonCancelar.setTitle("Cancelar", for: .normal)
        botonCancelar.setTitleColor(WayraTheme.textPrimary, for: .normal)
        botonCancelar.titleLabel?.font = .boldSystemFont(ofSize: 16)
        botonCancelar.addAction(UIAction { [weak self] _ in
            self?.removerOverlayActivo()
        }, for: .touchUpInside)
        
        view.addSubview(fondoOscuro)
        fondoOscuro.addSubview(tarjeta)
        tarjeta.addSubview(contenedorIcono)
        contenedorIcono.addSubview(icono)
        [etiquetaTitulo, etiquetaPregunta, etiquetaSubtitulo, botonTallerSugerido, botonDomicilio, botonMapa, botonSolicitar, botonCancelar].forEach { tarjeta.addSubview($0) }
        
        NSLayoutConstraint.activate([
            tarjeta.centerYAnchor.constraint(equalTo: fondoOscuro.centerYAnchor),
            tarjeta.leadingAnchor.constraint(equalTo: fondoOscuro.leadingAnchor, constant: 22),
            fondoOscuro.trailingAnchor.constraint(equalTo: tarjeta.trailingAnchor, constant: 22),
            
            contenedorIcono.topAnchor.constraint(equalTo: tarjeta.topAnchor, constant: 26),
            contenedorIcono.centerXAnchor.constraint(equalTo: tarjeta.centerXAnchor),
            contenedorIcono.widthAnchor.constraint(equalToConstant: 56),
            contenedorIcono.heightAnchor.constraint(equalToConstant: 56),
            
            icono.centerXAnchor.constraint(equalTo: contenedorIcono.centerXAnchor),
            icono.centerYAnchor.constraint(equalTo: contenedorIcono.centerYAnchor),
            icono.widthAnchor.constraint(equalToConstant: 26),
            icono.heightAnchor.constraint(equalToConstant: 26),
            
            etiquetaTitulo.topAnchor.constraint(equalTo: contenedorIcono.bottomAnchor, constant: 18),
            etiquetaTitulo.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 24),
            tarjeta.trailingAnchor.constraint(equalTo: etiquetaTitulo.trailingAnchor, constant: 24),
            
            etiquetaPregunta.topAnchor.constraint(equalTo: etiquetaTitulo.bottomAnchor, constant: 10),
            etiquetaPregunta.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 24),
            tarjeta.trailingAnchor.constraint(equalTo: etiquetaPregunta.trailingAnchor, constant: 24),
            
            etiquetaSubtitulo.topAnchor.constraint(equalTo: etiquetaPregunta.bottomAnchor, constant: 10),
            etiquetaSubtitulo.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 24),
            tarjeta.trailingAnchor.constraint(equalTo: etiquetaSubtitulo.trailingAnchor, constant: 24),
            
            botonTallerSugerido.topAnchor.constraint(equalTo: etiquetaSubtitulo.bottomAnchor, constant: 24),
            botonTallerSugerido.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 18),
            tarjeta.trailingAnchor.constraint(equalTo: botonTallerSugerido.trailingAnchor, constant: 18),
            
            botonDomicilio.topAnchor.constraint(equalTo: botonTallerSugerido.bottomAnchor, constant: 14),
            botonDomicilio.leadingAnchor.constraint(equalTo: botonTallerSugerido.leadingAnchor),
            botonDomicilio.trailingAnchor.constraint(equalTo: botonTallerSugerido.trailingAnchor),
            
            botonMapa.topAnchor.constraint(equalTo: botonDomicilio.bottomAnchor, constant: 14),
            botonMapa.leadingAnchor.constraint(equalTo: botonTallerSugerido.leadingAnchor),
            botonMapa.trailingAnchor.constraint(equalTo: botonTallerSugerido.trailingAnchor),
            
            botonSolicitar.topAnchor.constraint(equalTo: botonMapa.bottomAnchor, constant: 24),
            botonSolicitar.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 18),
            tarjeta.trailingAnchor.constraint(equalTo: botonSolicitar.trailingAnchor, constant: 18),
            botonSolicitar.heightAnchor.constraint(equalToConstant: 52),
            
            botonCancelar.topAnchor.constraint(equalTo: botonSolicitar.bottomAnchor, constant: 16),
            botonCancelar.centerXAnchor.constraint(equalTo: tarjeta.centerXAnchor),
            botonCancelar.bottomAnchor.constraint(equalTo: tarjeta.bottomAnchor, constant: -22)
        ])
        
        vistaOverlayActiva = fondoOscuro
    }
    
    func presentarOverlayExito(para vehiculo: VehiculoEntity) {
        removerOverlayActivo()
        
        let fondoOscuro = UIView(frame: view.bounds)
        fondoOscuro.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        fondoOscuro.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let tarjeta = UIView()
        tarjeta.translatesAutoresizingMaskIntoConstraints = false
        tarjeta.applyCardStyle(radius: 30, shadow: true)
        
        let contenedorIcono = UIView()
        contenedorIcono.translatesAutoresizingMaskIntoConstraints = false
        contenedorIcono.backgroundColor = WayraTheme.accentSoft
        contenedorIcono.layer.cornerRadius = 28
        
        let icono = UIImageView(image: UIImage(systemName: "checkmark.circle"))
        icono.translatesAutoresizingMaskIntoConstraints = false
        icono.tintColor = WayraTheme.accent
        
        let etiquetaTitulo = UILabel()
        etiquetaTitulo.translatesAutoresizingMaskIntoConstraints = false
        etiquetaTitulo.text = "¡Ayuda en Camino!"
        etiquetaTitulo.font = .boldSystemFont(ofSize: 28)
        etiquetaTitulo.textAlignment = .center
        
        let etiquetaSubtitulo = UILabel()
        etiquetaSubtitulo.translatesAutoresizingMaskIntoConstraints = false
        etiquetaSubtitulo.text = "Hemos recibido tu solicitud exitosamente. Una unidad de asistencia ha sido asignada y se dirige a tu ubicación."
        etiquetaSubtitulo.font = .systemFont(ofSize: 18)
        etiquetaSubtitulo.textColor = WayraTheme.textSecondary
        etiquetaSubtitulo.textAlignment = .center
        etiquetaSubtitulo.numberOfLines = 0
        
        let botonSeguimiento = UIButton(type: .system)
        botonSeguimiento.translatesAutoresizingMaskIntoConstraints = false
        botonSeguimiento.applyPrimaryStyle(title: "Ver Seguimiento")
        botonSeguimiento.addAction(UIAction { [weak self] _ in
            self?.removerOverlayActivo()
            self?.performSegue(withIdentifier: "irARastreo", sender: vehiculo)
        }, for: .touchUpInside)
        
        let botonCerrar = UIButton(type: .system)
        botonCerrar.translatesAutoresizingMaskIntoConstraints = false
        botonCerrar.setTitle("Cerrar", for: .normal)
        botonCerrar.setTitleColor(WayraTheme.textPrimary, for: .normal)
        botonCerrar.titleLabel?.font = .boldSystemFont(ofSize: 16)
        botonCerrar.addAction(UIAction { [weak self] _ in
            self?.removerOverlayActivo()
        }, for: .touchUpInside)
        
        view.addSubview(fondoOscuro)
        fondoOscuro.addSubview(tarjeta)
        tarjeta.addSubview(contenedorIcono)
        contenedorIcono.addSubview(icono)
        [etiquetaTitulo, etiquetaSubtitulo, botonSeguimiento, botonCerrar].forEach { tarjeta.addSubview($0) }
        
        NSLayoutConstraint.activate([
            tarjeta.centerYAnchor.constraint(equalTo: fondoOscuro.centerYAnchor),
            tarjeta.leadingAnchor.constraint(equalTo: fondoOscuro.leadingAnchor, constant: 22),
            fondoOscuro.trailingAnchor.constraint(equalTo: tarjeta.trailingAnchor, constant: 22),
            
            contenedorIcono.topAnchor.constraint(equalTo: tarjeta.topAnchor, constant: 28),
            contenedorIcono.centerXAnchor.constraint(equalTo: tarjeta.centerXAnchor),
            contenedorIcono.widthAnchor.constraint(equalToConstant: 56),
            contenedorIcono.heightAnchor.constraint(equalToConstant: 56),
            
            icono.centerXAnchor.constraint(equalTo: contenedorIcono.centerXAnchor),
            icono.centerYAnchor.constraint(equalTo: contenedorIcono.centerYAnchor),
            icono.widthAnchor.constraint(equalToConstant: 28),
            icono.heightAnchor.constraint(equalToConstant: 28),
            
            etiquetaTitulo.topAnchor.constraint(equalTo: contenedorIcono.bottomAnchor, constant: 18),
            etiquetaTitulo.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 24),
            tarjeta.trailingAnchor.constraint(equalTo: etiquetaTitulo.trailingAnchor, constant: 24),
            
            etiquetaSubtitulo.topAnchor.constraint(equalTo: etiquetaTitulo.bottomAnchor, constant: 16),
            etiquetaSubtitulo.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 24),
            tarjeta.trailingAnchor.constraint(equalTo: etiquetaSubtitulo.trailingAnchor, constant: 24),
            
            botonSeguimiento.topAnchor.constraint(equalTo: etiquetaSubtitulo.bottomAnchor, constant: 28),
            botonSeguimiento.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 20),
            tarjeta.trailingAnchor.constraint(equalTo: botonSeguimiento.trailingAnchor, constant: 20),
            botonSeguimiento.heightAnchor.constraint(equalToConstant: 54),
            
            botonCerrar.topAnchor.constraint(equalTo: botonSeguimiento.bottomAnchor, constant: 16),
            botonCerrar.centerXAnchor.constraint(equalTo: tarjeta.centerXAnchor),
            botonCerrar.bottomAnchor.constraint(equalTo: tarjeta.bottomAnchor, constant: -22)
        ])
        
        vistaOverlayActiva = fondoOscuro
    }
    
    func crearBotonOpcion(titulo: String, subtitulo: String, icono: String, seleccionado: Bool = false) -> UIView {
        let contenedor = UIView()
        contenedor.translatesAutoresizingMaskIntoConstraints = false
        contenedor.backgroundColor = seleccionado ? WayraTheme.accentSoft : UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
        contenedor.layer.cornerRadius = 18
        
        let contenedorIcono = UIView()
        contenedorIcono.translatesAutoresizingMaskIntoConstraints = false
        contenedorIcono.backgroundColor = .white
        contenedorIcono.layer.cornerRadius = 18
        
        let imagenIcono = UIImageView(image: UIImage(systemName: icono))
        imagenIcono.translatesAutoresizingMaskIntoConstraints = false
        imagenIcono.tintColor = WayraTheme.primary
        
        let etiquetaTitulo = UILabel()
        etiquetaTitulo.translatesAutoresizingMaskIntoConstraints = false
        etiquetaTitulo.text = titulo
        etiquetaTitulo.font = .boldSystemFont(ofSize: 18)
        
        let etiquetaSubtitulo = UILabel()
        etiquetaSubtitulo.translatesAutoresizingMaskIntoConstraints = false
        etiquetaSubtitulo.text = subtitulo
        etiquetaSubtitulo.font = .systemFont(ofSize: 15)
        etiquetaSubtitulo.textColor = WayraTheme.textSecondary
        
        contenedor.addSubview(contenedorIcono)
        contenedorIcono.addSubview(imagenIcono)
        contenedor.addSubview(etiquetaTitulo)
        contenedor.addSubview(etiquetaSubtitulo)
        
        if seleccionado {
            let iconoCheck = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            iconoCheck.translatesAutoresizingMaskIntoConstraints = false
            iconoCheck.tintColor = WayraTheme.accent
            contenedor.addSubview(iconoCheck)
            NSLayoutConstraint.activate([
                iconoCheck.centerYAnchor.constraint(equalTo: contenedor.centerYAnchor),
                contenedor.trailingAnchor.constraint(equalTo: iconoCheck.trailingAnchor, constant: 16),
                iconoCheck.widthAnchor.constraint(equalToConstant: 22),
                iconoCheck.heightAnchor.constraint(equalToConstant: 22)
            ])
        }
        
        NSLayoutConstraint.activate([
            contenedor.heightAnchor.constraint(equalToConstant: 78),
            contenedorIcono.leadingAnchor.constraint(equalTo: contenedor.leadingAnchor, constant: 14),
            contenedorIcono.centerYAnchor.constraint(equalTo: contenedor.centerYAnchor),
            contenedorIcono.widthAnchor.constraint(equalToConstant: 36),
            contenedorIcono.heightAnchor.constraint(equalToConstant: 36),
            
            imagenIcono.centerXAnchor.constraint(equalTo: contenedorIcono.centerXAnchor),
            imagenIcono.centerYAnchor.constraint(equalTo: contenedorIcono.centerYAnchor),
            
            etiquetaTitulo.topAnchor.constraint(equalTo: contenedor.topAnchor, constant: 16),
            etiquetaTitulo.leadingAnchor.constraint(equalTo: contenedorIcono.trailingAnchor, constant: 14),
            
            etiquetaSubtitulo.topAnchor.constraint(equalTo: etiquetaTitulo.bottomAnchor, constant: 4),
            etiquetaSubtitulo.leadingAnchor.constraint(equalTo: etiquetaTitulo.leadingAnchor)
        ])
        
        return contenedor
    }
    
    func removerOverlayActivo() {
        vistaOverlayActiva?.removeFromSuperview()
        vistaOverlayActiva = nil
    }
}

extension HomeViewController: SeleccionVehiculoDelegate {
    func vehiculoElegidoParaSOS(_ vehiculo: VehiculoEntity) {
        let placa = vehiculo.placa ?? ""
        print("Preparando rescate para: \(placa)")
        presentarOverlayDestino(para: vehiculo)
    }
}
