import Foundation
import MetalKit
import ARKit

class ARCoordinator: NSObject, MTKViewDelegate, ARSessionDelegate {

    var arSession:                  ARSession!

    var device:                     MTLDevice!
    var renderSemaphore:            DispatchSemaphore
    var commandQueue:               MTLCommandQueue!

    var previousFrameSize:          CGSize // to detect screen dimension change. SwiftUI does not always call mtkView().
    var viewportSize:               CGSize // current viewport size

    let worldManager:               WorldManager
    let photoImageRenderer:         PhotoImageRenderer

    var surfaceTransform:           matrix_float4x4?

    init( worldManager: WorldManager, device : MTLDevice ) {

        self.device             = worldManager.device
        self.renderSemaphore    = DispatchSemaphore( value: 1 )

        guard let commandQueue = device.makeCommandQueue()
        else {
            fatalError("GPU not available")
        }
        self.commandQueue       = commandQueue
        self.worldManager       = worldManager
        self.photoImageRenderer = PhotoImageRenderer( device: device )
        self.previousFrameSize  = CGSize( width: 0.0, height: 0.0 )
        self.viewportSize       = CGSize()

        super.init()

        arSession = ARSession()
        arSession.delegate = self
    }

    /// 2nd part of init. It must wait until device and the pixel format become available in MTKView
    func createPipelineStates( mtkView: MTKView ) {
        worldManager.createPipelineStates( mtkView: mtkView )
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize ) {

        let sizeInPixels = CGSize( width: size.width * view.contentScaleFactor,  height: size.height * view.contentScaleFactor )

        worldManager.updateScreenSizes( size: sizeInPixels )

        photoImageRenderer.arrangeMetalForCameraImage( view: view )

        let arConfiguration = ARWorldTrackingConfiguration()

        arConfiguration.planeDetection = [ .horizontal ]
        // Run the view's session
        arSession.run( arConfiguration )
    }

    func draw( in view: MTKView ) {

        // Update the world

        guard let currentFrame = arSession.currentFrame else {
            return
        }

        guard let drawable = view.currentDrawable
        else {
            return
        }

        // Draw the background camera image.

        if previousFrameSize != view.frame.size  {

            viewportSize = view.frame.size
            previousFrameSize  = view.frame.size
            self.mtkView( view, drawableSizeWillChange: view.frame.size )
            photoImageRenderer.updateImagePlane(frame: currentFrame, viewportSize : viewportSize )
        }

        photoImageRenderer.updateCapturedImageTextures( frame: currentFrame )

        // Handle one detected surface
        // Once one surface has been detected, retain it as long as the session stays normal.
        if arSession.currentFrame?.camera.trackingState != .normal {

            if surfaceTransform != nil {
                surfaceTransform = nil
                print( "Surface lost.")
            }
            return
        }

        if surfaceTransform == nil {

            for anchor in arSession.currentFrame!.anchors {

                if let planeAnchor = anchor as? ARPlaneAnchor {
                    surfaceTransform = planeAnchor.transform
                    print( "Surfarce discovered.")
                    print( "Surfarce Transform Matrix:")
                    print ( printMatrix( M : surfaceTransform! ) )
                    break
                }
            }
        }

        // MARK: - Device Orientation
        let V = arSession.currentFrame!.camera.viewMatrix( for: .portrait )
        let P = arSession.currentFrame!.camera.projectionMatrix( for: .portrait, viewportSize: viewportSize, zNear: 0.001, zFar: 10000.0 )
        let T = arSession.currentFrame!.camera.transform
        worldManager.updateCamera( viewMatrix: V, projectionMatrix: P, cameraTransformMatrix: T )
        worldManager.updateWorld( surfaceModelMatrix: surfaceTransform )
        // render the world

        guard
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        commandBuffer.addCompletedHandler { _ in self.renderSemaphore.signal() }
        renderSemaphore.wait()

        photoImageRenderer.draw( in : view,  commandBuffer: commandBuffer )

        worldManager.draw( in : view, commandBuffer: commandBuffer )

        commandBuffer.present( drawable )
        commandBuffer.commit()
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame){
    
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
    
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]){
    
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]){
    
    }
}


