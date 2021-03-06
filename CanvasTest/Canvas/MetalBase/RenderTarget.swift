//
//  RenderTarget.swift
//  MaLiang
//
//  Created by Harley-xk on 2019/4/15.
//

import UIKit
import Foundation
import Metal
import simd

/// a target for any thing that can be render on
open class RenderTarget {
    
    /// texture to render on
    public private(set) var texture: MTLTexture? {
        didSet {
            print("TEXTURE WAS SET")
        }
    }
    
    public let samplerState: MTLSamplerState
    /// the scale level of view, all things scales
    open var scale: CGFloat = 1 {
        didSet {
            updateTransformBuffer()
        }
    }
    
    /// the zoom level of render target, only scale render target
    open var zoom: CGFloat = 1

    /// the offset of render target with zoomed size
    open var contentOffset: CGPoint = .zero {
        didSet {
            updateTransformBuffer()
        }
    }
        
    /// create with texture and device
    public init(size: CGSize, pixelFormat: MTLPixelFormat, device: MTLDevice?) {
        
        self.drawableSize = size
        self.pixelFormat = pixelFormat
        self.device = device
        
        self.commandQueue = device?.makeCommandQueue()
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        
        samplerState = self.device!.makeSamplerState(descriptor: samplerDescriptor)!
        
        self.texture = makeEmptyTexture()
        
        renderPassDescriptor = MTLRenderPassDescriptor()
        let attachment = renderPassDescriptor?.colorAttachments[0]
        attachment?.texture = texture
        attachment?.loadAction = .load
        attachment?.storeAction = .store
        
        updateBuffer(with: size)
    }

    
    /// clear the contents of texture
    open func clear() {
///  this is very expensive, as it recreates the texture instead of just clearing it.
//        texture = makeEmptyTexture()
//        renderPassDescriptor?.colorAttachments[0].texture = texture
        
/// clearing the texture instead
        texture?.clear()

        commitCommands()
    }
    
    internal var pixelFormat: MTLPixelFormat = .bgra8Unorm
    internal var drawableSize: CGSize
    internal var uniform_buffer: MTLBuffer!
    internal var transform_buffer: MTLBuffer!
    internal var renderPassDescriptor: MTLRenderPassDescriptor?
    internal var commandBuffer: MTLCommandBuffer?
    internal var commandQueue: MTLCommandQueue?
    internal var device: MTLDevice?
    internal var modified = false
    
    internal func updateBuffer(with size: CGSize) {
        self.drawableSize = size
        let matrix = Matrix.identity
        let zoomUniform = 2 * Float(zoom / scale )
        matrix.scaling(x: zoomUniform  / Float(size.width), y: -zoomUniform / Float(size.height), z: 1)
        matrix.translation(x: -1, y: 1, z: 0)
        uniform_buffer = device?.makeBuffer(bytes: matrix.m, length: MemoryLayout<Float>.size * 16, options: [])
        
        updateTransformBuffer()
    }
    
    internal func updateTransformBuffer() {
        let scaleFactor = UIScreen.main.nativeScale
        var transform = ScrollingTransform(offset: contentOffset * scaleFactor, scale: scale)
        transform_buffer = device?.makeBuffer(bytes: &transform, length: MemoryLayout<ScrollingTransform>.stride, options: [])
    }
    
    internal func prepareForDraw() {
        if commandBuffer == nil {
            commandBuffer = commandQueue?.makeCommandBuffer()
        }
    }

    internal func makeCommandEncoder() -> MTLRenderCommandEncoder? {
        guard let commandBuffer = commandBuffer, let rpd = renderPassDescriptor else  {
            return nil
        }
        
//        if rpd.renderTargetArrayLength == 0 {
//            return nil
//        }
        
        
        return commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
    }
    
    internal func commitCommands() {
        commandBuffer?.commit()
        commandBuffer = nil
        modified = true
    }
        
    // make empty texture
    open func makeEmptyTexture() -> MTLTexture? {
        guard drawableSize.width * drawableSize.height > 0 else {
            return nil
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: Int(drawableSize.width),
                                                                         height: Int(drawableSize.height),
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let texture = device?.makeTexture(descriptor: textureDescriptor)
        texture?.clear()
        return texture
    }
    
}
