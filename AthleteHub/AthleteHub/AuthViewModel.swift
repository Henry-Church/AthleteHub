import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import AuthenticationServices
import CryptoKit

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var userProfile = UserProfile()

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
            if let user = user {
                self.userProfile.uid = user.uid
                self.userProfile.email = user.email ?? ""
                self.userProfile.loadFromFirestore()
            }
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
            } else if let user = result?.user {
                self.user = user
                self.userProfile.uid = user.uid
                self.userProfile.email = user.email ?? ""
                self.userProfile.loadFromFirestore()
            }
        }
    }

    func signUp(email: String, password: String, name: String, birthDate: String, sex: String, height: Double, weight: Double, role: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error signing up: \(error.localizedDescription)")
            } else if let user = result?.user {
                self.user = user
                self.userProfile.uid = user.uid
                self.userProfile.email = email
                self.userProfile.name = name
                self.userProfile.profileId = name
                self.userProfile.birthDate = birthDate
                self.userProfile.sex = sex
                self.userProfile.height = height
                self.userProfile.weight = weight
                self.userProfile.role = role

                let db = Firestore.firestore()
                let rolePath = role.lowercased() == "coach" ? "coaches" : "athletes"
                let userRef = db.collection("users").document(rolePath).collection(user.uid)
                let parts = name.split(separator: " ", maxSplits: 1)
                let first = String(parts.first ?? "")
                let last = parts.count > 1 ? String(parts.last ?? "") : ""
                userRef.document("profileData").setData([
                    "firstName": first,
                    "lastName": last,
                    "email": email
                ])

                self.userProfile.saveToFirestore()
            }
        }
    }

    func handleAppleRequest(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleCompletion(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else { fatalError("Invalid state: no login request sent.") }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }

                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

                Auth.auth().signIn(with: credential) { result, error in
                    if let error = error {
                        print("Apple sign in error: \(error.localizedDescription)")
                        return
                    }

                    self.user = result?.user
                    self.userProfile.uid = result?.user.uid ?? ""
                    self.userProfile.email = result?.user.email ?? ""
                    self.userProfile.loadFromFirestore()
                }
            }
        case .failure(let error):
            print("Apple sign in failed: \(error.localizedDescription)")
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.userProfile = UserProfile()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // MARK: - Utility Methods
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
