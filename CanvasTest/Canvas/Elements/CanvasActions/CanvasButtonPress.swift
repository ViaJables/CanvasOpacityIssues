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
open class CanvasButtonPress: CanvasElement {
    public enum ActionType: Int {
        case Undo = 0
        case Redo = 1
        case ToggleRef = 2
        case Brush = 3
        case Pencil = 4
        case Pen = 5
        case Eraser = 6
        case Opacity = 7
        case Stroke = 8
        case Color = 9
        case ToggleTrace = 10
        case AddReference = 11
        case ColorSampler = 12
    }
    
    public var index: Int = 0
    public var actionType: ActionType = .Undo
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(actionType: ActionType, timeStamp: TimeInterval) {
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
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(actionType.rawValue, forKey: .actionType)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
