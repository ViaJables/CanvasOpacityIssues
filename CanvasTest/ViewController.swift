//
//  ViewController.swift
//  CanvasTest
//
//  Created by John Brunsfeld on 6/29/20.
//  Copyright © 2020 John Brunsfeld. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var brushes: [Brush] = []
    @IBOutlet weak var canvas: Canvas!
    @IBOutlet weak var opacitySlider: UISlider!
    
    private func registerBrush(with imageName: String) throws -> Brush {
        let texture = try canvas.makeTexture(with: UIImage(named: imageName)!.pngData()!)
        return try canvas.registerBrush(name: imageName, textureID: texture.id)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        print("ViewController:viewDidLoad")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // note: calling canvas.setup before this point will create the canvas at the size defined in the storyboard
        canvas.setup()
        // Other Setup
        registerBrushes()
    }
    
    func registerBrushes() {
        do {
            let pencil = try registerBrush(with: "Pencil")
            pencil.rotation = .random
            pencil.pointSize = 256
            pencil.pointStep = 2
            pencil.forceSensitive = 1
            pencil.opacity = 1
            pencil.use()
            
//            let brush = try registerBrush(with: "Brush")
//            brush.rotation = .ahead
//            brush.pointSize = 150
//            brush.pointStep = 2
//            brush.forceSensitive = 1
//            brush.color = .black
//            brush.opacity = 1.0
//            brush.forceOnTap = 0.5
//            brush.use()

        } catch MLError.simulatorUnsupported {
            // No simulator support
        } catch {
            // Other errors
        }
        
    }
    
    @IBAction func opacityChanged(_ sender: Any) {
        
        canvas.currentBrush.opacity = CGFloat(opacitySlider.value/100.0)
    }
    
    @IBAction func blueTapped(_ sender: Any) {
        canvas.currentBrush.color = UIColor.init(hexString: "007aff")
    }
    
    @IBAction func yellowTapped(_ sender: Any) {
        canvas.currentBrush.color = UIColor.init(hexString: "ffcc00")
    }
    
    @IBAction func blackTapped(_ sender: Any) {
        canvas.currentBrush.color = .black
    }
    
}

