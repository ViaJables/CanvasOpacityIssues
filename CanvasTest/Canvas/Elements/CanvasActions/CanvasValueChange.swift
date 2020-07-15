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
open class CanvasValueChange: CanvasElement {
    public enum ActionType: Int {
        case Opacity = 0
        case Stroke = 1
        case ColorBrightness = 2
        case TraceAlpha = 3
    }
    
    public var index: Int = 0
    public var value: Double = 0.0
    public var actionType: ActionType = .Opacity
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(actionType: ActionType, value: Double, timeStamp: TimeInterval) {
        self.value = value
        self.actionType = actionType
        self.startTime = timeStamp
        self.endTime = timeStamp
    }
    
    public func drawSelf(on target: RenderTarget?) {
        //canvas?.printer.render(chartlet: self, on: target)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case index
        case value
        case actionType
        case startTime
        case endTime
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        let typeID = try container.decode(Int.self, forKey: .actionType)
        actionType = ActionType(rawValue: typeID)!
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
        value = try container.decode(Double.self, forKey: .value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(actionType.rawValue, forKey: .actionType)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(value, forKey: .value)
    }
}
