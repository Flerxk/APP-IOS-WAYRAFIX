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
    private var repositorioVehiculo: RepositorioVehiculoProtocol!
    private var btnEliminar: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        repositorioVehiculo = VehiculoLocalRepository()
        view.backgroundColor = WayraTheme.background
        title = "Detalle del Vehículo"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Editar", style: .plain, target: self, action: #selector(editarVehiculo))
        cargarDatos()
        setupEliminarButton()
    }
    
    private func setupEliminarButton() {
        let boton = UIButton(type: .system)
        boton.translatesAutoresizingMaskIntoConstraints = false
        boton.setTitle("Borrar Vehículo", for: .normal)
        boton.setTitleColor(.systemRed, for: .normal)
        boton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        boton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.08)
        boton.layer.cornerRadius = 14
        boton.layer.borderWidth = 1
        boton.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.2).cgColor
        
        boton.addTarget(self, action: #selector(confirmarEliminacion), for: .touchUpInside)
        
        view.addSubview(boton)
        
        NSLayoutConstraint.activate([
            boton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: boton.trailingAnchor, constant: 24),
            boton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            boton.heightAnchor.constraint(equalToConstant: 54)
        ])
        
        self.btnEliminar = boton
    }
    
    @objc func confirmarEliminacion() {
        let alerta = UIAlertController(
            title: "Confirmar",
            message: "¿Desea borrar la información de su vehículo?",
            preferredStyle: .alert
        )
        
        let eliminar = UIAlertAction(title: "Borrar", style: .destructive) { [weak self] _ in
            self?.eliminarVehiculo()
        }
        
        let cancelar = UIAlertAction(title: "Cancelar", style: .cancel)
        
        alerta.addAction(eliminar)
        alerta.addAction(cancelar)
        
        present(alerta, animated: true)
    }
    
    private func eliminarVehiculo() {
        guard let v = vehiculo else { return }
        do {
            try repositorioVehiculo.eliminarVehiculo(v)
            navigationController?.popViewController(animated: true)
        } catch {
            print("Error al eliminar: \(error)")
        }
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
