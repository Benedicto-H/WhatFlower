//
//  ViewController.swift
//  WhatFlower
//
//  Created by 홍진표 on 1/13/24.
//

import UIKit
import CoreML
import Vision
import SDWebImage

class ViewController: UIViewController {
    
    // MARK: - INTERFACE BUILDER (UI)
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    // MARK: - Properties
    let imagePicker: UIImagePickerController = UIImagePickerController()
    private let wikipediaURl: String = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    // MARK: - IBACTION
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) -> Void {
        
        self.present(imagePicker, animated: true)
    }
    
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let userPickedImage: UIImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
        let convertedCIImage: CIImage = CIImage(image: userPickedImage) else {
            imagePicker.dismiss(animated: true)
            
            fatalError("Couldn't convert UIImage into CIImage.")
        }
        
        detect(image: convertedCIImage)
        
        imagePicker.dismiss(animated: true)
    }
    
    func detect(image: CIImage) -> Void {
        
        guard let model: VNCoreMLModel = try? VNCoreMLModel(for: FlowerClassifier(contentsOf: FlowerClassifier.urlOfModelInThisBundle).model) else { fatalError("Cannot import model.") }
        let request: VNCoreMLRequest = VNCoreMLRequest(model: model) { request, error in
            guard let classification: VNClassificationObservation = request.results?.first as? VNClassificationObservation else { fatalError("Could not classify image.") }
            
            APICaller.shared.performRequest(flowerName: classification.identifier.capitalized) { extract, image in
                guard let extract: String = extract, let image: String = image else { return }
                
                DispatchQueue.main.async {
                    if #available(iOS 15.0, *) {
                        let appearance: UINavigationBarAppearance = UINavigationBarAppearance()
                        
                        self.navigationItem.title = classification.identifier.capitalized
                        self.label.text = extract
                        self.imageView.sd_setImage(with: URL(string: image))
                        
                        appearance.configureWithDefaultBackground()
                        appearance.backgroundColor = .systemBackground
                        UINavigationBar.appearance().standardAppearance = appearance
                        UINavigationBar.appearance().scrollEdgeAppearance = appearance
                    }
                }
            }
        }
        
        let handler: VNImageRequestHandler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
}

