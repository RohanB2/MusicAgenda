import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var firestoreManager = FirestoreManager()
    @State private var isLoggedIn = Auth.auth().currentUser != nil
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if isLoggedIn {
                ContentView()
                    .environment(firestoreManager)
            } else {
                LoginView()
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { auth, user in
                isLoggedIn = user != nil
                if user != nil {
                    firestoreManager.startListening()
                } else {
                    firestoreManager.stopListening()
                }
            }
            if isLoggedIn {
                firestoreManager.startListening()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isLoggedIn {
                firestoreManager.processPendingWidgetUpdates()
            }
        }
    }
}
