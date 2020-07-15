//
//  LessonData.swift
//  TinyStudio
//
//  Created by John Brunsfeld on 4/11/20.
//  Copyright © 2020 John Brunsfeld. All rights reserved.
//

import Foundation
import UIKit


/// content data on canvas
open class LessonData {
    /// current drawing elements, avoid to change this value when drawing
    open var elements: [CanvasElement] = []
    
    /// current unfinished element, avoid to change this value when drawing
    open var currentElement: CanvasElement?
    
    open var currentTransform: CanvasElement?
    open var currentDrag: CanvasElement?
    open var currentAudio: CanvasElement?
    open var currentSample: CanvasElement?
    
    
    var referenceDate: TimeInterval = NSDate().timeIntervalSince1970
    
    /// index for latest element
    open var lastElementIndex: Int {
        return elements.last?.index ?? 0
    }
    
    open func resetData(redraw: Bool = true) {
        currentElement = nil
        currentTransform = nil
        currentDrag = nil
        elements = []
    }
    
    open func addStartStop(starting: Bool) {
        referenceDate = NSDate().timeIntervalSince1970
        let ss = StartOrStopAction(starting: starting, timeStamp: referenceDate)
        elements.append(ss)
    }
    
    open func addAction(actionType: CanvasButtonPress.ActionType) {
        let now = NSDate().timeIntervalSince1970
        let bp = CanvasButtonPress(actionType: actionType, timeStamp: now-referenceDate)
        elements.append(bp)
    }
    
    open func addValueChange(actionType: CanvasValueChange.ActionType, value: Double) {
        let now = NSDate().timeIntervalSince1970
        let bp = CanvasValueChange(actionType: actionType, value: value, timeStamp: now-referenceDate)
        elements.append(bp)
    }
    
    open func addReferenceResize(referenceFrame: CGRect, parentFrame: CGRect) {
        let now = NSDate().timeIntervalSince1970
        let crr = CanvasReferenceResize(referenceFrame: referenceFrame, parentFrame: parentFrame, timeStamp: now-referenceDate)
        elements.append(crr)
    }
    
    open func addColorChange(color: UIColor) {
        let now = NSDate().timeIntervalSince1970
        let cc = CanvasColorChange(color: color, timeStamp: now-referenceDate)
        elements.append(cc)
    }
    
    open func append(lines: [MLLine], with brush: Brush) {
        guard lines.count > 0 else {
            return
        }
        // append lines to current line strip
        if let lineStrip = currentElement as? LineStrip, lineStrip.brush === brush {
            lineStrip.append(lines: lines)
        } else {
            finishCurrentElement()
            let timeStamp = NSDate().timeIntervalSince1970 - referenceDate
            let lineStrip = LineStrip(lines: lines, brush: brush, startTime: timeStamp, endTime: timeStamp)
            currentElement = lineStrip
        }
    }
    
    open func startTransform(transform: CGAffineTransform) {
        let timeStamp = NSDate().timeIntervalSince1970 - referenceDate
        let transform = CanvasTransformEvent(startingTransform: transform, timeStamp: timeStamp)
        elements.append(transform)
        currentTransform = transform
    }
    
    open func finishTransform(transform: CGAffineTransform) {
        if let transformElement = currentTransform as? CanvasTransformEvent {
            transformElement.endTime = NSDate().timeIntervalSince1970 - referenceDate
            transformElement.endingTransform = transform
        }
    }
    
    open func addDragStart(parentSize: CGSize, referenceFrame: CGRect, topLeft: CGPoint, center: CGPoint) {
        let timeStamp = NSDate().timeIntervalSince1970 - referenceDate
        let drag = CanvasDragEvent(parentSize: parentSize, referenceFrame: referenceFrame, topLeftStart: topLeft, centerStart: center, timeStamp: timeStamp)
        elements.append(drag)
        currentDrag = drag
    }
    
    open func finishDrag(topLeft: CGPoint, center: CGPoint) {
        if let dragElement = currentDrag as? CanvasDragEvent {
            dragElement.endTime = NSDate().timeIntervalSince1970 - referenceDate
            dragElement.topLeftFinish = topLeft
            dragElement.centerFinish = center
        }
    }
    
    open func addColorSampleStart(parentSize: CGSize, startPoint: CGPoint, startColor: UIColor) {
        let timeStamp = NSDate().timeIntervalSince1970 - referenceDate
        let sample = CanvasColorSamplerEvent(parentSize: parentSize, startPoint: startPoint, startColor: startColor, timeStamp: timeStamp)
        elements.append(sample)
        currentSample = sample
    }
    
    open func finishColorSample(endPoint: CGPoint, endColor: UIColor) {
        if let dragElement = currentSample as? CanvasColorSamplerEvent {
            dragElement.endTime = NSDate().timeIntervalSince1970 - referenceDate
            dragElement.endPoint = endPoint
            dragElement.endColor = endColor
        }
    }
    
    open func addAudioStart(streamPath: String) {
        let timeStamp = NSDate().timeIntervalSince1970 - referenceDate
        let audio = CanvasAudioRecording(streamPath: streamPath, timeStamp: timeStamp)
        elements.append(audio)
        currentAudio = audio
    }
    
    open func finishAudio() {
        if let audioElement = currentAudio as? CanvasAudioRecording {
            audioElement.endTime = NSDate().timeIntervalSince1970 - referenceDate
        }
    }
    
    open func addReference(image_url: String) {
        let timeStamp = NSDate().timeIntervalSince1970 - referenceDate
        let ar = CanvasAddReference(imageURL: image_url, timeStamp: timeStamp)
        elements.append(ar)
    }
    
    open func finishCurrentElement() {
        guard var element = currentElement else {
            return
        }
        element.index = lastElementIndex + 1
        element.endTime = NSDate().timeIntervalSince1970 - referenceDate
        elements.append(element)
        currentElement = nil
    }
}
