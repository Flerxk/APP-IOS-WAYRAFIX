//
//  ScanVINViewController.swift
//  AppSOS
//
//  Created by Erick Chunga on 20/04/26.
//

import UIKit
import AVFoundation

class ScanVINViewController: UIViewController {

    @IBOutlet weak var vistaCamara: UIView!
    @IBOutlet weak var btnCerrar: UIButton!
    @IBOutlet weak var btnFlash: UIButton!
    @IBOutlet weak var cardInfo: UIView!
    @IBOutlet weak var imgIcono: UIImageView!
    @IBOutlet weak var lblTitulo: UILabel!
    @IBOutlet weak var lblDescripcion: UILabel!
    @IBOutlet weak var btnManual: UIButton!
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isFlashOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = vistaCamara.bounds
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        vistaCamara.backgroundColor = UIColor(white: 0.1, alpha: 1)
        
        btnCerrar.configuration = .plain()
        btnCerrar.configuration?.image = UIImage(systemName: "xmark")
        btnCerrar.configuration?.baseForegroundColor = .white
        btnCerrar.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btnCerrar.layer.cornerRadius = 20
        btnCerrar.clipsToBounds = true
        
        btnFlash.configuration = .plain()
        btnFlash.configuration?.image = UIImage(systemName: "bolt.fill")
        btnFlash.configuration?.baseForegroundColor = .white
        btnFlash.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btnFlash.layer.cornerRadius = 20
        btnFlash.clipsToBounds = true
        
        cardInfo.backgroundColor = .white
        cardInfo.layer.cornerRadius = 24
        cardInfo.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardInfo.layer.shadowColor = UIColor.black.cgColor
        cardInfo.layer.shadowOpacity = 0.15
        cardInfo.layer.shadowOffset = CGSize(width: 0, height: -4)
        cardInfo.layer.shadowRadius = 20
        
        imgIcono.tintColor = WayraTheme.primary
        imgIcono.backgroundColor = WayraTheme.accentSoft
        imgIcono.layer.cornerRadius = imgIcono.frame.width / 2
        imgIcono.clipsToBounds = true
        imgIcono.contentMode = .scaleAspectFit
        
        lblTitulo.text = "Escanear BIM o VIN"
        lblTitulo.font = .boldSystemFont(ofSize: 20)
        lblTitulo.textColor = WayraTheme.textPrimary
        
        lblDescripcion.text = "Alinee el código de barras dentro del recuadro dorado para leerlo automáticamente."
        lblDescripcion.font = .systemFont(ofSize: 15)
        lblDescripcion.textColor = WayraTheme.textSecondary
        lblDescripcion.numberOfLines = 0
        
        btnManual.setTitle("Ingresar manualmente", for: .normal)
        btnManual.setTitleColor(WayraTheme.accent, for: .normal)
        btnManual.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btnManual.addTarget(self, action: #selector(btnManualTapped), for: .touchUpInside)
    }
    
    @objc func btnManualTapped() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "vc-agregar-vehiculo") as? AgregarVehiculoViewController {
            navigationController?.pushViewController(vc, animated: true)
        } else {
            // Fallback en caso de que el ID del storyboard cambie
            dismiss(animated: true) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
                   let tabBarController = window.rootViewController as? UITabBarController {
                    tabBarController.selectedIndex = 1 
                }
            }
        }
    }
    
    @IBAction func btnCerrarTapped(_ sender: UIButton) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func btnFlashTapped(_ sender: UIButton) {
        toggleFlash()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No se encontró cámara trasera")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error al crear input de video: \(error)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("No se pudo agregar input de video")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = vistaCamara.bounds
        previewLayer.videoGravity = .resizeAspectFill
        vistaCamara.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("Dispositivo no tiene flash")
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isFlashOn = false
                btnFlash.configuration?.image = UIImage(systemName: "bolt.fill")
            } else {
                try device.setTorchModeOn(level: 1.0)
                isFlashOn = true
                btnFlash.configuration?.image = UIImage(systemName: "bolt.slash.fill")
            }
            device.unlockForConfiguration()
        } catch {
            print("Error al toggle flash: \(error)")
        }
    }
}
