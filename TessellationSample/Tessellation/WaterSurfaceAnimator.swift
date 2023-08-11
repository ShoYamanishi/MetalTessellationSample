import Foundation
import MetalKit

struct WaterSurfaceAnimationConfig {
    var width      : Int32
    var height     : Int32
    var edgeLength : Float
    var coeff      : Float
    var decay      : Float
}

class WaterSurfaceAnimator {

    let threadsPerGroup : Int = 512

    let metalFunctionNameInit   = "water_surface_init"
    let metalFunctionNameUpdate = "water_surface_animate"

    let device              : MTLDevice
    var pipelineStateInit   : MTLComputePipelineState?
    var pipelineStateUpdate : MTLComputePipelineState?

    var config     : WaterSurfaceAnimationConfig
    let width      : Int
    let height     : Int
    let edgeLength : Float

    var buffersControlPoints : [MTLBuffer] // [ SIMD4<Float> ] allocated internally
    var bufferAgitation      : MTLBuffer   // [ Float ] allocated internally

    var curIndex : Int // {0,1,2}

    public init( device : MTLDevice, width: Int, height: Int, edgeLength: Float ) {

        self.device     = device
        self.width      = width
        self.height     = height
        self.edgeLength = edgeLength

        self.config = WaterSurfaceAnimationConfig(
            width      : Int32(width),
            height     : Int32(height),
            edgeLength : edgeLength,
            coeff      : 0.2,
            decay      : 0.99
        )

        self.buffersControlPoints = []
        for _ in 0..<3 {
            let buf = device.makeBuffer(
                length:  MemoryLayout< SIMD4<Float> >.stride * width * height,
                options: .storageModePrivate
            )
            self.buffersControlPoints.append( buf! )
        }

        self.curIndex = 0

        self.bufferAgitation = device.makeBuffer(
            length:  MemoryLayout<Float>.stride * width * height,
            options: .storageModeShared
        )!
        
        createPipelineStates()
        
        initBuffers()
    }

    public func update( agitationIntensity : Float ) {
        
        agitateRandomly( agitationIntensity: agitationIntensity )

        animate()

        curIndex = ( curIndex + 1 ) % 3
    }

    public func getCurrentControlPointsBuffer() -> MTLBuffer {

        return buffersControlPoints[curIndex]
    }

    func createPipelineStates() {

        guard let library = device.makeDefaultLibrary()
        else {
            print ("cannot make default library")
            return
        }

        let pipelineDescriptorInit = MTLComputePipelineDescriptor()
        pipelineDescriptorInit.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        pipelineDescriptorInit.computeFunction = library.makeFunction( name: metalFunctionNameInit )

        do {
             pipelineStateInit = try device.makeComputePipelineState( descriptor: pipelineDescriptorInit, options: [], reflection: nil )
        } catch {
            print ("cannot make pipeline states")
            return
        }

        let pipelineDescriptorUpdate = MTLComputePipelineDescriptor()
        pipelineDescriptorUpdate.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        pipelineDescriptorUpdate.computeFunction = library.makeFunction( name: metalFunctionNameUpdate )

        do {
             pipelineStateUpdate = try device.makeComputePipelineState( descriptor: pipelineDescriptorUpdate, options: [], reflection: nil )
        } catch {
            print ("cannot make pipeline states")
            return
        }
    }

    func initBuffers()
    {
        let queue = self.device.makeCommandQueue()

        guard let commandBuffer = queue!.makeCommandBuffer() else {
            print ("cannot make command buffer")
            return
        }

        let encoder = commandBuffer.makeComputeCommandEncoder()

        encoder?.setComputePipelineState( pipelineStateInit! )

        encoder?.setBytes( &config, length: MemoryLayout<WaterSurfaceAnimationConfig>.stride, index: 0 )
        encoder?.setBuffer( buffersControlPoints[0], offset: 0, index: 1 )
        encoder?.setBuffer( buffersControlPoints[1], offset: 0, index: 2 )
        encoder?.setBuffer( buffersControlPoints[2], offset: 0, index: 3 )

        let numThreads = width * height
        let threadConfig = getThreadConfiguration( numThreads : Int(numThreads) )
    
        encoder?.dispatchThreadgroups(
            MTLSizeMake( threadConfig.numGroupsPerGrid, 1, 1 ),
            threadsPerThreadgroup: MTLSizeMake( threadConfig.numThreadsPerGroup, 1, 1 )
        )

        encoder?.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func agitateRandomly( agitationIntensity : Float ) {

        var arr: [Float] = [Float]( repeating: 0.0, count: width * height )

        if Float.random( in: 0.0..<200.0 ) < agitationIntensity {

            let i = Int.random( in: 0..<width  )
            let j = Int.random( in: 0..<height )
            let maxOffset = agitationIntensity * 0.1 * edgeLength
            arr[ j * width + i ] += Float.random( in: -1.0 * maxOffset..<1.0 * maxOffset )
        }
        bufferAgitation.contents().copyMemory( from: arr, byteCount: MemoryLayout<Float>.stride * height * width )
    }

    func animate() {

        let queue = self.device.makeCommandQueue()

        guard let commandBuffer = queue!.makeCommandBuffer() else {
            print ("cannot make command buffer")
            return
        }

        let encoder = commandBuffer.makeComputeCommandEncoder()

        encoder?.setComputePipelineState( pipelineStateUpdate! )

        encoder?.setBytes( &config, length: MemoryLayout<WaterSurfaceAnimationConfig>.stride, index: 0 )
        encoder?.setBuffer( bufferAgitation, offset: 0, index: 1 )
        encoder?.setBuffer( buffersControlPoints[ (curIndex + 2) % 3 ], offset: 0, index: 2 )
        encoder?.setBuffer( buffersControlPoints[ curIndex           ], offset: 0, index: 3 )
        encoder?.setBuffer( buffersControlPoints[ (curIndex + 1) % 3 ], offset: 0, index: 4 )

        let numThreads = width * height
        let threadConfig = getThreadConfiguration( numThreads : Int(numThreads) )
    
        encoder?.dispatchThreadgroups(
            MTLSizeMake( threadConfig.numGroupsPerGrid, 1, 1 ),
            threadsPerThreadgroup: MTLSizeMake( threadConfig.numThreadsPerGroup, 1, 1 )
        )

        encoder?.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
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
