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
open class CanvasDragEvent: CanvasElement {
    public var index: Int = 0
    public var parentSize: CGSize = CGSize.zero
    public var topLeftStart: CGPoint = CGPoint.zero
    public var centerStart: CGPoint = CGPoint.zero
    public var topLeftFinish: CGPoint = CGPoint.zero
    public var centerFinish: CGPoint = CGPoint.zero
    public var referenceFrame: CGRect = CGRect.zero
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(parentSize: CGSize, referenceFrame: CGRect, topLeftStart: CGPoint, centerStart: CGPoint, timeStamp: TimeInterval) {
        self.parentSize = parentSize
        self.referenceFrame = referenceFrame
        self.topLeftStart = topLeftStart
        self.centerStart = centerStart
        self.startTime = timeStamp
    }
    
    public func drawSelf(on target: RenderTarget?) {
        //canvas?.printer.render(chartlet: self, on: target)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case index
        case parentSize
        case referenceFrame
        case centerStart
        case topLeftStart
        case topLeftFinish
        case centerFinish
        case startTime
        case endTime
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        parentSize = try container.decode(CGSize.self, forKey: .parentSize)
        referenceFrame = try container.decode(CGRect.self, forKey: .referenceFrame)
        centerStart = try container.decode(CGPoint.self, forKey: .centerStart)
        topLeftStart = try container.decode(CGPoint.self, forKey: .topLeftStart)
        topLeftFinish = try container.decode(CGPoint.self, forKey: .topLeftFinish)
        centerFinish = try container.decode(CGPoint.self, forKey: .centerFinish)
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        
        try container.encode(parentSize, forKey: .parentSize)
        try container.encode(referenceFrame, forKey: .referenceFrame)
        try container.encode(centerStart, forKey: .centerStart)
        try container.encode(topLeftStart, forKey: .topLeftStart)
        try container.encode(topLeftFinish, forKey: .topLeftFinish)
        try container.encode(centerFinish, forKey: .centerFinish)
        
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
