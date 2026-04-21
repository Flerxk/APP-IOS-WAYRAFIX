//
//  DetalleVehiculoViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit

class DetalleVehiculoViewController: UIViewController {

    @IBOutlet weak var lblPlaca: UILabel!
    @IBOutlet weak var lblMarcaModeloAnio: UILabel!
    @IBOutlet weak var lblColor: UILabel!
    @IBOutlet weak var lblVin: UILabel!
    @IBOutlet weak var lblTipoVehiculo: UILabel!
    @IBOutlet weak var lblCombustible: UILabel!
    @IBOutlet weak var lblTransmision: UILabel!
    
    var vehiculo: VehiculoEntity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WayraTheme.background
        title = "Vehicle Detail"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Editar", style: .plain, target: self, action: #selector(editarVehiculo))
        cargarDatos()
    }
    
    func cargarDatos() {
        lblPlaca.text = vehiculo?.placa ?? "Sin placa"
        lblMarcaModeloAnio.text = "\(vehiculo?.marca ?? "-") \(vehiculo?.modelo ?? "-") • \(vehiculo?.anio ?? 0)"
        lblColor.text = "Color: \(vehiculo?.color ?? "-")"
        lblVin.text = "VIN: \(vehiculo?.vin ?? "-")"
        lblTipoVehiculo.text = "Tipo: \(vehiculo?.tipoVehiculo ?? "-")"
        lblCombustible.text = "Combustible: \(vehiculo?.tipoCombustible ?? "-")"
        lblTransmision.text = "Transmisión: \(vehiculo?.transmision ?? "-")"
    }
    
    @objc func editarVehiculo() {
        performSegue(withIdentifier: "editarVehiculoSegue", sender: vehiculo)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editarVehiculoSegue",
           let destino = segue.destination as? AgregarVehiculoViewController,
           let vehiculo = sender as? VehiculoEntity {
            destino.vehiculoAEditar = vehiculo
        }
    }
}
