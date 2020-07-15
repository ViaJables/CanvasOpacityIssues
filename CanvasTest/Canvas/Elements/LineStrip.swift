//
//  MLLine.swift
//  MaLiang
//
//  Created by Harley.xk on 2018/4/12.
//

import Foundation
import Metal
import UIKit

/// a line strip with lines and brush info
open class LineStrip: CanvasElement {
    
    /// element index
    public var index: Int = 0
    
    /// identifier of bursh used to render this line strip
    public var brushName: String?
    
    /// default color
    // this color will be used when line's color not set
    public var color: MLColor
    
    /// line units of this line strip, avoid change this value directly when drawing.
    public var lines: [MLLine] = []
    
    public var startTime: TimeInterval = 0
    public var endTime: TimeInterval = 0
    
    /// brush used to render this line strip
    open weak var brush: Brush? {
        didSet {
            brushName = brush?.name
        }
    }
    
    public init(lines: [MLLine], brush: Brush, startTime: TimeInterval, endTime: TimeInterval) {
        self.lines = lines
        self.brush = brush
        self.brushName = brush.name
        self.color = brush.renderingColor
        self.startTime = startTime
        self.endTime = endTime
        
        remakBuffer(rotation: brush.rotation)
    }
    
    open func append(lines: [MLLine]) {
        self.lines.append(contentsOf: lines)
        vertex_buffer = nil
    }
    
    public func drawSelf(on target: RenderTarget?) {
        brush?.render(lineStrip: self, on: target)
    }
    
    public func clearCanvas() {
        guard let renderTarget = brush?.target?.screenTarget else { return }
        renderTarget.clear()
    }
    
    public func draw(on target: RenderTarget?, scaleFactor: Double) {
        guard lines.count > 0 else {
            return
        }
        
        var vertexes: [Point] = []
        
        lines.forEach { (line) in
            let scale = brush?.target?.contentScaleFactor ?? UIScreen.main.nativeScale
            var line = line
            line.begin = (line.begin * CGFloat(scaleFactor)) * scale
            line.end = (line.end * CGFloat(scaleFactor)) * scale
            let count = max(line.length / line.pointStep, 1)
            
            for i in 0 ..< Int(count) {
                let index = CGFloat(i)
                let x = line.begin.x + (line.end.x - line.begin.x) * (index / count)
                let y = line.begin.y + (line.end.y - line.begin.y) * (index / count)
                
                var angle: CGFloat = 0
                switch brush?.rotation {
                case let .fixed(a): angle = a
                case .random: angle = CGFloat.random(in: -CGFloat.pi ... CGFloat.pi)
                case .ahead: angle = line.angle
                case .none:
                    break
                }
                
                vertexes.append(Point(x: x, y: y, color: line.color ?? color, size: (line.pointSize * CGFloat(scaleFactor)) * scale, angle: angle))
            }
        }
        
        guard let renderTarget = brush?.target?.screenTarget else { return }
        renderTarget.prepareForDraw()
        
        guard let commandEncoder = renderTarget.makeCommandEncoder() else { return }
        commandEncoder.endEncoding()
        
        if let vertex_buffer = sharedDevice?.makeBuffer(bytes: vertexes, length: MemoryLayout<Point>.stride * vertexes.count, options: .cpuCacheModeWriteCombined) {

            DispatchQueue.main.async {
                self.brush?.render(buffer: vertex_buffer, commandEncoder: commandEncoder, vertexCount: vertexes.count)
                renderTarget.commitCommands()
            }
        }
    }
    

    
    /// get vertex buffer for this line strip, remake if not exists
    open func retrieveBuffers(rotation: Brush.Rotation) -> MTLBuffer? {
        if vertex_buffer == nil {
            remakBuffer(rotation: rotation)
        }
        return vertex_buffer
    }
    
    /// count of vertexes, set when remake buffers
    open private(set) var vertexCount: Int = 0
    
    private var vertex_buffer: MTLBuffer?
    
    private func remakBuffer(rotation: Brush.Rotation) {
            
            guard lines.count > 0 else {
                return
            }
            
            var vertexes: [Point] = []
            
            lines.forEach { (line) in
                let scale = brush?.target?.contentScaleFactor ?? UIScreen.main.nativeScale
                var line = line
                line.begin = line.begin * scale
                line.end = line.end * scale
                let count = max(line.length / line.pointStep, 1)
                
                // fix opacity of line color
                let overlapping = max(1, line.pointSize / line.pointStep)
                var renderingColor = line.color ?? color
                renderingColor.alpha = renderingColor.alpha / Float(overlapping) * 2.5
                
                for i in 0 ..< Int(count) {
                    let index = CGFloat(i)
                    let x = line.begin.x + (line.end.x - line.begin.x) * (index / count)
                    let y = line.begin.y + (line.end.y - line.begin.y) * (index / count)
                    
                    var angle: CGFloat = 0
                    switch rotation {
                    case let .fixed(a): angle = a
                    case .random: angle = CGFloat.random(in: -CGFloat.pi ... CGFloat.pi)
                    case .ahead: angle = line.angle
                    }
                    
                    vertexes.append(Point(x: x, y: y, color: renderingColor, size: line.pointSize * scale, angle: angle))
                }
            }
            
            vertexCount = vertexes.count
            vertex_buffer = sharedDevice?.makeBuffer(bytes: vertexes, length: MemoryLayout<Point>.stride * vertexCount, options: .cpuCacheModeWriteCombined)
        }
    
    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case index
        case brush
        case lines
        case color
        case startTime
        case endTime
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        brushName = try container.decode(String.self, forKey: .brush)
        lines = try container.decode([MLLine].self, forKey: .lines)
        color = try container.decode(MLColor.self, forKey: .color)
        startTime = try container.decode(Double.self, forKey: .startTime)
        endTime = try container.decode(Double.self, forKey: .endTime)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(brushName, forKey: .brush)
        try container.encode(lines, forKey: .lines)
        try container.encode(color, forKey: .color)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
