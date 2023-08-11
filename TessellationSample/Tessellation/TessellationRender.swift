import Foundation
import MetalKit

class TessellationRender {

    let maxNumTessellationFactor    : Int = 64
    let threadsPerGroup             : Int = 512
    let functionNameVertex   = "vertex_tessellation"
    let functionNameFragment = "fragment_tessellation"

    let device                      : MTLDevice
    var bufferIndirectArguments     : MTLBuffer! // [ MTLDrawPatchIndirectArguments ] allocated internally, set static
    var bufferTessellationFactors   : MTLBuffer! // [ HalfFloat[6] ] given externally
    var bufferControlPoints         : MTLBuffer! // [ SIMD4<Float> ] given externally
    var bufferControlPointIndices   : MTLBuffer! // [ Int32 ] allocated internally

    var pipelineState               : MTLRenderPipelineState?
    var depthStencilState           : MTLDepthStencilState?

    public init( device : MTLDevice, width: Int, height: Int ) {
   
        self.device = device
        buildDepthStencilState()

        var indices = TessellationRender.makeTessellationIndices( width: width, height: height )
        bufferControlPointIndices = device.makeBuffer(
            bytes:   &indices,
            length:  MemoryLayout<Int32>.stride * indices.count,
            options: .storageModeShared
        )

        let numPatches = indices.count / 16

        var indirectArguments = MTLDrawPatchIndirectArguments(
            patchCount:    UInt32(numPatches),
            instanceCount: 1,
            patchStart:    0,
            baseInstance:  0
        )

        bufferIndirectArguments = device.makeBuffer(
            bytes:   &indirectArguments,
            length:  MemoryLayout<MTLDrawPatchIndirectArguments>.stride,
            options: .storageModeShared
        )
    }

    public func getBufferControlPointIndices() -> MTLBuffer {
        return self.bufferControlPointIndices
    }

    public func setBufferTessellationFactors(
        bufferTessellationFactors : MTLBuffer
    ) {
        self.bufferTessellationFactors = bufferTessellationFactors
    }

    public func setBufferControlPoints(
        bufferControlPoints       : MTLBuffer
    ) {
        self.bufferControlPoints       = bufferControlPoints
    }

    public func createRenderPipelineState( colorPixelFormat: MTLPixelFormat, depthStencilPixelFormat: MTLPixelFormat )
    {
        let library = device.makeDefaultLibrary()

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction   = library!.makeFunction( name: functionNameVertex   )
        pipelineDescriptor.fragmentFunction = library!.makeFunction( name: functionNameFragment )
    
        // set up vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format      = .float4
        vertexDescriptor.attributes[0].offset      = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride       = MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint

        pipelineDescriptor.vertexDescriptor                  = vertexDescriptor
        pipelineDescriptor.tessellationFactorStepFunction    = .perPatch
        pipelineDescriptor.maxTessellationFactor             = maxNumTessellationFactor
        pipelineDescriptor.tessellationPartitionMode         = .pow2
        pipelineDescriptor.tessellationOutputWindingOrder    = .counterClockwise
        pipelineDescriptor.tessellationControlPointIndexType = .uint32
        pipelineDescriptor.colorAttachments[0].pixelFormat   = colorPixelFormat

        pipelineDescriptor.colorAttachments[0].isBlendingEnabled         = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation         = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor      = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        pipelineDescriptor.depthAttachmentPixelFormat = depthStencilPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState( descriptor: pipelineDescriptor )
        } catch let error {
            fatalError( error.localizedDescription )
        }
    }

    public func encode(
        encoder       : MTLRenderCommandEncoder,
        controlPoints : MTLBuffer,
        Mmodel        : inout matrix_float4x4,
        Mview         : inout matrix_float4x4,
        Mproj         : inout matrix_float4x4,
        Mcamera       : inout matrix_float4x4,
        showWireFrame : Bool
    ) {
        if showWireFrame {
            encoder.setTriangleFillMode( .lines )
        }
        encoder.setRenderPipelineState( pipelineState! )
        encoder.setDepthStencilState( depthStencilState )
        encoder.setTessellationFactorBuffer( bufferTessellationFactors, offset: 0, instanceStride: 0)
        encoder.setVertexBuffer( controlPoints, offset: 0, index: 0 )
        encoder.setVertexBytes( &Mmodel, length: MemoryLayout<matrix_float4x4>.stride, index: 1 )
        encoder.setVertexBytes( &Mview,  length: MemoryLayout<matrix_float4x4>.stride, index: 2 )
        encoder.setVertexBytes( &Mproj,  length: MemoryLayout<matrix_float4x4>.stride, index: 3 )
        encoder.setFragmentBytes( &Mcamera, length: MemoryLayout<matrix_float4x4>.stride, index: 1 )
        encoder.drawIndexedPatches(
            numberOfPatchControlPoints:    16,
            patchIndexBuffer:              nil,
            patchIndexBufferOffset:        0,
            controlPointIndexBuffer:       bufferControlPointIndices,
            controlPointIndexBufferOffset: 0,
            indirectBuffer:                bufferIndirectArguments,
            indirectBufferOffset:          0
        )
        if showWireFrame {
            encoder.setTriangleFillMode( .fill )
        }
    }

    func buildDepthStencilState() {

        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled  = true
        depthStencilState = device.makeDepthStencilState( descriptor: descriptor )!
    }
    
    
    static func makeTessellationIndices( width: Int, height: Int ) -> [Int32]
    {
        var indices : [Int32] = []

        for y in 0 ..< height - 3 {

            for x in 0 ..< width - 3 {

                for j in 0 ..< 4 {

                    for i in 0 ..< 4 {

                        indices.append( Int32( ( y + j ) * width + x + i ) )
                    }
                }
            }
        }
        return indices
    }
}
