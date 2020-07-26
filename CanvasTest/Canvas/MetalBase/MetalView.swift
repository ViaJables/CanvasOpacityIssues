//
//  MetalView.swift
//  MaLiang_Example
//
//  Created by Harley-xk on 2019/4/3.
//  Copyright © 2019 Harley-xk. All rights reserved.
//

import UIKit
import QuartzCore
import MetalKit

internal let sharedDevice = MTLCreateSystemDefaultDevice()

open class MetalView: MTKView {
    
    // MARK: - Brush Textures
    
    func makeTexture(with data: Data, id: String? = nil) throws -> MLTexture {
        guard metalAvaliable else {
            throw MLError.simulatorUnsupported
        }
        let textureLoader = MTKTextureLoader(device: device!)
        let texture = try textureLoader.newTexture(data: data, options: [.SRGB : false])
        return MLTexture(id: id ?? UUID().uuidString, texture: texture)
    }
    
    func makeTexture(with file: URL, id: String? = nil) throws -> MLTexture {
        let data = try Data(contentsOf: file)
        return try makeTexture(with: data, id: id)
    }
    
    // MARK: - Functions
    // Erases the screen, redisplay the buffer if display sets to true
    open func clear(display: Bool = true) {
        brushTarget?.clear()
        if display {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Render

    open override func layoutSubviews() {
        super.layoutSubviews()
        brushTarget?.updateBuffer(with: drawableSize)
    }
    
    open override var backgroundColor: UIColor? {
        didSet {
            clearColor = (backgroundColor ?? .white).toClearColor()
        }
    }
    
    // MARK: - Setup
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var metalLayer: CAMetalLayer? {
        guard metalAvaliable, let layer = layer as? CAMetalLayer else {
            fatalError("Metal initialize failed!")
        }
        return layer
    }
    
    open func setup() {
        print("MetalView: setup")
        device = sharedDevice
        isOpaque = false
        
        supportsReadWriteTexture = device!.readWriteTextureSupport == .tier2
        
        resetCanvas()
    }
    
    open func resetCanvas() {
        guard metalAvaliable else {
            print("<== Drawing is disabled on the Simulator.  ==>")
            return
        }
        
        print("MetalView drawableSize:")
        print(drawableSize)
        brushTarget = RenderTarget(size: drawableSize, pixelFormat: colorPixelFormat, device: device)
        
        canvasTextures.removeAll()
        for _ in 0..<canvasTexturesCount {
            if let newCanvasTexture = brushTarget?.makeEmptyTexture() {
                canvasTextures.append(newCanvasTexture)
            }
        }
        commandQueue = device?.makeCommandQueue()
        
        setupTargetUniforms()
        
        do {
            try setupPiplineState()
        } catch {
            fatalError("Metal initialize failed: \(error.localizedDescription)")
        }
    }
    
    // pipeline state
    
    private var pipelineState: MTLRenderPipelineState!
    private var computePipelineState: MTLComputePipelineState!

    private func setupPiplineState() throws {
        let library = device?.libraryForMaLiang()
        let vertex_func = library?.makeFunction(name: "vertex_render_target")
        let fragment_func = library?.makeFunction(name: "fragment_render_target")
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineState = try device?.makeRenderPipelineState(descriptor: rpd)

        let transferBrushKernelName = (canvasTexturesCount == 1) ? "kernel_transfer_brush_fast" : "kernel_transfer_brush"
        let transferBrushKernel = library?.makeFunction(name: transferBrushKernelName)
        computePipelineState = try device?.makeComputePipelineState(function: transferBrushKernel!)
        
    }
    
    // render target for rendering contents to screen
    internal var brushTarget: RenderTarget?
    internal var brushOpacity: Float = 0

    internal var supportsReadWriteTexture: Bool = false
    // we need 2 textures for devices that don't support read::write access in compute shaders
    private var canvasTexturesCount: Int { supportsReadWriteTexture ? 1 : 2 }
    private var currentCanvasTextureIndex = 0
    private var nextCanvasTextureIndex: Int {
        (currentCanvasTextureIndex + 1) % canvasTexturesCount
    }
    internal var canvasTextures = [MTLTexture?]()
    
    private var commandQueue: MTLCommandQueue?
    
    // Uniform buffers
    private var render_target_vertex: MTLBuffer!
    private var render_target_uniform: MTLBuffer!
    
    func setupTargetUniforms() {
        let size = drawableSize
        let w = size.width, h = size.height
        let vertices = [
            Vertex(position: CGPoint(x: 0 , y: 0), textCoord: CGPoint(x: 0, y: 0)),
            Vertex(position: CGPoint(x: w , y: 0), textCoord: CGPoint(x: 1, y: 0)),
            Vertex(position: CGPoint(x: 0 , y: h), textCoord: CGPoint(x: 0, y: 1)),
            Vertex(position: CGPoint(x: w , y: h), textCoord: CGPoint(x: 1, y: 1)),
        ]
        render_target_vertex = device?.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: .cpuCacheModeWriteCombined)
        
        let matrix = Matrix.identity
        matrix.scaling(x: 2 / Float(size.width), y: -2 / Float(size.height), z: 1)
        matrix.translation(x: -1, y: 1, z: 0)
        render_target_uniform = device?.makeBuffer(bytes: matrix.m, length: MemoryLayout<Float>.size * 16, options: [])
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard
            let brushTarget = brushTarget,
            brushTarget.modified,
            let brushTexture = brushTarget.texture,
            let canvasTexture = canvasTextures[currentCanvasTextureIndex]
            else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        guard
            let attachment = renderPassDescriptor.colorAttachments[0]
            else { fatalError("can't get colorAttachment") }
        attachment.clearColor = clearColor
        attachment.texture = currentDrawable?.texture
        attachment.loadAction = .clear
        attachment.storeAction = .store
        
        guard
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            else { return }
        
        commandEncoder.setRenderPipelineState(pipelineState)
        
        commandEncoder.setVertexBuffer(render_target_vertex, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(render_target_uniform, offset: 0, index: 1)
        /// canvas
        commandEncoder.setFragmentTexture(canvasTexture, index: 0)
        /// current brush
        commandEncoder.setFragmentTexture(brushTexture, index: 1)
        /// current Brush opacity
        commandEncoder.setFragmentBytes(&brushOpacity, length: MemoryLayout<Float>.stride, index: 0)

        commandEncoder.setFragmentSamplerState(brushTarget.samplerState, index: 0)
        commandEncoder.setFragmentSamplerState(brushTarget.samplerState, index: 1)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    
        commandEncoder.endEncoding()
        if let drawable = currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
        
//        canvasTarget.modified = false
    }
    
    func transferBrushToCanvas() {

        guard
            let brushTarget = brushTarget,
            let canvasTextureIn = canvasTextures[currentCanvasTextureIndex],
            let brushTexture = brushTarget.texture,
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            else { return }

        
        commandEncoder.setComputePipelineState(computePipelineState!)

        /// current brush
        commandEncoder.setTexture(brushTexture, index: 0)
        /// canvas in
        commandEncoder.setTexture(canvasTextureIn, index: 1)
        
        if !supportsReadWriteTexture {
            /// canvas out
            let canvasTextureOut = canvasTextures[nextCanvasTextureIndex]!
            commandEncoder.setTexture(canvasTextureOut, index: 2)
        }
        
        /// pass the current Brush opacity to the shader
        commandEncoder.setBytes(&brushOpacity, length: MemoryLayout<Float>.stride, index: 0)
        
        let threadGroupCounts = MTLSizeMake(8, 8, 1);
        let threadGroups = MTLSizeMake(brushTexture.width  / threadGroupCounts.width,
                                       brushTexture.height / threadGroupCounts.height,
                                       1);
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCounts)
                
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        if !supportsReadWriteTexture {
            // switch to the next canvas texture
            currentCanvasTextureIndex = nextCanvasTextureIndex
            // clear the brush texture
            brushTexture.clear()
        }

    }
    
}

// MARK: - Simulator fix

internal var metalAvaliable: Bool = {
    #if targetEnvironment(simulator)
    if #available(iOS 13.0, *) {
        return true
    } else {
        return false
    }
    #else
    return true
    #endif
}()
