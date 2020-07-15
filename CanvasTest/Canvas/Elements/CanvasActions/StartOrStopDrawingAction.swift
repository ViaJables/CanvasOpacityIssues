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
open class StartOrStopAction: CanvasElement {
    public var index: Int = 0
    public var starting: Bool = false
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(starting: Bool, timeStamp: TimeInterval) {
        self.starting = starting
        self.startTime = timeStamp
        self.endTime = timeStamp
    }
    
    public func drawSelf(on target: RenderTarget?) {
        //canvas?.printer.render(chartlet: self, on: target)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case index
        case starting
        case startTime
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        starting = try container.decode(Bool.self, forKey: .starting)
        startTime = try container.decode(Double.self, forKey: .startTime)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(starting, forKey: .starting)
        try container.encode(startTime, forKey: .startTime)
    }
}
