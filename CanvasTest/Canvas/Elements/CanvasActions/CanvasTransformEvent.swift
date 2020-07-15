import Foundation
import UIKit
import Metal

/// not implemented yet
open class CanvasTransformEvent: CanvasElement {
    public var index: Int = 0
    public var startingTransform: CGAffineTransform = CGAffineTransform()
    public var endingTransform: CGAffineTransform = CGAffineTransform()
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    init(startingTransform: CGAffineTransform, timeStamp: TimeInterval) {
        self.startingTransform = startingTransform
        self.startTime = timeStamp
        self.endTime = timeStamp
    }
    
    public func drawSelf(on target: RenderTarget?) {
        //canvas?.printer.render(chartlet: self, on: target)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case index
        case startingTransform
        case endingTransform
        case startTime
        case endTime
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        startingTransform = try container.decode(CGAffineTransform.self, forKey: .startingTransform)
        endingTransform = try container.decode(CGAffineTransform.self, forKey: .endingTransform)
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(startingTransform, forKey: .startingTransform)
        try container.encode(endingTransform, forKey: .endingTransform)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
