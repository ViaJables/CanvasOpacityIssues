//
//  UIView+Gradient.swift
//  InkWell
//
//  Created by John Brunsfeld on 6/26/20.
//  Copyright © 2020 John Brunsfeld. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addGradientBackground(firstColor: UIColor, secondColor: UIColor){
        clipsToBounds = true
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [firstColor.cgColor, secondColor.cgColor]
        gradientLayer.frame = self.bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        print(gradientLayer.frame)
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
}
