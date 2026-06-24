import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Music Agenda")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled(true)
#if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
#endif
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            Button("Sign In / Create Account") {
                loginOrRegister()
            }
            .buttonStyle(.borderedProminent)
            
            Text("Using Email & Password ensures your albums sync across your Mac and iPhone seamlessly.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .padding()
        .frame(maxWidth: 400)
    }
    
    private func loginOrRegister() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error != nil {
                // If sign in fails, try creating the account
                Auth.auth().createUser(withEmail: email, password: password) { result, createError in
                    if let createError = createError {
                        errorMessage = createError.localizedDescription
                    } else {
                        errorMessage = nil
                    }
                }
            } else {
                errorMessage = nil
            }
        }
    }
}
