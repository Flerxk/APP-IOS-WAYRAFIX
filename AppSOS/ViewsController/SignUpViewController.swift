//
//  SignUpViewController.swift
//  AppSOS
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet private var camposConBorde: [UIView]?

    @IBAction func volverAtras(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func irIniciarSesion(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let cajas = camposConBorde, !cajas.isEmpty {
            cajas.forEach { $0.layer.borderColor = UIColor.lightGray.cgColor }
        } else {
            aplicarBordeGrisAContenedoresDeCampos(en: view)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func aplicarBordeGrisAContenedoresDeCampos(en root: UIView) {
        for sub in root.subviews {
            if sub.layer.cornerRadius >= 12, sub.layer.borderWidth >= 1,
               sub.subviews.contains(where: { $0 is UIStackView }) {
                sub.layer.borderColor = UIColor.lightGray.cgColor
            }
            aplicarBordeGrisAContenedoresDeCampos(en: sub)
        }
    }
}
