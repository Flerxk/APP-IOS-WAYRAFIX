//
//  HistorialViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 12/04/26.
//

import UIKit
import CoreData

class HistorialViewController: UIViewController {

    @IBOutlet weak var tblHistorial: UITableView!
    
    var listaServicios: [ServicioEntity] = []
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        tblHistorial.delegate = self
        tblHistorial.dataSource = self
        
        cargarDatos()
    }
    
    func cargarDatos() {
        let solicitud: NSFetchRequest<ServicioEntity> = ServicioEntity.fetchRequest()
        
        do {
            listaServicios = try context.fetch(solicitud)
            tblHistorial.reloadData()
        } catch {
            print("Error al cargar datos: \(error)")
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
        return listaServicios.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: "historialCell", for: indexPath)
        let servicio = listaServicios[indexPath.row]
        
        celda.textLabel?.text = servicio.titulo
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let fechaReal = servicio.fecha {
            celda.detailTextLabel?.text = "\(formatter.string(from: fechaReal)) - \(servicio.estado ?? "")"
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
