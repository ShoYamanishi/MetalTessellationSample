import SwiftUI

@main
struct TessellationSampleApp: App {

    let worldManager : WorldManager!
    
    init() {
        worldManager = WorldManager( device: MTLCreateSystemDefaultDevice()! )
    }

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject( worldManager )
        }
    }
}
