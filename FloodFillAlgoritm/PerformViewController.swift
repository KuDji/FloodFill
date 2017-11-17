//
//  ViewController.swift
//  FloodFillAlgoritm
//
//  Created by Анатолий on 15.11.2017.
//  Copyright © 2017 Анатолий. All rights reserved.
//

import UIKit

class PerformViewController: UIViewController {
    
    @IBOutlet weak var repaintingImage: FloodImage!
    
    var imageSet = UIImage(named: "Hexagon")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        repaintingImage.originImage = imageSet 
        repaintingImage.isUserInteractionEnabled = true
    }
}
