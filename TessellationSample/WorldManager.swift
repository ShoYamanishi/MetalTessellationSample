import Foundation
import MetalKit
import SwiftUI
import ARKit

class WorldManager : ObservableObject, TouchMTKViewDelegate {

    var arCoordinator  : ARCoordinator?

    var device:                MTLDevice!
    var screenSize:            CGSize

    var viewMatrix:            float4x4
    var projectionMatrix:      float4x4
    var cameraTransformMatrix: float4x4

    var surfaceModelMatrix:    float4x4?
    var tessSurface:           TessellationMain

    @Published var tessellationFactor: Float = 10.0
    @Published var showWireFrame:      Bool  = false
    @Published var agitationIntensity: Float = 16

    public init( device : MTLDevice ) {

        self.device                = device
        self.screenSize            = CGSize( width: 0.0, height: 0.0 )
        self.viewMatrix            = matrix_identity_float4x4
        self.projectionMatrix      = matrix_identity_float4x4
        self.cameraTransformMatrix = matrix_identity_float4x4

        self.tessSurface       = TessellationMain(
            device     : device,
            gridWidth  : 40,
            gridHeight : 40,
            edgeLength : 0.2 // in meter
        )
    }

    func createPipelineStates( mtkView: MTKView ) {
        tessSurface.createRenderPipelineState(
            colorPixelFormat:        mtkView.colorPixelFormat,
            depthStencilPixelFormat: mtkView.depthStencilPixelFormat
        )
    }

    func updateScreenSizes( size: CGSize ) {
        screenSize = size
    }

    func updateCamera( viewMatrix: float4x4, projectionMatrix: float4x4, cameraTransformMatrix: float4x4 ) {

        var coordinateSpaceTransform = matrix_identity_float4x4

        // MARK: - Coordinate conversion
        // Flip the Z axis to convert geometry from right handed to left handed
        // ARKit uses the right-hand coordinate system, while Metal uses the left-hand coordinate system.
        coordinateSpaceTransform.columns.2.z = -1.0

        self.viewMatrix            = viewMatrix * coordinateSpaceTransform
        self.projectionMatrix      = projectionMatrix
        self.cameraTransformMatrix = cameraTransformMatrix
    }
   
    func updateWorld( surfaceModelMatrix: float4x4? ) {
        let down1m = float4x4( columns: (
            SIMD4<Float>( 1.0, 0.0, 0.0, 0.0 ),
            SIMD4<Float>( 0.0, 1.0, 0.0, 0.0 ),
            SIMD4<Float>( 0.0, 0.0, 1.0, 0.0 ),
            SIMD4<Float>( 0.0,-1.0, 0.0, 1.0 )
        ) )

        if let M = surfaceModelMatrix {
            self.surfaceModelMatrix = M * down1m
        }
        else {
            self.surfaceModelMatrix = nil
        }
    }
   
    func draw( in view: MTKView, commandBuffer: MTLCommandBuffer ) {

        let descriptor = view.currentRenderPassDescriptor

        // At this point, the image from the camera has been drawn to the drawable, and we should not clear it.
        let oldAction = descriptor!.colorAttachments[0].loadAction
        descriptor!.colorAttachments[0].loadAction = .load

        guard
            let encoder = commandBuffer.makeRenderCommandEncoder( descriptor: descriptor! )
        else {
            return
        }

        if let modelMatrix = self.surfaceModelMatrix {

            self.tessSurface.update(
                renderEncoder      : encoder,
                Mmodel             : modelMatrix,
                Mview              : self.viewMatrix,
                Mproj              : self.projectionMatrix,
                Mcamera            : self.cameraTransformMatrix,
                factorCoeff        : tessellationFactor,
                agitationIntensity : agitationIntensity,
                showWireFrame      : showWireFrame
            )
        }

        encoder.endEncoding()

        descriptor!.colorAttachments[0].loadAction = oldAction
    }

    func touchesBegan( location: CGPoint, size: CGRect ) {
        print ( "toutchesBegan at ( \(location.x), \(location.y) ).")
    }

    func touchesMoved( location: CGPoint, size: CGRect ) {
        print ( "toutchesMoved at ( \(location.x), \(location.y) ).")
    }

    func touchesEnded( location: CGPoint, size: CGRect ) {
        print ( "toutchesEnded at ( \(location.x), \(location.y) ).")
    }
}

