//
//  ViewController.swift
//  FlowerFinderApp
//
//  Created by Ellen Sun on 2019-07-20.
//  Copyright © 2019 Ellen Sun. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaBaseURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController();
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }

    @IBAction func cameraTap(_ sender: Any) {
        //present the camera, and take the picture
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            guard let converted = CIImage(image: pickedImage) else{
                fatalError("Can't convert")
            }
            detect(image: converted);
            image.image = pickedImage
            imagePicker.dismiss(animated: true, completion: nil)
        }
       
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Cannot import")
        }
        
        let request = VNCoreMLRequest(model: model) {(request, error) in
            let classification = request.results?.first as? VNClassificationObservation
            self.navigationItem.title = classification?.identifier.capitalized
            self.requestWiki(flowerName: classification?.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do{
            try handler.perform([request])
        }
        catch{
            print("error")
        }
        
        
    }
    
    func requestWiki(flowerName: String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
        ]
        Alamofire.request(wikipediaBaseURL, method: .get, parameters: parameters).responseJSON { (res) in
            if res.result.isSuccess{
                print("Got info")
                print(res)
                
                let json: JSON = JSON(res.result.value!)
                let pageid = json["query"]["pageid"][0].stringValue
                let flowerDescription = json["query"]["pages"][pageid]["extract"].stringValue
                self.label.text=flowerDescription
                
            }
        }
        
    }
    
}

