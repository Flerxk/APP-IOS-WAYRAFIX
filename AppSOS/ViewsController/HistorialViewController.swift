//
//  HistorialViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
import CoreData
import FirebaseAuth

class HistorialViewController: UIViewController {

    @IBOutlet weak var tblHistorial: UITableView!
    
    var listaServicios: [ServicioEntity] = []
    var listaServiciosCloud: [HistoryItem] = []
    
    let context = ControladorPersistencia.compartido.contextoVista

    override func viewDidLoad() {
        super.viewDidLoad()
        tblHistorial.delegate = self
        tblHistorial.dataSource = self
        
        view.backgroundColor = .clear
        view.aplicarFondoRosadoRadial()
        cargarDatosLocales()
        cargarHistorialCloud()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.ajustarMarcoDeFondoRadial()
    }
    
    func cargarDatosLocales() {
        let solicitud: NSFetchRequest<ServicioEntity> = ServicioEntity.fetchRequest()
        
        do {
            listaServicios = try context.fetch(solicitud)
            tblHistorial.reloadData()
        } catch {
            print("Error al cargar datos locales: \(error)")
        }
    }
    
    func cargarHistorialCloud() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        APIService.shared.obtenerHistorial(uid: uid) { [weak self] resultado in
            guard let self = self else { return }
            switch resultado {
            case .success(let items):
                self.listaServiciosCloud = items
                self.tblHistorial.reloadData()
            case .failure(let error):
                print("Error al cargar historial cloud: \(error.localizedDescription)")
            }
        }
    }
    
    func guardarNuevoServicio(nombre: String) {
        let nuevoServicio = ServicioEntity(context: self.context)
        nuevoServicio.titulo = nombre
        nuevoServicio.fecha = Date()
        nuevoServicio.estado = "En camino"
        
        do {
            try context.save()
            print("Servicio guardado exitosamente")
        } catch {
            print("Error al guardar: \(error)")
        }
    }
    
}

// MARK: - Extensiones
extension HistorialViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listaServiciosCloud.isEmpty ? listaServicios.count : listaServiciosCloud.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: "historialCell", for: indexPath)
        
        if !listaServiciosCloud.isEmpty {
            let servicio = listaServiciosCloud[indexPath.row]
            celda.textLabel?.text = "Ticket: \(servicio.ticket ?? "N/A") - \(servicio.tipoSiniestro ?? "Asistencia")"
            celda.detailTextLabel?.text = "\(servicio.fechaCorta ?? "") - \(servicio.estado?.capitalized ?? "") (\(servicio.vehiculo?.placa ?? ""))"
        } else {
            let servicio = listaServicios[indexPath.row]
            celda.textLabel?.text = servicio.titulo
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            if let fechaReal = servicio.fecha {
                celda.detailTextLabel?.text = "\(formatter.string(from: fechaReal)) - \(servicio.estado ?? "")"
            }
        }
        
        return celda
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let servicioAEliminar = listaServicios[indexPath.row]
            
            context.delete(servicioAEliminar)
            
            do {
                try context.save()
                listaServicios.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                print("Error al borrar: \(error)")
            }
        }
    }
}
