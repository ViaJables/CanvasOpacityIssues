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
open class CanvasColorChange: CanvasElement {
    public var index: Int = 0
    public var color: UIColor = .black
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(color: UIColor, timeStamp: TimeInterval) {
        self.color = color
        self.startTime = timeStamp
        self.endTime = timeStamp
    }
    
    public func drawSelf(on target: RenderTarget?) {
        //canvas?.printer.render(chartlet: self, on: target)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case index
        case color
        case startTime
        case endTime
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        let hex = try container.decode(String.self, forKey: .color)
        color = UIColor(hexString: hex)
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(color.toHex, forKey: .color)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
