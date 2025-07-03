import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var healthManager: HealthManager
    @State private var showingUserSettingsSheet = false
    @State private var showingNotificationsSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingIntegrationsSheet = false

    let accentColor = Color(red: 1.0, green: 0.25, blue: 0.25)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProfileHeaderView(userProfile: userProfile)

                ProfileStatsView(userProfile: userProfile, accentColor: accentColor, colorScheme: colorScheme)

                ProfileOptionsView(accentColor: accentColor, colorScheme: colorScheme,
                                   showingUserSettingsSheet: $showingUserSettingsSheet,
                                   showingNotificationsSheet: $showingNotificationsSheet,
                                   showingSettingsSheet: $showingSettingsSheet,
                                   showingIntegrationsSheet: $showingIntegrationsSheet)

                Button(action: {
                    authViewModel.signOut()
                }) {
                    HStack {
                        Image(systemName: "arrow.backward.square")
                        Text("Sign Out")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.bottom)
        }
        .background(accentColor.opacity(0.05).edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingUserSettingsSheet) {
            UserSettingsFormView().environmentObject(userProfile)
        }
        .sheet(isPresented: $showingNotificationsSheet) {
            NotificationsFormView()
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsFormView()
        }
        .sheet(isPresented: $showingIntegrationsSheet) {
            IntegrationsFormView().environmentObject(healthManager)
        }
    }
}

struct NotificationsFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var pushEnabled = true
    @State private var emailEnabled = false
    @State private var muteAll = false
    @State private var activityReminders = true
    @State private var weeklySummary = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preferences")) {
                    Toggle("Push Notifications", isOn: $pushEnabled)
                    Toggle("Email Notifications", isOn: $emailEnabled)
                    Toggle("Mute All", isOn: $muteAll)
                    Toggle("Activity Reminders", isOn: $activityReminders)
                    Toggle("Weekly Summary Emails", isOn: $weeklySummary)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

struct SettingsFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var privacyEnabled = false
    @State private var twoFactorAuth = false
    @State private var requirePasscode = false
    @State private var shareActivity = true
    @State private var allowCoachAccess = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Security")) {
                    Toggle("Enable Two-Factor Authentication", isOn: $twoFactorAuth)
                    Toggle("Require Passcode on Launch", isOn: $requirePasscode)
                }

                Section(header: Text("Privacy")) {
                    Toggle("Hide Activity Status", isOn: $privacyEnabled)
                    Toggle("Share Activity with Friends", isOn: $shareActivity)
                    Toggle("Allow Coach Access", isOn: $allowCoachAccess)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

struct IntegrationsFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var healthManager: HealthManager
    @AppStorage("healthConnected") var isConnectedToHealth: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Apple Health")) {
                    Toggle(isOn: $isConnectedToHealth) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Connect Apple Health")
                        }
                    }
                    .onChange(of: isConnectedToHealth) { newValue in
                        if newValue {
                            healthManager.requestAuthorization { success in
                                if success {
                                    healthManager.fetchAllData()
                                } else {
                                    isConnectedToHealth = false
                                }
                            }
                        } else {
                            healthManager.disconnectHealthKit()
                        }
                    }
                }


                Section(header: Text("Other Integrations")) {
                    IntegrationButton(icon: "figure.run", label: "Connect Strava")
                    IntegrationButton(icon: "flame.fill", label: "Connect Fitbit")
                    IntegrationButton(icon: "bolt.fill", label: "Connect Garmin")
                    IntegrationButton(icon: "fork.knife", label: "Connect MyFitnessPal")
                    IntegrationButton(icon: "chart.bar.fill", label: "Connect TrainingPeaks")
                }
            }
            .navigationTitle("Integrations")
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

struct IntegrationButton: View {
    let icon: String
    let label: String

    var body: some View {
        Button(action: {
            // handle integration tap
        }) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(8)
            .background(Color(.systemBackground))
        }
    }
}

struct ProfileHeaderView: View {
    @ObservedObject var userProfile: UserProfile

    var body: some View {
        VStack {
            if let image = userProfile.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            Text(userProfile.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(userProfile.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 24)
    }
}

struct HealthDataView: View {
    @ObservedObject var healthManager: HealthManager

    var body: some View {
        VStack(spacing: 16) {
            if healthManager.isAuthorized {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Data")
                        .font(.headline)
                    Text("Resting Heart Rate: \(Int(healthManager.restingHeartRate ?? 0)) bpm")
                    Text("Calories Burned: \(Int(healthManager.activeCalories ?? 0)) kcal")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Button("Link Apple Health") {
                    healthManager.requestAuthorization { success in
                        if success {
                            healthManager.fetchAllData()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}

struct ProfileStatsView: View {
    @ObservedObject var userProfile: UserProfile
    let accentColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 16) {
            ProfileInfoBox(label: "Age", value: "\(calculateAge(from: userProfile.birthDate))", shadowColor: accentColor, colorScheme: colorScheme)
            ProfileInfoBox(label: "Sex", value: userProfile.sex, shadowColor: accentColor, colorScheme: colorScheme)
            ProfileInfoBox(label: "Height", value: "\(Int(userProfile.height)) cm", shadowColor: accentColor, colorScheme: colorScheme)
            ProfileInfoBox(label: "Weight", value: "\(Int(userProfile.weight)) kg", shadowColor: accentColor, colorScheme: colorScheme)
        }
        .padding(.horizontal)
    }

    func calculateAge(from dobString: String) -> Int {
        if dobString.isEmpty { return 0 }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        guard let dobDate = formatter.date(from: dobString) else { return 0 }
        let now = Date()
        let components = Calendar.current.dateComponents([.year], from: dobDate, to: now)
        return components.year ?? 0
    }
}

struct ProfileOptionsView: View {
    let accentColor: Color
    let colorScheme: ColorScheme
    @Binding var showingUserSettingsSheet: Bool
    @Binding var showingNotificationsSheet: Bool
    @Binding var showingSettingsSheet: Bool
    @Binding var showingIntegrationsSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            Button(action: { showingUserSettingsSheet = true }) {
                ProfileOptionRow(icon: "person.fill", title: "User Settings", subtitle: "Username & Personal Info", shadowColor: accentColor, colorScheme: colorScheme)
            }

            Button(action: { showingNotificationsSheet = true }) {
                ProfileOptionRow(icon: "bell.fill", title: "Notifications", subtitle: "Mute, Push, Email", shadowColor: accentColor, colorScheme: colorScheme)
            }

            Button(action: { showingSettingsSheet = true }) {
                ProfileOptionRow(icon: "gear", title: "Settings", subtitle: "Security, Privacy", shadowColor: accentColor, colorScheme: colorScheme)
            }

            Button(action: { showingIntegrationsSheet = true }) {
                ProfileOptionRow(icon: "link", title: "Integrations", subtitle: "Connected Services", shadowColor: accentColor, colorScheme: colorScheme)
            }
        }
        .padding(.horizontal)
    }
}

struct ProfileInfoBox: View {
    let label: String
    let value: String
    let shadowColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Text(label)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .frame(width: 80, height: 80)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let shadowColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray5))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
