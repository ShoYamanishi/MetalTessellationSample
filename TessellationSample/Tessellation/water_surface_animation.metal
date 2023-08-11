#include <metal_stdlib>
using namespace metal;

typedef struct _WaterSurfaceAnimationConfig {

    int32_t width;
    int32_t height;
    float   edge_length;
    float   coeff;
    float   decay;

} WaterSurfaceAnimationConfig;

kernel void water_surface_init(

    constant WaterSurfaceAnimationConfig&
                   config              [[ buffer( 0 ) ]],
    device float4* control_points_prev [[ buffer( 1 ) ]],
    device float4* control_points_cur  [[ buffer( 2 ) ]],
    device float4* control_points_new  [[ buffer( 3 ) ]],
    uint           tid                 [[ thread_position_in_grid ]]

) {
    const auto w = config.width;
    const auto h = config.height;

    const auto hw = static_cast<float>( w ) * 0.5f;
    const auto hh = static_cast<float>( h ) * 0.5f;

    const auto i = static_cast<float>( tid % w );
    const auto j = static_cast<float>( tid / w );

    if ( static_cast<int32_t>( tid ) < w * h ) {

        const float4 p{
            ( j - hh ) * config.edge_length, // secondary axis.
            0.0f,                            // height
            ( i - hw ) * config.edge_length, // primary axis.
            1.0f
        };

        control_points_prev[ tid ] = p;
        control_points_cur [ tid ] = p;
        control_points_new [ tid ] = p;
    }
}

kernel void water_surface_animate(

    constant WaterSurfaceAnimationConfig&
                         config              [[ buffer( 0 ) ]],
    device const float*  agitation           [[ buffer( 1 ) ]],
    device const float4* control_points_prev [[ buffer( 2 ) ]],
    device const float4* control_points_cur  [[ buffer( 3 ) ]],
    device float4*       control_points_new  [[ buffer( 4 ) ]],
    uint                 tid                 [[ thread_position_in_grid ]]

) {
    const auto w = config.width;
    const auto h = config.height;

    const int32_t i = tid % w;
    const int32_t j = tid / w;

    if ( static_cast<int32_t>( tid ) < w * h ) {

        const auto iC = j * w + i; // center
        const auto iN = clamp( j + 1, 0, h - 1 ) * w + i; // north
        const auto iS = clamp( j - 1, 0, h - 1 ) * w + i; // south
        const auto iE = j * w + clamp( i + 1, 0, w - 1 );  // east
        const auto iW = j * w + clamp( i - 1, 0, w - 1 );  // west

        const auto C = control_points_cur[ iC ].y + agitation[ iC ];
        const auto N = control_points_cur[ iN ].y + agitation[ iN ];
        const auto S = control_points_cur[ iS ].y + agitation[ iS ];
        const auto E = control_points_cur[ iE ].y + agitation[ iE ];
        const auto W = control_points_cur[ iW ].y + agitation[ iW ];

        const auto Cprev = control_points_prev[ iC ].y;

        control_points_new[ iC ].y = ( C * 2.0f + ( E + W + N + S - C * 4.0f ) * config.coeff - Cprev ) * config.decay;
    }
}

