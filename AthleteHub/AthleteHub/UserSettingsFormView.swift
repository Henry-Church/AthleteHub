//
//  UserSettingsFormView.swift
//  AthleteHub
//
//  Created by Henry Church on 29/06/2025.
//

import SwiftUI
import PhotosUI

struct UserSettingsFormView: View {
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var username: String = ""
    @State private var dob = Date()
    @State private var sexOptions = ["Male", "Female", "Other"]
    @State private var selectedSex = "Male"
    @State private var roleOptions = ["Athlete", "Coach"]
    @State private var selectedRole = "Athlete"
    @State private var height: Double = 170
    @State private var weight: Double = 70
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture")) {
                    HStack {
                        if let image = selectedImage ?? userProfile.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }

                        Button("Change Photo") {
                            showingImagePicker = true
                        }
                    }
                }

                Section(header: Text("Profile")) {
                    TextField("Username", text: $username)
                }

                Section(header: Text("Personal Info")) {
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    Picker("Sex", selection: $selectedSex) {
                        ForEach(sexOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    Picker("Role", selection: $selectedRole) {
                        ForEach(roleOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Height: \(Int(height)) cm")
                        Slider(value: $height, in: 100...250, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Weight: \(Int(weight)) kg")
                        Slider(value: $weight, in: 30...200, step: 1)
                    }
                }
            }
            .navigationTitle("User Settings")
            .navigationBarItems(trailing: Button("Done") {
                userProfile.name = username
                userProfile.profileId = username
                userProfile.sex = selectedSex
                userProfile.height = height
                userProfile.weight = weight
                userProfile.birthDate = DateFormatter.localizedString(from: dob, dateStyle: .short, timeStyle: .none)
                userProfile.role = selectedRole
                if let image = selectedImage {
                    userProfile.profileImage = image
                }
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                username = userProfile.name
                selectedSex = userProfile.sex
                selectedRole = userProfile.role
                height = userProfile.height
                weight = userProfile.weight
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                if let date = formatter.date(from: userProfile.birthDate) {
                    dob = date
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    self.parent.image = object as? UIImage
                }
            }
        }
    }
}
