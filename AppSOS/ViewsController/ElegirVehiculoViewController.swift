//
//  ElegirVehiculoViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 16/04/26.
//

import UIKit
import CoreData
import FirebaseAuth


class ElegirVehiculoViewController: UIViewController {

    @IBOutlet weak var tblVehiculos: UITableView!
    
    var listaVehiculos: [VehiculoEntity] = []
    let context = ControladorPersistencia.compartido.contextoVista
    
    weak var delegado: SeleccionVehiculoDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = WayraTheme.background
        title = "Selecciona vehículo"
        tblVehiculos.delegate = self
        tblVehiculos.dataSource = self
        tblVehiculos.backgroundColor = .clear
        tblVehiculos.separatorStyle = .none
        cargarVehiculos()
    }
    
    func cargarVehiculos() {
        let solicitud: NSFetchRequest<VehiculoEntity> = VehiculoEntity.fetchRequest()
        if let uid = Auth.auth().currentUser?.uid {
            solicitud.predicate = NSPredicate(format: "propietario.id == %@ AND is_active == true", uid)
        }
        do {
            listaVehiculos = try context.fetch(solicitud)
            tblVehiculos.reloadData()
        } catch {
            print("Error al cargar autos: \(error)")
        }
    }
}

extension ElegirVehiculoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listaVehiculos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: "autoSosCell", for: indexPath)
        let auto = listaVehiculos[indexPath.row]
        
        celda.backgroundColor = .clear
        celda.selectionStyle = .none
        var config = celda.defaultContentConfiguration()
        config.text = auto.placa
        config.secondaryText = "\(auto.marca ?? "") \(auto.modelo ?? "")"
        config.textProperties.font = .boldSystemFont(ofSize: 18)
        config.secondaryTextProperties.color = WayraTheme.textSecondary
        config.image = UIImage(systemName: "car.circle.fill")
        config.imageProperties.tintColor = WayraTheme.accent
        celda.contentConfiguration = config
        celda.layer.cornerRadius = 18
        celda.layer.masksToBounds = true
        
        return celda
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        82
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let autoElegido = listaVehiculos[indexPath.row]
        
        delegado?.vehiculoElegidoParaSOS(autoElegido)
        
        dismiss(animated: true, completion: nil)
    }
}
