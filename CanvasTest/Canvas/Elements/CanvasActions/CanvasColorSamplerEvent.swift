//
//  Chartlet.swift
//  MaLiang
//
//  Created by Harley-xk on 2019/4/23.
//

import Foundation
import UIKit
import Metal

/// not implemented yet
open class CanvasColorSamplerEvent: CanvasElement {
    public var index: Int = 0
    public var parentSize: CGSize = CGSize.zero
    public var startPoint: CGPoint = CGPoint.zero
    public var endPoint: CGPoint = CGPoint.zero
    public var startColor: UIColor = .clear
    public var endColor: UIColor = .clear
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(parentSize: CGSize, startPoint: CGPoint, startColor: UIColor, timeStamp: TimeInterval) {
        self.parentSize = parentSize
        self.startPoint = startPoint
        self.startColor = startColor
        self.startTime = timeStamp
    }
    
    public func drawSelf(on target: RenderTarget?) {
        //canvas?.printer.render(chartlet: self, on: target)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case index
        case parentSize
        case startPoint
        case endPoint
        case startColor
        case endColor
        case startTime
        case endTime
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        parentSize = try container.decode(CGSize.self, forKey: .parentSize)
        startPoint = try container.decode(CGPoint.self, forKey: .startPoint)
        endPoint = try container.decode(CGPoint.self, forKey: .endPoint)
        let sColor = try container.decodeIfPresent(String.self, forKey: .startColor)
        if sColor == nil {
            startColor = .white
        } else {
            startColor = UIColor(hexString: sColor!)
        }
        let eColor = try container.decodeIfPresent(String.self, forKey: .endColor)
        if eColor == nil {
            endColor = .white
        } else {
            endColor = UIColor(hexString: eColor!)
        }
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        
        try container.encode(parentSize, forKey: .parentSize)
        try container.encode(startPoint, forKey: .startPoint)
        try container.encode(endPoint, forKey: .endPoint)
        try container.encode(startColor.toHex, forKey: .startColor)
        try container.encode(endColor.toHex, forKey: .endColor)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
