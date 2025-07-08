import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var sex = "Other"
    @State private var role = "Athlete"
    @State private var height: Double = 170
    @State private var weight: Double = 70
    @State private var showAlert = false
    @State private var alertMessage = ""

    let sexOptions = ["Male", "Female", "Other"]
    let roleOptions = ["Athlete", "Coach"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.top)

                    Group {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)

                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        DatePicker("Date of Birth", selection: $birthDate, displayedComponents: .date)
                            .padding(.horizontal)

                        Picker("Sex", selection: $sex) {
                            ForEach(sexOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        Picker("Role", selection: $role) {
                            ForEach(roleOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Height: \(Int(height)) cm")
                            Slider(value: $height, in: 100...250, step: 1)
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Weight: \(Int(weight)) kg")
                            Slider(value: $weight, in: 30...200, step: 1)
                        }
                        .padding(.horizontal)
                    }

                    Button(action: {
                        if validateFields() {
                            let dobString = DateFormatter.localizedString(from: birthDate, dateStyle: .short, timeStyle: .none)
                            authViewModel.signUp(email: email, password: password, name: name, birthDate: dobString, sex: sex, height: height, weight: weight, role: role)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Sign Up")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func validateFields() -> Bool {
        if name.isEmpty || email.isEmpty || password.isEmpty {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return false
        }
        if !email.contains("@") {
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return false
        }
        if password.count < 6 {
            alertMessage = "Password must be at least 6 characters."
            showAlert = true
            return false
        }
        return true
    }
}
