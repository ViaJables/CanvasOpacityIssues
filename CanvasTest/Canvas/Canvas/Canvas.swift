//
//  Canvas.swift
//  MaLiang
//
//  Created by Harley.xk on 2018/4/11.
//

import UIKit

protocol CanvasColorSampleDelegate: class {
    func sampleColorBegan(color: UIColor, touch: UITouch)
    func sampleColorMoved(color: UIColor, touch: UITouch)
    func finishedSamplingColor(color: UIColor, touch: UITouch)
}

open class Canvas: MetalView {
    
    // MARK: - Brushes
    weak var colorSampleDelegate: CanvasColorSampleDelegate?
    
    /// default round point brush, will not show in registeredBrushes
    open var defaultBrush: Brush!
    
    /// printer to print image textures on canvas
    open private(set) var printer: Printer!
    
    /// pencil only mode for apple pencil, defaults to false
    /// if sets to true, all touches with toucheType that is not pencil will be ignored
    open var isPencilMode = false {
        didSet {
            // enable multiple touch for pencil mode
            // this makes user to draw with pencil when finger is already on the screen
            isMultipleTouchEnabled = isPencilMode
        }
    }
    
    open var useFingersToErase = false
    
    open var isSamplingColor = false
    open var twoFingerTapDetected = false
    
    /// the actual size of canvas in points, may be larger than current bounds
    /// size must between bounds size and 5120x5120
    open var size: CGSize {
        print("Canvas size: \(drawableSize) / \(contentScaleFactor)")
        return drawableSize / contentScaleFactor
    }
    
    // delegate & observers
    
    open weak var renderingDelegate: RenderingDelegate?
    
    internal var actionObservers = ActionObserverPool()
    
    // add an observer to observe data changes, observers are not retained
    open func addObserver(_ observer: ActionObserver) {
        // pure nil objects
        actionObservers.clean()
        actionObservers.addObserver(observer)
    }
    
    /// Register a brush with image data
    ///
    /// - Parameter texture: texture data of brush
    /// - Returns: registered brush
    @discardableResult open func registerBrush<T: Brush>(name: String? = nil, from data: Data) throws -> T {
        let texture = try makeTexture(with: data)
        let brush = T(name: name, textureID: texture.id, target: self)
        registeredBrushes.append(brush)
        return brush
    }
    
    /// Register a brush with image data
    ///
    /// - Parameter file: texture file of brush
    /// - Returns: registered brush
    @discardableResult open func registerBrush<T: Brush>(name: String? = nil, from file: URL) throws -> T {
        let data = try Data(contentsOf: file)
        return try registerBrush(name: name, from: data)
    }
    
    /// Register a new brush with texture already registered on this canvas
    ///
    /// - Parameter textureID: id of a texture, default round texture will be used if sets to nil or texture id not found
    open func registerBrush<T: Brush>(name: String? = nil, textureID: String? = nil) throws -> T {
        let brush = T(name: name, textureID: textureID, target: self)
        registeredBrushes.append(brush)
        return brush
    }
    
    /// current brush used to draw
    /// only registered brushed can be set to current
    /// get a brush from registeredBrushes and call it's use() method to make it current
    open internal(set) var currentBrush: Brush!
    
    /// All registered brushes
    open private(set) var registeredBrushes: [Brush] = []
    
    /// find a brush by name
    /// nill will be retured if brush of name provided not exists
    open func findBrushBy(name: String?) -> Brush? {
        return registeredBrushes.first { $0.name == name }
    }
    
    /// All textures created by this canvas
    open private(set) var textures: [MLTexture] = []
    
    /// make texture and cache it with ID
    ///
    /// - Parameters:
    ///   - data: image data of texture
    ///   - id: id of texture, will be generated if not provided
    /// - Returns: created texture, if the id provided is already exists, the existing texture will be returend
    @discardableResult
    override open func makeTexture(with data: Data, id: String? = nil) throws -> MLTexture {
        // if id is set, make sure this id is not already exists
        if let id = id, let exists = findTexture(by: id) {
            return exists
        }
        let texture = try super.makeTexture(with: data, id: id)
        textures.append(texture)
        textures.forEach {
            let i = $0.texture.toUIImage()
            addSubview(UIImageView(image: i))
        }
        return texture
    }
    
    /// find texture by textureID
    open func findTexture(by id: String) -> MLTexture? {
        return textures.first { $0.id == id }
    }
    
    @available(*, deprecated, message: "this property will be removed soon, set the property forceSensitive on brush to 0 instead, changing this value will cause no effects")
    open var forceEnabled: Bool = true
    
    // MARK: - Zoom and scale
    /// the scale level of view, all things scales
    open var scale: CGFloat {
        get {
            return brushTarget?.scale ?? 1
        }
        set {
            brushTarget?.scale = newValue
        }
    }
    
    /// the zoom level of render target, only scale render target
    open var zoom: CGFloat {
        get {
            return brushTarget?.zoom ?? 1
        }
        set {
            brushTarget?.zoom = newValue
        }
    }
    
    /// the offset of render target with zoomed size
    open var contentOffset: CGPoint {
        get {
            return brushTarget?.contentOffset ?? .zero
        }
        set {
            brushTarget?.contentOffset = newValue
        }
    }
    
    // setup gestures
    open var paintingGesture: PaintingGestureRecognizer?
    
    /// this will setup the canvas and gestures、default brushs
    open override func setup() {
        super.setup()
        
        isMultipleTouchEnabled = true
        
        /// initialize default brush
        defaultBrush = Brush(name: "maliang.default", textureID: nil, target: self)
        currentBrush = defaultBrush
        
        /// initialize printer
        printer = Printer(name: "maliang.printer", textureID: nil, target: self)
        
        data = CanvasData()
        lessonData = LessonData()
    }
    
    /// take a snapshot on current canvas and export an image
    open func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, contentScaleFactor)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /// clear all things on the canvas
    ///
    /// - Parameter display: redraw the canvas if this sets to true
    open override func clear(display: Bool = true) {
        super.clear(display: display)
        
        if display {
            data.appendClearAction()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        //redraw()
    }
    
    // MARK: - Document
    public private(set) var data: CanvasData!
    public private(set) var lessonData: LessonData!
    
    /// reset data on canvas, this method will drop the old data object and create a new one.
    /// - Attention: SAVE your data before call this method!
    /// - Parameter redraw: if should redraw the canvas after, defaults to true
    open func resetData(redraw: Bool = true) {
        let oldData = data!
        let newData = CanvasData()
        // link registered observers to new data
        newData.observers = data.observers
        data = newData
        if redraw {
            self.redraw()
        }
        data.observers.data(oldData, didResetTo: newData)
    }
    
    public func undo() {
        if let data = data, data.undo() {
            print("undo")
            redraw()
        }
    }
    
    public func redo() {
        if let data = data, data.redo() {
            redraw()
        }
    }
    
    public func adjustContentSize(originalSize: CGSize) -> [CanvasElement] {
        let canvasSize = self.frame.size
        let adjustment = canvasSize.width/originalSize.width
        var newData: [CanvasElement] = []
        for element in data.elements {
            if let el = element as? LineStrip {
                var lines: [MLLine] = []
                for ml in el.lines {
                    let line = MLLine(begin: ml.begin * adjustment, end: ml.end * adjustment, pointSize: ml.pointSize * adjustment, pointStep: ml.pointStep * adjustment, color: el.color)
                    
                    lines.append(line)
                }
                let lineStrip = LineStrip(lines: lines, brush: el.brush!, startTime: el.startTime, endTime: el.endTime)
                lineStrip.brushName = el.brushName
                lineStrip.color = el.color
                newData.append(lineStrip)
            } else {
                newData.append(element)
            }
        }
        
        return newData
    }
    
    /// redraw elemets in document
    /// - Attention: this method must be called on main thread
    open func redraw(on target: RenderTarget? = nil) {
        guard Thread.isMainThread else {
            fatalError("redraw not called on MainThread")
        }
        
        guard let target = target ?? brushTarget
            else { return }
        
        data.finishCurrentElement()

        target.updateBuffer(with: drawableSize)

        target.clear()
        canvasTextures.forEach { $0?.clear() }
        
        data.elements.forEach {
            $0.drawSelf(on: target)
            // TODO: this must be tested
            transferBrushToCanvas()
        }
        /// submit commands
        target.commitCommands()
        
        //actionObservers.canvas(self, didRedrawOn: target)
    }
    
    
    // MARK: - Bezier
    // optimize stroke with bezier path, defaults to true
    //    private var enableBezierPath = true
    private var bezierGenerator = BezierGenerator()
    
    // MARK: - Drawing Actions
    private var lastRenderedPan: Pan?
    
    private func pushPoint(_ point: CGPoint, to bezier: BezierGenerator, force: CGFloat, isEnd: Bool = false) {
        var lines: [MLLine] = []
        let vertices = bezier.pushPoint(point)
        guard vertices.count >= 2 else {
            return
        }
        var lastPan = lastRenderedPan ?? Pan(point: vertices[0], force: force)
        let deltaForce = (force - (lastRenderedPan?.force ?? force)) / CGFloat(vertices.count)
        for i in 1 ..< vertices.count {
            let p = vertices[i]
            let pointStep = currentBrush.pointStep
            if  // end point of line
                (isEnd && i == vertices.count - 1) ||
                    // ignore step
                    pointStep <= 1 ||
                    // distance larger than step
                    (pointStep > 1 && lastPan.point.distance(to: p) >= pointStep)
            {
                let force = lastPan.force + deltaForce
                let pan = Pan(point: p, force: force)
                let line = currentBrush.makeLine(from: lastPan, to: pan)
                lines.append(contentsOf: line)
                lastPan = pan
                lastRenderedPan = pan
            }
        }
        
        render(lines: lines)

        if isEnd {
            transferBrushToCanvas()
        }
    }
    
    // MARK: - Rendering
    open func render(lines: [MLLine]) {
        data.append(lines: lines, with: currentBrush)
        lessonData.append(lines: lines, with: currentBrush)
        // create a temporary line strip and draw it on canvas
        let date = NSDate().timeIntervalSince1970
        LineStrip(lines: lines, brush: currentBrush, startTime: date, endTime: date).drawSelf(on: brushTarget)

        /// submit commands
        brushTarget?.commitCommands()
        brushOpacity = Float(currentBrush.opacity)
    }
        
    open func renderTap(at point: CGPoint, to: CGPoint? = nil) {
        
        guard renderingDelegate?.canvas(self, shouldRenderTapAt: point) ?? true else {
            return
        }
        
        let brush = currentBrush!
        let lines = brush.makeLine(from: point, to: to ?? point)
        render(lines: lines)
        
        transferBrushToCanvas()
    }
    
    /// draw a chartlet to canvas
    ///
    /// - Parameters:
    ///   - point: location where to draw the chartlet
    ///   - size: size of texture
    ///   - textureID: id of texture for drawing
    ///   - rotation: rotation angle of texture for drawing
    open func renderChartlet(at point: CGPoint, size: CGSize, textureID: String, rotation: CGFloat = 0) {
        
        let chartlet = Chartlet(center: point, size: size, textureID: textureID, angle: rotation, canvas: self)
        
        guard renderingDelegate?.canvas(self, shouldRenderChartlet: chartlet) ?? true else {
            return
        }
        
        data.append(chartlet: chartlet)
        chartlet.drawSelf(on: brushTarget)
        brushTarget?.commitCommands()
        setNeedsDisplay()
        
        actionObservers.canvas(self, didRenderChartlet: chartlet)
    }
    
    // MARK: - Touches
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        twoFingerTapDetected = false
        if touches.count > 1 {
            //undo()
            return
        }
        
        if touches.count == 3 {
            //redo()
            return
        }
        
        if touches.count > 3 {
            return
        }
        
        
        guard let touch = firstAvaliableTouch(from: touches) else {
            return
        }
        
        if isSamplingColor {
            if let color = getColor(point: touch.location(in: self)) {
                colorSampleDelegate?.sampleColorBegan(color: color, touch: touch)
            }
            return
        }
        
        
        let pan = Pan(touch: touch, on: self)
        lastRenderedPan = pan
        
        guard renderingDelegate?.canvas(self, shouldBeginLineAt: pan.point, force: pan.force) ?? true else {
            return
        }
        
        bezierGenerator.begin(with: pan.point)
        pushPoint(pan.point, to: bezierGenerator, force: pan.force)
        actionObservers.canvas(self, didBeginLineAt: pan.point, force: pan.force)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 { return }
        
        guard let touch = firstAvaliableTouch(from: touches) else {
            return
        }
        
        if twoFingerTapDetected {
            return
        }
        
        if isSamplingColor {
            if let color = getColor(point: touch.location(in: self)) {
                colorSampleDelegate?.sampleColorMoved(color: color, touch: touch)
            }
            return
        }
        
        guard bezierGenerator.points.count > 0 else { return }
        let pan = Pan(touch: touch, on: self)
        guard pan.point != lastRenderedPan?.point else {
            return
        }
        
        // If this is a two finger tap and pan it will register it as a single point but the distance will be great
        if bezierGenerator.points.count == 1 {
            let distance = CGPointDistance(from: bezierGenerator.points.last!, to: pan.point)
            if distance > 50.0 {
                print("twoFingerTapDetected")
                twoFingerTapDetected = true
                undo()
                return
            }
        }
        pushPoint(pan.point, to: bezierGenerator, force: pan.force)
        actionObservers.canvas(self, didMoveLineTo: pan.point, force: pan.force)
    }
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if twoFingerTapDetected {
            twoFingerTapDetected = false
            undo()
            return
        }
        
        if touches.count > 1 { return }
        
        guard let touch = firstAvaliableTouch(from: touches) else {
            return
        }
        
        if isSamplingColor {
            if let color = getColor(point: touch.location(in: self)) {
                colorSampleDelegate?.finishedSamplingColor(color: color, touch: touch)
            }
            return
        }

        let pan = Pan(touch: touch, on: self)
        let count = bezierGenerator.points.count
        
        if count >= 3 {
            pushPoint(pan.point, to: bezierGenerator, force: pan.force, isEnd: true)
        } else if count > 0 {
            renderTap(at: bezierGenerator.points.first!, to: bezierGenerator.points.last!)
        }
        
        let unfishedLines = currentBrush.finishLineStrip(at: Pan(point: pan.point, force: pan.force))
        if unfishedLines.count > 0 {
            render(lines: unfishedLines)
        }

        actionObservers.canvas(self, didFinishLineAt: pan.point, force: pan.force)
        
        bezierGenerator.finish()
        lastRenderedPan = nil
        data.finishCurrentElement()
        lessonData.finishCurrentElement()
    }
    
    private func firstAvaliableTouch(from touches: Set<UITouch>) -> UITouch? {
        if #available(iOS 9.1, *), isPencilMode {
            return touches.first { (t) -> Bool in
                return t.type == .pencil
            }
        } else {
            return touches.first
        }
    }
    
    // Doesn't work but might be starting point
    func getColor(point: CGPoint) -> UIColor? {
        if let curDrawable = self.currentDrawable {
            let x = point.x
            let y = point.y
            
            if x < 0 || y < 0 || x > self.bounds.width || y > self.bounds.height {
                return nil
            }
            
            var pixel: [CUnsignedChar] = [0, 0, 0, 0]  // bgra

            let textureScale = CGFloat(curDrawable.texture.width) / self.bounds.width
            let bytesPerRow = curDrawable.texture.width * 4
            //let y = self.bounds.height - y
            //let y = point.y
            print("\(x) \(y)")
            curDrawable.texture.getBytes(&pixel, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(Int(x * textureScale), Int(y * textureScale), 1, 1), mipmapLevel: 0)
            let red: CGFloat   = CGFloat(pixel[2]) / 255.0
            let green: CGFloat = CGFloat(pixel[1]) / 255.0
            let blue: CGFloat  = CGFloat(pixel[0]) / 255.0
            let alpha: CGFloat = CGFloat(pixel[3]) / 255.0
            let color = UIColor(red:red, green: green, blue:blue, alpha:alpha)
            print("\(red) \(green) \(blue) \(alpha)")
            
            if red == 0 && green == 0 && blue == 0 && alpha == 0 {
                return .white
            }
            
            return color
        }
        
        //framebufferOnly = true
        return nil
    }
}
