//
//  Document.swift
//  MaLiang
//
//  Created by Harley.xk on 2018/4/24.
//

import Foundation
import CoreGraphics

/// base infomation for saved documents
public struct DocumentInfo: Codable {
    
    /// default infomation read form info.plist
    public static let `default` = DocumentInfo()
    
    /// identifier for this file
    public var identifier: String?
    
    /// format version of this document, equal to the library version
    public let version: String
    
    /// the app whitch uses MaLiang to generate this file
    public let app: BundleInfo?
    
    /// library info of MaLiang used in current app
    public let library: BundleInfo?
    
    /// number of lines in document
    public var lines: Int = 0
    
    /// number of chartlets in document
    public var chartlets: Int = 0
    
    /// number of custom textures used for chartlets and so on
    public var textures: Int = 0
    
    /// initialize a document info with specified identifier, an uuid will be used if passed nil
    public init(identifier: String? = nil) {
        self.identifier = identifier ?? UUID().uuidString
        library = try? Bundle(for: Canvas.classForCoder()).readInfo()
        app = try? Bundle.main.readInfo()
        version = library?.version ?? "unknown"
    }
}

/// contents' vector data on the canvas
public struct CanvasContent: Codable {
    
    /// content size of canvas
    public var size: CGSize?
    
    /// all linestrips
    public var lineStrips: [LineStrip] = []
    
    /// chatlets
    public var chartlets: [Chartlet] = []
    
    public init(size: CGSize?, lineStrips: [LineStrip], chartlets: [Chartlet]) {
        self.size = size
        self.lineStrips = lineStrips
        self.chartlets = chartlets
    }
}

/// contents' vector data on the canvas
public struct LessonContent: Codable {
    
    /// content size of canvas
    public var size: CGSize?
    
    /// all linestrips
    public var lineStrips: [LineStrip] = []
    public var buttonPresses: [CanvasButtonPress] = []
    public var colorChanges: [CanvasColorChange] = []
    public var valueChanges: [CanvasValueChange] = []
    public var referenceResizes: [CanvasReferenceResize] = []
    public var canvasTransforms: [CanvasTransformEvent] = []
    public var canvasDrags: [CanvasDragEvent] = []
    public var audioRecordings: [CanvasAudioRecording] = []
    public var addReferences: [CanvasAddReference] = []
    public var canvasColorSamples: [CanvasColorSamplerEvent] = []
    
    
    public var drawSessions: [StartOrStopAction] = []
    
    public init(size: CGSize?, lineStrips: [LineStrip], buttonPresses: [CanvasButtonPress], drawSessions: [StartOrStopAction],
                colorChanges: [CanvasColorChange], valueChanges: [CanvasValueChange],
                referenceResizes: [CanvasReferenceResize], canvasTransforms: [CanvasTransformEvent], canvasDrags: [CanvasDragEvent],
                audioRecordings: [CanvasAudioRecording], addReferences: [CanvasAddReference],
                canvasColorSamples: [CanvasColorSamplerEvent]) {
        self.size = size
        self.lineStrips = lineStrips
        self.buttonPresses = buttonPresses
        self.drawSessions = drawSessions
        self.colorChanges = colorChanges
        self.valueChanges = valueChanges
        self.referenceResizes = referenceResizes
        self.canvasTransforms = canvasTransforms
        self.canvasDrags = canvasDrags
        self.audioRecordings = audioRecordings
        self.addReferences = addReferences
        self.canvasColorSamples = canvasColorSamples
    }
}

/// base infomation for bundle from info.plist
public struct BundleInfo: Codable {
    public var name: String
    public var version: String
    public var identifier: String
}

extension Bundle {
    /// read base infomation from info.plist
    func readInfo() throws -> BundleInfo {
        guard let file = url(forResource: "Info", withExtension: "plist") else {
            throw MLError.fileNotExists("Info.plist")
        }
        let data = try Data(contentsOf: file)
        let info = try PropertyListDecoder().decode(__Info.self, from: data)
        return info.makePublic()
    }
    
    private struct __Info: Codable {
        var name: String
        var version: String
        var identifier: String
        
        enum CodingKeys: String, CodingKey {
            case name = "CFBundleName"
            case version = "CFBundleShortVersionString"
            case identifier = "CFBundleIdentifier"
        }
        
        func makePublic() -> BundleInfo {
            return BundleInfo(name: name, version: version, identifier: identifier)
        }
    }
}
