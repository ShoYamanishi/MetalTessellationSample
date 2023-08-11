import Foundation
import MetalKit

func printMatrix( M : matrix_float4x4 ) -> String {

    var outStr : String = "\n"

    for i in 0..<4 { // row

        for j in 0..<4 { // col

            let v = M[j][i]
            outStr += String( format: "%.3f", v )
            outStr += "\t"
        }
        outStr += "\n\n"
    }
    outStr += "\n"
    return outStr
}
