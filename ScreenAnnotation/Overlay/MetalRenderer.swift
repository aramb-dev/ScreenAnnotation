import Foundation
import MetalKit
import simd

struct StrokeVertex {
    var position: SIMD2<Float>
    var color: SIMD4<Float>
    var thickness: Float
    var opacity: Float
    var texCoord: SIMD2<Float>
}

struct Uniforms {
    var viewportSize: SIMD2<Float>
}

class MetalRenderer: NSObject, MTKViewDelegate {
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var highlighterPipelineState: MTLRenderPipelineState?
    private var pencilPipelineState: MTLRenderPipelineState?
    private var crayonPipelineState: MTLRenderPipelineState?
    private var watercolorPipelineState: MTLRenderPipelineState?
    private var calligraphyPipelineState: MTLRenderPipelineState?
    private var laserPointerPipelineState: MTLRenderPipelineState?
    weak var canvasManager: CanvasManager?
    
    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        buildPipelines(pixelFormat: pixelFormat)
    }
    
    private func buildPipelines(pixelFormat: MTLPixelFormat) {
        guard let library = device.makeDefaultLibrary() else {
            print("[MetalRenderer] Failed to load default Metal library")
            return
        }
        
        // Standard stroke pipeline (alpha blending)
        let vertexFunction = library.makeFunction(name: "strokeVertexShader")
        let fragmentFunction = library.makeFunction(name: "strokeFragmentShader")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        // Alpha blending
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("[MetalRenderer] Failed to create pipeline state: \(error)")
        }
        
        // Highlighter pipeline (multiply blend for translucent effect)
        let highlighterDescriptor = MTLRenderPipelineDescriptor()
        highlighterDescriptor.vertexFunction = vertexFunction
        highlighterDescriptor.fragmentFunction = library.makeFunction(name: "highlighterFragmentShader")
        highlighterDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        highlighterDescriptor.colorAttachments[0].isBlendingEnabled = true
        highlighterDescriptor.colorAttachments[0].rgbBlendOperation = .add
        highlighterDescriptor.colorAttachments[0].alphaBlendOperation = .add
        highlighterDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        highlighterDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        highlighterDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .zero
        highlighterDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        
        do {
            highlighterPipelineState = try device.makeRenderPipelineState(descriptor: highlighterDescriptor)
        } catch {
            print("[MetalRenderer] Failed to create highlighter pipeline: \(error)")
        }

        // Pencil pipeline
        pencilPipelineState = buildStandardBlendPipeline(
            vertexFunction: vertexFunction,
            fragmentName: "pencilFragmentShader",
            library: library,
            pixelFormat: pixelFormat
        )

        // Crayon pipeline
        crayonPipelineState = buildStandardBlendPipeline(
            vertexFunction: vertexFunction,
            fragmentName: "crayonFragmentShader",
            library: library,
            pixelFormat: pixelFormat
        )

        // Watercolor pipeline
        watercolorPipelineState = buildStandardBlendPipeline(
            vertexFunction: vertexFunction,
            fragmentName: "watercolorFragmentShader",
            library: library,
            pixelFormat: pixelFormat
        )

        // Calligraphy pipeline
        calligraphyPipelineState = buildStandardBlendPipeline(
            vertexFunction: vertexFunction,
            fragmentName: "calligraphyFragmentShader",
            library: library,
            pixelFormat: pixelFormat
        )

        // Laser pointer pipeline
        laserPointerPipelineState = buildStandardBlendPipeline(
            vertexFunction: vertexFunction,
            fragmentName: "laserPointerFragmentShader",
            library: library,
            pixelFormat: pixelFormat
        )
    }

    private func buildStandardBlendPipeline(
        vertexFunction: MTLFunction?,
        fragmentName: String,
        library: MTLLibrary,
        pixelFormat: MTLPixelFormat
    ) -> MTLRenderPipelineState? {
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexFunction
        desc.fragmentFunction = library.makeFunction(name: fragmentName)
        desc.colorAttachments[0].pixelFormat = pixelFormat
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].rgbBlendOperation = .add
        desc.colorAttachments[0].alphaBlendOperation = .add
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .one
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        do {
            return try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            print("[MetalRenderer] Failed to create \(fragmentName) pipeline: \(error)")
            return nil
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let canvasManager = canvasManager,
              let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }
        
        // Clear to transparent
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        // Use bounds (points), not drawableSize (pixels), so coordinates match AppKit mouse events.
        let viewportSize = SIMD2<Float>(Float(view.bounds.width), Float(view.bounds.height))
        var uniforms = Uniforms(viewportSize: viewportSize)
        
        // Render all strokes
        let strokes = canvasManager.allStrokes
        
        for stroke in strokes {
            guard stroke.points.count >= 2 else { continue }
            
            let vertices = buildTriangleStrip(for: stroke, viewportSize: viewportSize)
            guard !vertices.isEmpty else { continue }
            
            let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<StrokeVertex>.stride,
                options: .storageModeShared
            )
            
            // Choose pipeline based on pen type
            let selectedPipeline: MTLRenderPipelineState
            switch stroke.penType {
            case .highlighter:
                selectedPipeline = highlighterPipelineState ?? pipelineState
            case .pencil:
                selectedPipeline = pencilPipelineState ?? pipelineState
            case .crayon:
                selectedPipeline = crayonPipelineState ?? pipelineState
            case .watercolor:
                selectedPipeline = watercolorPipelineState ?? pipelineState
            case .calligraphy:
                selectedPipeline = calligraphyPipelineState ?? pipelineState
            case .laserPointer:
                selectedPipeline = laserPointerPipelineState ?? pipelineState
            default:
                selectedPipeline = pipelineState
            }
            encoder.setRenderPipelineState(selectedPipeline)
            
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Triangle Strip Generation
    
    private func buildTriangleStrip(for stroke: Stroke, viewportSize: SIMD2<Float>) -> [StrokeVertex] {
        let points = stroke.smoothedPoints.isEmpty ? stroke.points : stroke.smoothedPoints
        guard points.count >= 2 else { return [] }
        
        var vertices: [StrokeVertex] = []
        let color = stroke.color
        let baseWidth = stroke.width
        
        for i in 0..<points.count {
            let p = points[i]
            let pressure = CGFloat(p.pressure)
            let width = baseWidth * stroke.penType.widthMultiplier(pressure: pressure)
            
            // Compute perpendicular direction
            let direction: SIMD2<Float>
            if i == 0 {
                direction = normalize(SIMD2<Float>(
                    Float(points[1].position.x - p.position.x),
                    Float(points[1].position.y - p.position.y)
                ))
            } else if i == points.count - 1 {
                direction = normalize(SIMD2<Float>(
                    Float(p.position.x - points[i-1].position.x),
                    Float(p.position.y - points[i-1].position.y)
                ))
            } else {
                direction = normalize(SIMD2<Float>(
                    Float(points[i+1].position.x - points[i-1].position.x),
                    Float(points[i+1].position.y - points[i-1].position.y)
                ))
            }
            
            let perp = SIMD2<Float>(-direction.y, direction.x)
            let halfWidth = Float(width) / 2.0
            
            // Convert AppKit point coords (Y=0 at bottom) to Metal NDC (Y=+1 at top).
            // X: [0, width]  → [-1, +1]
            // Y: [0, height] → [+1, -1]  (flipped because Metal Y-axis is top-down)
            let posNDC = SIMD2<Float>(
                Float(p.position.x) / viewportSize.x * 2.0 - 1.0,
                1.0 - Float(p.position.y) / viewportSize.y * 2.0
            )
            
            let perpNDC = SIMD2<Float>(
                perp.x / viewportSize.x * 2.0,
                -(perp.y / viewportSize.y * 2.0)  // negate Y to match flipped coordinate system
            )
            
            let opacity = Float(stroke.penType.opacity(pressure: pressure) * stroke.opacity)
            let colorVec = SIMD4<Float>(
                Float(color.redComponent),
                Float(color.greenComponent),
                Float(color.blueComponent),
                Float(color.alphaComponent) * opacity
            )
            
            let texY = Float(i) / Float(points.count - 1)
            
            vertices.append(StrokeVertex(
                position: posNDC + perpNDC * halfWidth,
                color: colorVec,
                thickness: Float(width),
                opacity: opacity,
                texCoord: SIMD2<Float>(0, texY)
            ))
            
            vertices.append(StrokeVertex(
                position: posNDC - perpNDC * halfWidth,
                color: colorVec,
                thickness: Float(width),
                opacity: opacity,
                texCoord: SIMD2<Float>(1, texY)
            ))
        }
        
        return vertices
    }
}
