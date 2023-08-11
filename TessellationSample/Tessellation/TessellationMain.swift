import Foundation
import MetalKit

// B-Spline surface tessellation.
// Each patch consists of the following 4x4 sub-grid in (i,j)-integer coordinates.
// The center patch (quad) is geometrically subdivided/triangulated by the tessellator.
//
// CP:     control points
// EF[x] : Edge factor to sub-divide the center quad patch
// IF[x] : Interior factor to subdivide the edges of the center quad patch
//
//       j
//       ^
//       |    CP[12]  ---   CP[13]   ---   CP[14]   ---   Cp[15]
//       |
//       |      |             |              |              |
//       |      |             |              |              |
//       |      |             |              |              |
//       |                 uv(0,1)  EF[1]  uv(1,1)
//       |    CP[8]   ---   CP[9]==========CP[10]   ---   CP[11]
//       |                   ||  ^           ||
//       |      |            ||  |IF[1]      ||             |
//       |      |       EF[0]||  |           ||EF[2]        |
//       |      |            ||<-+--IF[0]--->||             |
//       |                   ||  v           ||
//       |    CP[4]   ---   CP[5]==========CP[6]    ---   CP[7]
//       |                 uv(0,0)  EF[3]  uv(1,0)
//       |      |             |              |              |
//       |      |             |              |              |
//       |      |             |              |              |
//       |
//       |    CP[0]   ---   CP[1]   ---    CP[2]    ---   CP[3]
//       |
//       +------------------------------------------------------> i

class TessellationMain {

    var render   : TessellationRender
    var factors  : TessellationFactors
    var animator : WaterSurfaceAnimator

    public init(
        device     : MTLDevice,
        gridWidth  : Int,
        gridHeight : Int,
        edgeLength : Float
    ) {
        render    = TessellationRender  ( device : device, width: gridWidth, height: gridHeight )
        factors   = TessellationFactors ( device : device, width: gridWidth, height: gridHeight )
        animator  = WaterSurfaceAnimator( device : device, width: gridWidth, height: gridHeight, edgeLength: edgeLength )

        render.setBufferTessellationFactors ( bufferTessellationFactors : factors.getBufferForFactors() )
        factors.setBufferControlPointIndices( bufferControlPointIndices : render.getBufferControlPointIndices() )
    }

    public func createRenderPipelineState( colorPixelFormat: MTLPixelFormat, depthStencilPixelFormat: MTLPixelFormat )
    {
        render.createRenderPipelineState( colorPixelFormat: colorPixelFormat, depthStencilPixelFormat:  depthStencilPixelFormat )
    }

    public func update(
        renderEncoder      : MTLRenderCommandEncoder,
        Mmodel             : matrix_float4x4,
        Mview              : matrix_float4x4,
        Mproj              : matrix_float4x4,
        Mcamera            : matrix_float4x4,
        factorCoeff        : Float,
        agitationIntensity : Float,
        showWireFrame      : Bool
    ) {
        var Lmodel  = Mmodel
        var Lview   = Mview
        var Lproj   = Mproj
        var Lcamera = Mcamera

        animator.update( agitationIntensity: agitationIntensity )

        factors.update(
            controlPoints : animator.getCurrentControlPointsBuffer(),
            Mmodel        : &Lmodel,
            Mview         : &Lview,
            factorCoeff   : factorCoeff
        )

        render.encode(
            encoder       : renderEncoder,
            controlPoints : animator.getCurrentControlPointsBuffer(),
            Mmodel        : &Lmodel,
            Mview         : &Lview,
            Mproj         : &Lproj,
            Mcamera       : &Lcamera,
            showWireFrame : showWireFrame
        )
    }
}
