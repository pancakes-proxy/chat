import SwiftUI
import LocalAuthentication
import UserNotifications
import AuthenticationServices
import GoogleMobileAds

@main
struct BudgetingApp: App {
    init() {
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var isAuthenticated: Bool = false
    @State private var goalAmount: Double = 0.0
    @State private var currentSavings: Double = 0.0
    @State private var isSignedIn: Bool = false
    @State private var userName: String = "Guest"
    
    var remainingAmount: Double {
        max(0, goalAmount - currentSavings)
    }
    
    var body: some View {
        ZStack {
            if isAuthenticated {
                VStack {
                    mainContentView
                    BannerAdView() // Add the banner ad at the bottom of the view
                        .frame(height: 50)
                }
            } else {
                lockScreenView
            }
        }
        .onAppear {
            authenticateWithFaceID() // Prompt Face ID/Passcode authentication on app load
        }
    }
    
    var mainContentView: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Welcome: \(userName)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                
                if isSignedIn {
                    VStack(spacing: 15) {
                        TextField("Enter your goal amount", value: $goalAmount, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        
                        TextField("Enter your current savings", value: $currentSavings, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        
                        Text("You need to save: $\(remainingAmount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                        
                        Button(action: {
                            requestNotificationPermission()
                            scheduleWeeklyNotification(remainingAmount: remainingAmount)
                        }) {
                            Text("Enable Weekly Notifications")
                                .bold()
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    SignInWithAppleButtonView(isSignedIn: $isSignedIn, userName: $userName)
                }
            }
            .padding()
        }
    }
    
    var lockScreenView: some View {
        VStack {
            Text("Unlock with Face ID or Passcode")
                .font(.title2)
                .padding()
            
            Button(action: authenticateWithFaceID) {
                Text("Authenticate")
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to access your budgeting app"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true
                    } else {
                        print("Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Authentication not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }
    
    func scheduleWeeklyNotification(remainingAmount: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Budgeting Reminder"
        content.body = "You still need to save $\(remainingAmount, specifier: "%.2f") to reach your goal!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9 // 9:00 AM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "WeeklyBudgetingReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-2596258669748338/2454154397" // Replace with your Ad Unit ID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // Update the banner view if needed
    }
}

struct SignInWithAppleButtonView: View {
    @Binding var isSignedIn: Bool
    @Binding var userName: String
    
    var body: some View {
        VStack {
            Text("Sign in to Sync Your Data")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        handleAuthorization(authorization)
                        isSignedIn = true
                    case .failure(let error):
                        print("Sign in with Apple failed: \(error)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(width: 280, height: 50)
            .cornerRadius(10)
        }
        .padding()
    }
    
    func handleAuthorization(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            if let fullName = appleIDCredential.fullName {
                userName = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
                if userName.isEmpty {
                    userName = "User"
                }
            }
        }
    }
}
