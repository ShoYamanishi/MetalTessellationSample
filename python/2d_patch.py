#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__    = "Shoichiro Yamanishi"
__copyright__ = "Copyright 2023, Shoichiro Yamanishi"
__license__   = "GPLv3"
__version__   = "1.0"

'''
This is a sample python code to illustrate the order-2 B-spline surface interpolation
for the surface point, uv-tangents, and the surface normal
The basis function is for the knots at the regular unit interval (0.0, 1.0, 2.0,...).
'''

import math
import numpy as np
import matplotlib.pyplot as plt

def N_Unit_Order2( k: int, t: float ) -> float:

    '''Basis function of order 2 (quadratic) at the unit interval.
       :param k: knot.
       :param t: input
       :returns: output       
    '''
    fk = float(k) + 0.5

    if fk - 2.0 <= t and t < fk - 1.0:

        return 0.5 * ( t - (fk - 2.0) ) * ( t - (fk - 2.0) )

    if fk - 1.0 <= t and t < fk:

        return -1.0 * ( t - (fk - 1.0) ) * ( t - (fk - 1.0) ) + ( t - (fk - 1.0)) + 0.5

    if fk <= t and t < fk + 1.0:

        return 0.5 * ( t - fk ) * ( t - fk ) - ( t - fk ) + 0.5

    return 0.0

def D_Unit_Order2( k: int, t: float ) -> float:

    '''1st derivative of the basis function: D(t) = (d/dt)N.
       :param k: knot.
       :param t: input
       :returns: output       
    '''

    fk = float(k) + 0.5

    if fk - 2.0 <= t and t < fk - 1.0:

        return 0.5 * 2.0 * ( t - (fk - 2.0) )

    if fk - 1.0 <= t and t < fk:

        return -1.0 * 2.0 * ( t - (fk - 1.0) )+ 1.0

    if fk <= t and t < fk + 1.0:

        return 0.5 * 2.0 * ( t - fk ) - 1.0

    return 0.0


def interpolate_NN_4_by_4( u: float, v: float, control_pts )-> float:

    '''Calculates Σj[ Σi[ N(u)·N(v) ] ] over all the control points in the grid.
       :param u:     input u
       :param v:     input v
       :control_pts: control points in the grid.
       :returns: output       
    '''

    sum = 0.0

    for j in range( 0, 4 ):

        for i in range( 0, 4 ):

            sum += N_Unit_Order2( i, u ) * N_Unit_Order2( j, v ) * control_pts[ j, i ] 

    return sum


def interpolate_DN_4_by_4( u: float, v: float, control_pts )-> float:

    '''Calculates Σj[ Σi[ d/du(N(u)) · N(v) ] ] over all the control points in the grid.
       :param u:     input u
       :param v:     input v
       :control_pts: control points in the grid.
       :returns: output       
    '''

    sum = 0.0

    for j in range( 0, 4 ):

        for i in range( 0, 4 ):

            sum += D_Unit_Order2( i, u ) * N_Unit_Order2( j, v ) * control_pts[ j, i ] 

    return sum


def interpolate_ND_4_by_4( u: float, v: float, control_pts )-> float:

    '''Calculates Σj[ Σi[ N(u) · d/dv(N(v)) ] ] over all the control points in the grid.
       :param u:     input u
       :param v:     input v
       :control_pts: control points in the grid.
       :returns: output       
    '''

    sum = 0.0

    for j in range( 0, 4 ):

        for i in range( 0, 4 ):

            sum += N_Unit_Order2( i, u ) * D_Unit_Order2( j, v ) * control_pts[ j, i ] 

    return sum

def sample_surface_point_in_patch( base : [float,float], num_samples_per_axis: int ):

    '''Sample the surface point from (u,v) by interpolation.
       :param base: the lower-left corner of the patch in uv-coordinates
       :param num_samples_per_axis:
       :returns: output sampled point (xyz) in 2d-grid(uv)
    '''

    patch_x = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    patch_y = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    patch_z = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )

    for j in range ( 0, num_samples_per_axis ):

        v = base[1] + float(j) / float( num_samples_per_axis - 1 )

        for i in range ( 0, num_samples_per_axis ):

            u = base[0] + float(i) / float( num_samples_per_axis - 1 )

            interpolated_x = interpolate_NN_4_by_4( u, v, control_pts_x )
            interpolated_y = interpolate_NN_4_by_4( u, v, control_pts_y )
            interpolated_z = interpolate_NN_4_by_4( u, v, control_pts_z )

            patch_x[i][j] = interpolated_x
            patch_y[i][j] = interpolated_y
            patch_z[i][j] = interpolated_z

    return ( patch_x, patch_y, patch_z )


def sample_surface_tangents_and_normal_in_patch( base : [float,float], num_samples_per_axis: int ):

    '''Sample the normal from (u,v) by interpolation.
       :param bas: the lower-left corner of the patch in uv-coordinates
       :param num_samples_per_axis:
       :returns: output sampled 3d-vector(xyz) in 2d-grid(uv)
    '''

    tangent_u_x = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    tangent_u_y = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    tangent_u_z = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )

    tangent_v_x = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    tangent_v_y = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    tangent_v_z = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )

    normal_x = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    normal_y = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )
    normal_z = np.zeros( ( num_samples_per_axis, num_samples_per_axis ) )

    for j in range ( 0, num_samples_per_axis ):

        v = base[1] + float(j) / float( num_samples_per_axis - 1 )

        for i in range ( 0, num_samples_per_axis ):

            u = base[0] + float(i) / float( num_samples_per_axis - 1 )

            interpolated_dx_du = interpolate_DN_4_by_4( u, v, control_pts_x )
            interpolated_dx_dv = interpolate_ND_4_by_4( u, v, control_pts_x )

            interpolated_dy_du = interpolate_DN_4_by_4( u, v, control_pts_y )
            interpolated_dy_dv = interpolate_ND_4_by_4( u, v, control_pts_y )

            interpolated_dz_du = interpolate_DN_4_by_4( u, v, control_pts_z )
            interpolated_dz_dv = interpolate_ND_4_by_4( u, v, control_pts_z )

            tangent_dp_du = [ interpolated_dx_du, interpolated_dy_du, interpolated_dz_du ]
            tangent_dp_dv = [ interpolated_dx_dv, interpolated_dy_dv, interpolated_dz_dv ]

            tangent_dp_du = tangent_dp_du / np.linalg.norm( tangent_dp_du )
            tangent_dp_dv = tangent_dp_dv / np.linalg.norm( tangent_dp_dv )

            normal = np.cross( tangent_dp_du, tangent_dp_dv )
            normal = normal /  np.linalg.norm( normal )

            tangent_u_x[i][j] = tangent_dp_du[0]
            tangent_u_y[i][j] = tangent_dp_du[1]
            tangent_u_z[i][j] = tangent_dp_du[2]

            tangent_v_x[i][j] = tangent_dp_dv[0]
            tangent_v_y[i][j] = tangent_dp_dv[1]
            tangent_v_z[i][j] = tangent_dp_dv[2]

            normal_x[i][j] = normal[0]
            normal_y[i][j] = normal[1]
            normal_z[i][j] = normal[2]
         
    return ( tangent_u_x, tangent_u_y, tangent_u_z ), ( tangent_v_x, tangent_v_y, tangent_v_z ), ( normal_x, normal_y, normal_z )

# uv-grids of 4-by-4 ( 16 quad patches )
# range of u : [0.0, 3.0]
# range of v : [0.0, 3.0]

# Creating dataset in 4x4 uv-grids
control_pts_x = np.array( [ [ 0, 10, 20, 30 ], [  0, 10, 20, 30 ], [  0, 10, 20, 30 ], [  0, 10, 20, 30 ] ] )
control_pts_y = np.array( [ [ 0,  0,  0,  0 ], [ 10, 10, 10, 10 ], [ 20, 20, 20, 20 ], [ 30, 30, 30, 30 ] ] )
control_pts_z = np.random.uniform( 0.0, 20.0, ( 4, 4 ) )

# Interpolated center patch in 11x11 uv-grids : (1.0, 1.0) - (2.0, 2.0) at step 0.1

patch_x,  patch_y,  patch_z  = sample_surface_point_in_patch ( base=[ 1.0, 1.0 ], num_samples_per_axis = 11 )

tangent_u, tangent_v, normal = sample_surface_tangents_and_normal_in_patch( base=[ 1.0, 1.0 ], num_samples_per_axis = 11 )
 
fig = plt.figure()
ax = plt.axes( projection ='3d' )

# draw the surface in the control patches
ax.plot_trisurf(
    np.reshape( control_pts_x, (-1) ),
    np.reshape( control_pts_y, (-1) ),
    np.reshape( control_pts_z, (-1) ),
    linewidth = 1.0,
    alpha = 0.3,
    antialiased = True
);

# draw the interpolated surface of the center patch
ax.plot_trisurf(
    np.reshape( patch_x, (-1) ),
    np.reshape( patch_y, (-1) ),
    np.reshape( patch_z, (-1) ),
    linewidth = 0.2,
    alpha = 0.8,
    antialiased = True
);

# draw the interpolated normals in the center patch
ax.quiver(
    np.reshape( patch_x,  (-1) ),
    np.reshape( patch_y,  (-1) ),
    np.reshape( patch_z,  (-1) ),
    np.reshape( normal[0], (-1) ),
    np.reshape( normal[1], (-1) ),
    np.reshape( normal[2], (-1) ),
    color='red'
)

# draw the interpolated tangents in the center patch
ax.quiver(
    np.reshape( patch_x,  (-1) ),
    np.reshape( patch_y,  (-1) ),
    np.reshape( patch_z,  (-1) ),
    np.reshape( tangent_u[0], (-1) ),
    np.reshape( tangent_u[1], (-1) ),
    np.reshape( tangent_u[2], (-1) ),
    color='green'
)

# draw the interpolated tangents in the center patch
ax.quiver(
    np.reshape( patch_x,  (-1) ),
    np.reshape( patch_y,  (-1) ),
    np.reshape( patch_z,  (-1) ),
    np.reshape( tangent_v[0], (-1) ),
    np.reshape( tangent_v[1], (-1) ),
    np.reshape( tangent_v[2], (-1) ),
    color='blue'
)

ax.set_box_aspect( (np.ptp(patch_x), np.ptp(patch_y), np.ptp(patch_z) ) )
 
# show plot
plt.show()
