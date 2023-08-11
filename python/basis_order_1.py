import matplotlib.pyplot as plt

__author__    = "Shoichiro Yamanishi"
__copyright__ = "Copyright 2023, Shoichiro Yamanishi"
__license__   = "GPLv3"
__version__   = "1.0"

'''
This is a sample python code to illustrate the order-1 B-spline basis functions.
'''

def N_order0( knots : [float], k : int, u : float ) -> float:

    '''Basis function of order 0
       :param knots : knots array
       :param k: knot index.
       :param u: input
       :returns: output       
    '''

    if knots[k] <= u and u < knots[k+1]:
        return 1.0
    else:
        return 0.0

def N_order1( knots : [float], k : int, u : float ) -> float:

    '''Basis function of order 1 (linear).
       :param knots : knots array
       :param k: knot index.
       :param u: input
       :returns: output       
    '''

    if knots[k+1] - knots[k] == 0.0:
        sum1 = 0.0
    else:
        sum1 = (u - knots[k]) / (knots[k+1] - knots[k]) * N_order0(knots, k, u) 

    if knots[k+2] - knots[k+1] == 0.0:
        sum2 = 0.0
    else:
        sum2 = (knots[k+2] - u) / (knots[k+2] - knots[k+1]) * N_order0(knots, k+1, u) 

    return sum1 + sum2

# Sample knots at an irregular interval
#
# index       0      1      2      3      4      5      6      7      8      9      10     11     12     13
knots = [ -15.0, -13.0,  -11.5, -7.0,  -5.0,  -1.0,   3.0,   4.0,   4.5,   5.5,   7.0,   9.5,   13.0,  15.0]

def plot_one_basis_func( ax, knot_index ):

    xs = []
    ys = []

    for i in range(-1500,1501):

        # -15.0 <= x <= 15.0
        x = float(i)/100.0 
        y = N_order1( knots, knot_index, x )

        xs.append( x )
        ys.append( y )

    ax.plot( xs, ys )


fig = plt.figure()
ax = fig.add_subplot(111)

for k in range( 0, len(knots)-2 ):
    plot_one_basis_func( ax, k )

ax.plot( knots, [0] * 14, 'o' )

#ax.set_title( 'Basis Function Order 1' )
ax.set_xticks([ -10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10 ])
ax.set_xlabel('u-axis')
ax.set_ylabel('N(k,u)')
#plt.show()
plt.tight_layout()
plt.gcf().set_size_inches(6, 4.0)
plt.savefig('basis_order_1.png', dpi=300)
