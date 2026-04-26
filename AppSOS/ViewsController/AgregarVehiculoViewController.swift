//
//  AgregarVehiculoViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
internal import CoreData
import FirebaseAuth

class AgregarVehiculoViewController: UIViewController {

    @IBOutlet weak var scTransmision: UISegmentedControl!
    @IBOutlet weak var txtPlaca: UITextField!
    @IBOutlet weak var txtMarca: UITextField!
    @IBOutlet weak var txtModelo: UITextField!
    @IBOutlet weak var txtAnio: UITextField!
    @IBOutlet weak var txtColor: UITextField!
    @IBOutlet weak var txtVin: UITextField!
    
    @IBOutlet weak var btnTipoVehiculo: UIButton!
    @IBOutlet weak var btnTipoCombustible: UIButton!
    
    @IBOutlet weak var btnGuardar: UIButton!
    
    var vehiculoAEditar: VehiculoEntity?
    
    var tipoVehiculoSeleccionado: String = ""
    var tipoCombustibleSeleccionado: String = ""
        
    let context = ControladorPersistencia.compartido.contextoVista

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ocultarTeclado))
        view.addGestureRecognizer(tap)
        
        styleUI()
        configurarMenuTipoVehiculo()
        configurarMenuTipoCombustible()
        btnGuardar.addTarget(self, action: #selector(btnGuardarTapped(_:)), for: .touchUpInside)
        
        if let vehiculo = vehiculoAEditar {
            title = "Editar Vehículo"
            btnGuardar.configuration?.title = "Actualizar Vehículo"
            txtPlaca.text = vehiculo.placa
            txtMarca.text = vehiculo.marca
            txtModelo.text = vehiculo.modelo
            txtAnio.text = vehiculo.anio == 0 ? nil : "\(vehiculo.anio)"
            txtColor.text = vehiculo.color
            txtVin.text = vehiculo.vin
            tipoVehiculoSeleccionado = vehiculo.tipoVehiculo ?? ""
            tipoCombustibleSeleccionado = vehiculo.tipoCombustible ?? ""
            btnTipoVehiculo.setTitle(tipoVehiculoSeleccionado, for: .normal)
            btnTipoCombustible.setTitle(tipoCombustibleSeleccionado, for: .normal)
            scTransmision.selectedSegmentIndex = (vehiculo.transmision == "Manual") ? 1 : 0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }
    
    func styleUI() {
        view.backgroundColor = .clear
        view.aplicarFondoRosadoRadial()
        title = "Agregar Vehículo"
        btnGuardar.applyPrimaryStyle(title: "Guardar Vehículo")
        // Cambiar a dorado/ocre para seguir el wireframe
        btnGuardar.configuration?.baseBackgroundColor = UIColor(red: 0.77, green: 0.58, blue: 0.30, alpha: 1.0)
        btnGuardar.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btnGuardar.layer.cornerRadius = 26
        btnGuardar.layer.masksToBounds = true
        
        scTransmision.selectedSegmentTintColor = WayraTheme.primary
        scTransmision.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.boldSystemFont(ofSize: 20)], for: .selected)
        scTransmision.setTitleTextAttributes([.foregroundColor: WayraTheme.textPrimary, .font: UIFont.boldSystemFont(ofSize: 20)], for: .normal)
        scTransmision.backgroundColor = .white
        scTransmision.layer.cornerRadius = 28
        scTransmision.layer.borderWidth = 1
        scTransmision.layer.borderColor = WayraTheme.primary.cgColor
        scTransmision.layer.masksToBounds = true
        
        [txtPlaca, txtMarca, txtModelo, txtAnio, txtColor, txtVin].forEach { textField in
            guard let campo = textField else { return }
            
            campo.backgroundColor = .white
            campo.layer.cornerRadius = 16
            campo.layer.borderWidth = 1
            campo.layer.borderColor = WayraTheme.divider.cgColor
            
            campo.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
            campo.leftViewMode = .always
            
            campo.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 10))
            campo.rightViewMode = .unlessEditing
            
            campo.clearButtonMode = .whileEditing
            
            campo.font = .systemFont(ofSize: 18, weight: .medium)
            campo.textColor = WayraTheme.textPrimary
            
            if let textoPlaceholder = campo.placeholder {
                campo.attributedPlaceholder = NSAttributedString(
                    string: textoPlaceholder,
                    attributes: [.foregroundColor: WayraTheme.textSecondary]
                )
            }
        }
        
        [btnTipoVehiculo, btnTipoCombustible].forEach { boton in
            guard let boton = boton else { return }
            let tituloPorDefecto = boton == btnTipoVehiculo ? "Seleccionar Tipo de Vehículo:" : "Seleccionar Tipo de Combustible:"
            let tituloActual = boton.title(for: .normal) ?? ""
            
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = .white
            config.baseForegroundColor = WayraTheme.textPrimary
            config.title = (tituloActual.isEmpty || tituloActual == "Button") ? tituloPorDefecto : tituloActual
            
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 14)
            
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 18, weight: .medium)
                return outgoing
            }
            
            config.background.cornerRadius = 16
            config.background.strokeColor = WayraTheme.divider
            config.background.strokeWidth = 1
            
            boton.configuration = config
            
            boton.contentHorizontalAlignment = .left
        }
    }
        
    @objc func ocultarTeclado() {
        view.endEditing(true)
    }

        func configurarMenuTipoVehiculo() {
            let opciones = ["Sedán", "Hatchback", "SUV", "Pick-up", "Minivan", "Motocicleta"]
            var acciones: [UIAction] = []
            for opcion in opciones {
                let accion = UIAction(title: opcion, image: UIImage(systemName: "car.fill")) { _ in
                    self.tipoVehiculoSeleccionado = opcion
                    self.btnTipoVehiculo.setTitle(opcion, for: .normal)
                }
                acciones.append(accion)
            }
            btnTipoVehiculo.menu = UIMenu(title: "Tipo de Vehículo", children: acciones)
            btnTipoVehiculo.showsMenuAsPrimaryAction = true
        }
        
        func configurarMenuTipoCombustible() {
            let opciones = ["Gasolina 90", "Gasolina 95", "Gasolina 97", "Diésel B5", "GNV", "GLP", "Híbrido", "Eléctrico"]
            var acciones: [UIAction] = []
            for opcion in opciones {
                let accion = UIAction(title: opcion, image: UIImage(systemName: "fuelpump.fill")) { _ in
                    self.tipoCombustibleSeleccionado = opcion
                    self.btnTipoCombustible.setTitle(opcion, for: .normal)
                }
                acciones.append(accion)
            }
            btnTipoCombustible.menu = UIMenu(title: "Combustible", children: acciones)
            btnTipoCombustible.showsMenuAsPrimaryAction = true
        }

    @IBAction func btnGuardarTapped(_ sender: UIButton) {
            guard let placa = txtPlaca.text, !placa.isEmpty,
                  let marca = txtMarca.text, !marca.isEmpty,
                  let modelo = txtModelo.text, !modelo.isEmpty,
                  let anioStr = txtAnio.text, let anio = Int16(anioStr),
                  let color = txtColor.text, !color.isEmpty,
                  let vin = txtVin.text, !vin.isEmpty else {
                mostrarAlerta(titulo: "Campos incompletos", mensaje: "Completa todos los datos del vehículo.")
                return
            }
            
            if tipoVehiculoSeleccionado.isEmpty || tipoCombustibleSeleccionado.isEmpty {
                mostrarAlerta(titulo: "Campos incompletos", mensaje: "Selecciona el tipo de vehículo y combustible.")
                return
            }

            
            let indiceSeleccionado = scTransmision.selectedSegmentIndex
            let transmision = scTransmision.titleForSegment(at: indiceSeleccionado) ?? "No definido"

            let registro = vehiculoAEditar ?? VehiculoEntity(context: self.context)
            registro.placa = placa.uppercased()
            registro.marca = marca
            registro.modelo = modelo
            registro.anio = Int64(anio)
            registro.color = color
            registro.vin = vin.uppercased()
            registro.tipoVehiculo = tipoVehiculoSeleccionado
            registro.tipoCombustible = tipoCombustibleSeleccionado
            registro.transmision = transmision
            
            // Asignar el propietario buscando el UsuarioEntity correspondiente para el Garage
            if let uid = Auth.auth().currentUser?.uid {
                let fetchRequest: NSFetchRequest<UsuarioEntity> = UsuarioEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uid)
                if let usuario = try? context.fetch(fetchRequest).first {
                    registro.propietario = usuario
                }
            }
            
            // Sincronizar con Firestore
            if let uid = Auth.auth().currentUser?.uid {
                let vehiculoData: [String: Any] = [
                    "placa": placa.uppercased(),
                    "marca": marca,
                    "modelo": modelo,
                    "anio": anio,
                    "color": color,
                    "vin": vin.uppercased(),
                    "tipoVehiculo": tipoVehiculoSeleccionado,
                    "tipoCombustible": tipoCombustibleSeleccionado,
                    "transmision": transmision
                ]
                FirebaseManager.shared.guardarVehiculo(uidUsuario: uid, vehiculo: vehiculoData, idVehiculo: vin.uppercased()) { _ in }
            }
            
            do {
                try context.save()
                print("Guardado con éxito: \(transmision)")
                self.navigationController?.popViewController(animated: true)
            } catch {
                print("Error al guardar: \(error)")
            }
    }
    
    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }
}
