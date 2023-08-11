import matplotlib.pyplot as plt
import random

__author__    = "Shoichiro Yamanishi"
__copyright__ = "Copyright 2023, Shoichiro Yamanishi"
__license__   = "GPLv3"
__version__   = "1.0"

'''
This is a sample python code to illustrate the order-2 B-spline basis functions 
at the regular unit interval (..., -2.0, -1.0, 0.0, 1.0, 2.0, ... )
'''

def N_order2_unit( k : int, u : float) -> float:

    '''Basis function of order 2.
       :param k: knot index.
       :param x: input
       :returns: output       
    '''

    fk = float(k) + 0.5

    if fk - 2.0 <= u and u < fk - 1.0:
        return 0.5 * ( u - (fk - 2.0) ) * ( u - (fk - 2.0) )

    if fk - 1.0 <= u and u < fk:
        return -1.0 * ( u - (fk - 1.0) ) * ( u - (fk - 1.0) ) + ( u - (fk - 1.0)) + 0.5

    if fk <= u and u < fk + 1.0:
        return 0.5 * ( u - fk ) * ( u - fk ) - ( u - fk ) + 0.5

    return 0.0


def D_order2_unit( k : int, u : float ) -> float:

    '''1st derivative of the basis function of order 2.
       :param k: knot index.
       :param u: input
       :returns: output       
    '''

    fk = float(k) + 0.5

    if fk - 2.0 <= u and u < fk - 1.0:
        return u - (fk - 2.0)

    if fk - 1.0 <= u and u < fk:
        return -2.0 * ( u - (fk - 1.0) ) + 1.0

    if fk <= u and u < fk + 1.0:
        return u - fk  - 1.0

    return 0.0

def interpolate_N_order2_unit( points : [float], x : float ) -> float:

    sum = 0.0

    for k in range( -10, 10 ):
        sum += N_order2_unit( k, x )* points[ k + 10 ]

    return sum

def plot_one_basis_func( ax, knot_index ):

    xs = []
    ys = []

    for i in range(-1000,1001):

        # -10.0 <= x <= 10.0
        x = float(i) / 100.0 
        y = N_order2_unit( knot_index, x )

        xs.append( x )
        ys.append( y )

    ax.plot( xs, ys )

def plot_interpolated_points( ax, points ):

    xs = []
    ys = []

    for i in range(-1000,1001):

        # -10.0 <= x <= 10.0
        x = float(i) / 100.0 
        y = interpolate_N_order2_unit( points, x )

        xs.append( x )
        ys.append( y )

    ax.plot( xs, ys )

    xs = []
    ys = []

    for i in range( -10, 11 ):
        xs.append( float(i) )
        ys.append( points[ i + 10 ] )   

    ax.plot( xs, ys, 'o-', linewidth=0.5 )

fig, axs = plt.subplots( 2, sharex=True, sharey=True )

# Plot the basis functions

for k in range( -10, 11 ):
    plot_one_basis_func( axs[0], k )

axs[0].set_title( 'Basis Function Order 2 Unit Interval' )
axs[0].set_xticks([ -10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10 ])
axs[0].set_xlabel('u-axis')
axs[0].set_ylabel('N(k,u)')

# Plot the interpolated points

points = []
for i in range( -10, 11 ):
    points.append( random.random() )

plot_interpolated_points( axs[1], points )

axs[1].set_title( 'Interpolated Curve' )
axs[1].set_xticks([ -10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10 ])
axs[1].set_xlabel('U-axis')
axs[1].set_ylabel('X-axis')

#plt.show()
plt.tight_layout()
plt.gcf().set_size_inches(10, 5)
plt.savefig('basis_order_2_unit.png', dpi=300)
