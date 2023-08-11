#include <metal_stdlib>
using namespace metal;

typedef struct _TessellationConfig {

    int32_t num_patches;
    int32_t max_tessellation_factor;
    float   factor_coeff;

} TessellationConfig;

kernel void find_tessellation_factors(

    constant     TessellationConfig&
                           config                [[ buffer( 0 ) ]],
    constant     float4x4& M_model               [[ buffer( 1 ) ]],
    constant     float4x4& M_view                [[ buffer( 2 ) ]],
    device const float4*   control_points        [[ buffer( 3 ) ]],
    device const int32_t*  control_point_indices [[ buffer( 4 ) ]],
    device       MTLQuadTessellationFactorsHalf*
                           factors               [[ buffer( 5 ) ]],
    uint                   tid                   [[ thread_position_in_grid ]]

) {
    if ( static_cast<int32_t>( tid ) < config.num_patches ) {

        const auto Mvm = M_view * M_model;

        const int32_t control_point_indices_begin = tid * 16;
        const auto i_09 = control_point_indices[control_point_indices_begin +  9 ];
        const auto i_05 = control_point_indices[control_point_indices_begin +  5 ];
        const auto i_06 = control_point_indices[control_point_indices_begin +  6 ];
        const auto i_10 = control_point_indices[control_point_indices_begin + 10 ];

        const auto p_09_gcs = ( Mvm * control_points[ i_09 ] ).xyz;
        const auto p_05_gcs = ( Mvm * control_points[ i_05 ] ).xyz;
        const auto p_06_gcs = ( Mvm * control_points[ i_06 ] ).xyz;
        const auto p_10_gcs = ( Mvm * control_points[ i_10 ] ).xyz;

        const auto dist_09_05 = length( (p_09_gcs + p_05_gcs ) * 0.5f ); // edge factor [0]
        const auto dist_05_06 = length( (p_05_gcs + p_06_gcs ) * 0.5f ); // edge factor [1]
        const auto dist_06_10 = length( (p_06_gcs + p_10_gcs ) * 0.5f ); // edge factor [2]
        const auto dist_10_09 = length( (p_10_gcs + p_09_gcs ) * 0.5f ); // edge factor [3]

        const auto dist_avg = ( dist_09_05 + dist_05_06 + dist_06_10 + dist_10_09 ) / 4.0f;

        const auto F = static_cast<float>( config.max_tessellation_factor );

        factors[tid].edgeTessellationFactor[0] = min( F, max( 1.0f, F / ( dist_09_05 * config.factor_coeff ) ) );
        factors[tid].edgeTessellationFactor[1] = min( F, max( 1.0f, F / ( dist_05_06 * config.factor_coeff ) ) );
        factors[tid].edgeTessellationFactor[2] = min( F, max( 1.0f, F / ( dist_06_10 * config.factor_coeff ) ) );
        factors[tid].edgeTessellationFactor[3] = min( F, max( 1.0f, F / ( dist_10_09 * config.factor_coeff ) ) );

        factors[tid].insideTessellationFactor[0] = min( F, max( 1.0f, F / ( dist_avg * config.factor_coeff ) ) );
        factors[tid].insideTessellationFactor[1] = min( F, max( 1.0f, F / ( dist_avg * config.factor_coeff ) ) );
    }
}

