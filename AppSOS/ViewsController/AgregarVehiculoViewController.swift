//
//  AgregarVehiculoViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
internal import CoreData

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
        
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

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
        btnGuardar.applyAccentStyle(title: "Guardar Vehículo")
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
        
        [txtPlaca, txtMarca, txtModelo, txtAnio, txtColor, txtVin].forEach {
            $0?.backgroundColor = .white
            $0?.layer.cornerRadius = 16
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = WayraTheme.divider.cgColor
            $0?.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 10))
            $0?.leftViewMode = .always
            $0?.font = .systemFont(ofSize: 18, weight: .medium)
            $0?.textColor = WayraTheme.textPrimary
            $0?.attributedPlaceholder = NSAttributedString(
                string: $0?.placeholder ?? "",
                attributes: [.foregroundColor: WayraTheme.textSecondary]
            )
        }
        
        [btnTipoVehiculo, btnTipoCombustible].forEach {
            $0?.backgroundColor = .white
            $0?.layer.cornerRadius = 16
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = WayraTheme.divider.cgColor
            $0?.setTitleColor(WayraTheme.textPrimary, for: .normal)
            $0?.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            $0?.contentHorizontalAlignment = .left
            $0?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 14)
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
