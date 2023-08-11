#include <metal_stdlib>
using namespace metal;

typedef struct _ControlPoint {

    float4 pos [[ attribute(0) ]];

} ControlPoint;

typedef struct _VertexOut {

    float4 position       [[ position ]];
    float3 world_position;
    float3 normal;

} VertexOut;

// Unit basis function of order 2 adjusted such that the peak occurs at t = (float)k.
static float N_Unit_Order2( const int32_t k, const float t )
{
    const auto fk = static_cast<float>(k) + 0.5f;

    if ( fk - 2.0f <= t && t < fk - 1.0f ) {

        return 0.5f * ( t - ( fk - 2.0f ) ) * ( t - ( fk - 2.0f ) );
    }
    else if ( fk - 1.0f <= t && t < fk ) {

        return -1.0f * ( t - ( fk - 1.0f ) ) * ( t - ( fk - 1.0f ) ) + ( t - ( fk - 1.0f ) ) + 0.5f;
    }
    else if ( fk <= t and t < fk + 1.0f ) {

        return 0.5f * ( t - fk ) * ( t - fk ) - ( t - fk ) + 0.5f;
    }
    else {
       return 0.0f;
    }
}

// 1st derivative of the unit basis function of order 2
static float D_Unit_Order2( const int32_t k, const float t )
{
    const auto fk = static_cast<float>(k) + 0.5f;

    if ( fk - 2.0f <= t && t < fk - 1.0f ) {
        return 0.5f * 2.0f * ( t - ( fk - 2.0f ) );
    }
    else if ( fk - 1.0f <= t && t < fk ) {
        return -1.0f * 2.0f * ( t - ( fk - 1.0f ) )+ 1.0f;
    }
    else if ( fk <= t && t < fk + 1.0f ) {
        return 0.5f * 2.0f * ( t - fk ) - 1.0f;
    }
    else {
        return 0.0f;
    }
}

[[ patch( quad, 16 ) ]]
vertex VertexOut vertex_tessellation (

    patch_control_point<ControlPoint> control_points [[ stage_in ]],
    constant float4x4&                M_model        [[ buffer( 1 ) ]],
    constant float4x4&                M_view         [[ buffer( 2 ) ]],
    constant float4x4&                M_proj         [[ buffer( 3 ) ]],
    const    float2                   uv             [[ position_in_patch ]],
    const    uint                     patch_id       [[ patch_id ]] // not used
) {
    const auto u = 1.0f + uv.x; // [1.0 <= u <= 2.0] for the center patch
    const auto v = 1.0f + uv.y; // [1.0 <= v <= 2.0] for the center patch

    float3 P_interp { 0.0f, 0.0f, 0.0f };
    float3 T_u      { 0.0f, 0.0f, 0.0f };
    float3 T_v      { 0.0f, 0.0f, 0.0f };

    for ( int32_t j = 0; j < 4; j++ ) { // along j-axis

        const auto Nj = N_Unit_Order2( j, v );
        const auto Dj = D_Unit_Order2( j, v );

        for ( int32_t i = 0; i < 4; i++ ) { // along i-axis

            const auto Ni = N_Unit_Order2( i, u );
            const auto Di = D_Unit_Order2( i, u );

            const auto P_ij = control_points[ j * 4 + i ].pos.xyz;

            P_interp += ( P_ij * ( Ni * Nj ) );
            T_u      += ( P_ij * ( Di * Nj ) );
            T_v      += ( P_ij * ( Ni * Dj ) );
        }
    }

    const auto N_lcs = normalize( cross(T_u, T_v) );

    const auto N_gcs = M_model * float4( N_lcs,    0.0f );
    const auto P_gcs = M_model * float4( P_interp, 1.0f );

    return VertexOut {
        .position         = M_proj * M_view * P_gcs,
        .world_position   = P_gcs.xyz / P_gcs.w,
        .normal           = N_gcs.xyz
    };
}

fragment float4 fragment_tessellation(
    VertexOut          in       [[ stage_in  ]],
    constant float4x4& M_camera [[ buffer( 1 ) ]]
) {
    const float3 camera_gcs{ M_camera[3][0],  M_camera[3][1],  M_camera[3][2] };
    const float3 material_color{ 0.529f, 0.808f, 0.922f };// Skyblue

    const float  opacity{ 0.2f };

    const float3 light_direction{ 0.0f, -1.0f, 0.0f };

    // diffuse
    const auto cos_theta = dot( in.normal, light_direction * -1.0f );
    const auto diffuse_coeff = cos_theta * cos_theta; // hack to emphasize the surface gradient
    const auto diffuse_color = material_color * diffuse_coeff * 0.7f;

    // ambient
    const auto ambient_color = material_color * 0.3f;

    // specular
    const auto dir_vertex_to_camera = normalize( in.world_position - camera_gcs );
    const auto normal_reflected = reflect( light_direction, in.normal );
    const auto  cos_alpha = clamp( dot( normal_reflected, dir_vertex_to_camera ), 0.0f, 1.0f );
    const auto specular_color = material_color * cos_alpha;

    const auto color = saturate( diffuse_color + ambient_color + specular_color );
    return float4( color, 1.0f - opacity );
}
