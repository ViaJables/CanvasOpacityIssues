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
open class CanvasReferenceResize: CanvasElement {
    public var index: Int = 0
    public var referenceFrame: CGRect = CGRect.zero
    public var parentFrame: CGRect = CGRect.zero
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(referenceFrame: CGRect, parentFrame: CGRect, timeStamp: TimeInterval) {
        self.referenceFrame = referenceFrame
        self.parentFrame = parentFrame
        self.startTime = timeStamp
        self.endTime = timeStamp
    }
    
    public func drawSelf(on target: RenderTarget?) {
        //canvas?.printer.render(chartlet: self, on: target)
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case index
        case referenceFrame
        case parentFrame
        case startTime
        case endTime
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        referenceFrame = try container.decode(CGRect.self, forKey: .referenceFrame)
        parentFrame = try container.decode(CGRect.self, forKey: .parentFrame)
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(referenceFrame, forKey: .referenceFrame)
        try container.encode(parentFrame, forKey: .parentFrame)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
