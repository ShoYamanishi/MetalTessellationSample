import Foundation
import MetalKit

struct TessellationConfig {
    var numPatches             : Int32 // Number of the patches to be sent to the render pipeline. 16 * numPatches = numControlPointIndices
    var maxTessellationFactor  : Int32 // Max number of splits (subpatches) along both axes to generate vertices from one patch.
    var factorCoeff            : Float // Default 1.0, the greater the value is, the coarser the patch becomes.
}

class TessellationFactors {

    let maxNumTessellationFactor    : Int = 64
    let threadsPerGroup             : Int = 512
    let metalFunctionName = "find_tessellation_factors"
    let device                      : MTLDevice
    var config                      : TessellationConfig
    var bufferTessellationFactors   : MTLBuffer! // [ HalfFloat[6] ] allocated internally
    var bufferControlPoints         : MTLBuffer! // [ SIMD4<Float> ] given externally
    var bufferControlPointIndices   : MTLBuffer! // [ Int32 ] given externally
    var pipelineState               : MTLComputePipelineState?

    public init( device : MTLDevice, width: Int, height: Int ) {
   
        let numPatches = (width - 3) * (height - 3)
   
        self.device = device
        self.config = TessellationConfig(
            numPatches             : Int32(numPatches),
            maxTessellationFactor  : Int32(maxNumTessellationFactor),
            factorCoeff            : 2.0
        )

        self.bufferTessellationFactors = device.makeBuffer(
            length:  MemoryLayout<Float>.stride * 6 / 2 * numPatches,
            options: .storageModeShared
        )

        createComputePipelineStates()
    }

    public func getBufferForFactors() -> MTLBuffer {
        return bufferTessellationFactors
    }

    public func setBufferControlPointIndices( bufferControlPointIndices : MTLBuffer ) {
        self.bufferControlPointIndices = bufferControlPointIndices
    }

    public func setBufferControlPoints( bufferControlPoints : MTLBuffer ) {
        self.bufferControlPoints = bufferControlPoints
    }

    public func update(
        controlPoints : MTLBuffer,
        Mmodel        : inout matrix_float4x4,
        Mview         : inout matrix_float4x4,
        factorCoeff   : Float
    ) {
        let queue = self.device.makeCommandQueue()

        guard let commandBuffer = queue!.makeCommandBuffer() else {
            print ("cannot make command buffer")
            return
        }

        let encoder = commandBuffer.makeComputeCommandEncoder()
        config.factorCoeff = factorCoeff

        encoder?.setComputePipelineState( pipelineState! )

        encoder?.setBytes( &config, length: MemoryLayout<TessellationConfig>.stride, index: 0 )
        encoder?.setBytes( &Mmodel, length: MemoryLayout<matrix_float4x4>.stride,    index: 1 )
        encoder?.setBytes( &Mview,  length: MemoryLayout<matrix_float4x4>.stride,    index: 2 )

        encoder?.setBuffer( controlPoints,             offset: 0, index: 3 )
        encoder?.setBuffer( bufferControlPointIndices, offset: 0, index: 4 )
        encoder?.setBuffer( bufferTessellationFactors, offset: 0, index: 5 )

        let numThreads = config.numPatches
        let threadConfig = getThreadConfiguration( numThreads : Int(numThreads) )
    
        encoder?.dispatchThreadgroups(
            MTLSizeMake( threadConfig.numGroupsPerGrid, 1, 1 ),
            threadsPerThreadgroup: MTLSizeMake( threadConfig.numThreadsPerGroup, 1, 1 )
        )

        encoder?.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func createComputePipelineStates() {

        guard let library = device.makeDefaultLibrary()
        else {
            print ("cannot make default library")
            return
        }

        let pipelineDescriptor = MTLComputePipelineDescriptor()
        pipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        pipelineDescriptor.computeFunction = library.makeFunction( name: metalFunctionName )

        do {
             pipelineState = try device.makeComputePipelineState( descriptor: pipelineDescriptor, options: [], reflection: nil )
        } catch {
            print ("cannot make pipeline states")
            return
        }
    }

    func getThreadConfiguration( numThreads : Int )
    
        -> (numGroupsPerGrid : Int, numThreadsPerGroup : Int)
    {
        let numThreadsAligned32 = Int( ((numThreads + 31) / 32) * 32 )
        let numThreadsPerGroup  = Int( (numThreadsAligned32 < threadsPerGroup) ? numThreadsAligned32 : threadsPerGroup )
        let numGroupsPerGrid    = Int( ( numThreadsAligned32 + threadsPerGroup - 1) / threadsPerGroup )

        return ( numGroupsPerGrid : numGroupsPerGrid, numThreadsPerGroup : numThreadsPerGroup )
    }

}
