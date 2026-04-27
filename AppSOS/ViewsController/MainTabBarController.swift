//
//  MainTabBarController.swift
//  AppSOS
//
//  Created by Gemini Code Assist.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarEstilo()
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