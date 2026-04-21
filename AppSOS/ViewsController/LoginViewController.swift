//
//  LoginViewController.swift
//  AppSOS
//
//  Created by user286450 on 4/19/26.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var VistaEmail: UIView!
    @IBOutlet weak var VistaPassword: UIView!
    
    override func viewDidLoad() {
        VistaEmail.layer.borderColor = UIColor.lightGray.cgColor
        VistaPassword.layer.borderColor = UIColor.lightGray.cgColor
        
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
