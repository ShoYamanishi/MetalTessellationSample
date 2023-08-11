import SwiftUI

struct ContentView: View {

    @EnvironmentObject var worldManager: WorldManager

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {

        if verticalSizeClass == .compact {
            HStack {
                MetalView().padding()
                HStack{
                    Text("Factor:")
                    Slider( value: $worldManager.tessellationFactor, in: 0.1...100.0 ).padding()
                }
                HStack{
                    Text("Intensity:")
                    Slider( value: $worldManager.agitationIntensity, in: 0.0...100.0 ).padding()
                }
                Toggle( "Show Wireframe", isOn: $worldManager.showWireFrame )
                Text("Tessllation Factor Coeff: \( worldManager.tessellationFactor, specifier: "%.1f")")
                Text("Surface Agitation Intensity: \( worldManager.agitationIntensity, specifier: "%.0f")")
            }

        } else {
            VStack(alignment: .center) {
                MetalView().padding()
                HStack{
                    Text("Factor:")
                    Slider( value: $worldManager.tessellationFactor, in: 0.1...100.0 ).padding()
                }
                HStack{
                    Text("Intensity:")
                    Slider( value: $worldManager.agitationIntensity, in: 0.0...100.0 ).padding()
                }
                Toggle( "Show Wireframe", isOn: $worldManager.showWireFrame )
                Text("Tessllation Factor Coeff: \( worldManager.tessellationFactor, specifier: "%.1f")")
                Text("Surface Agitation Intensity: \( worldManager.agitationIntensity, specifier: "%.0f")")
            }
        }
    }
}

