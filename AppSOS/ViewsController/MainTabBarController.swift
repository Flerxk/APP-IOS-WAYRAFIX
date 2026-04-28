//
//  MainTabBarController.swift
//  AppSOS
//
//  Created by user286450 on 4/25/26.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarEstilo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurarIconos()
    }
    
    private func configurarIconos() {
        guard let items = tabBar.items else { return }
        
        let iconos = ["house.fill", "car.2.fill", "clock.fill", "person.fill"]
        let titulos = ["Inicio", "Garage", "Historial", "Perfil"]
        
        for (index, item) in items.enumerated() {
            if index < iconos.count {
                item.image = UIImage(systemName: iconos[index])
                item.title = titulos[index]
            }
        }
    }
    
    private func configurarEstilo() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        appearance.stackedLayoutAppearance.selected.iconColor = WayraTheme.brand
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: WayraTheme.brand]
        
        appearance.stackedLayoutAppearance.normal.iconColor = WayraTheme.textSecondary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: WayraTheme.textSecondary]
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.tintColor = WayraTheme.brand
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.05
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -4)
        tabBar.layer.shadowRadius = 12
        tabBar.layer.masksToBounds = false
    }
}