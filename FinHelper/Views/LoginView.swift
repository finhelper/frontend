import SwiftUI

struct LoginView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingForgotPassword = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "tr"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo
                Image("finhelper_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 30)
                
                // Başlık
                Text("FinHelper")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                // Giriş formu
                VStack(spacing: 15) {
                    TextField(localizedString(key: "email"), text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField(localizedString(key: "password"), text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: login) {
                        HStack {
                            Spacer()
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(localizedString(key: "login"))
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                            Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 30)
                
                // Şifremi unuttum butonu
                Button(action: { showingForgotPassword = true }) {
                    Text(localizedString(key: "forgotPassword"))
                        .foregroundColor(.blue)
                        .font(.footnote)
                }
                .padding(.top, 10)
                
                // Kayıt ol butonu
                Button(action: { showingSignUp = true }) {
                    Text(localizedString(key: "signUp"))
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Dil seçimi
                VStack(spacing: 10) {
                    Text(localizedString(key: "language"))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        Button(action: { selectedLanguage = "tr" }) {
                            HStack {
                                Text("🇹🇷")
                                Text("Türkçe")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedLanguage == "tr" ? Color.blue.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedLanguage == "tr" ? .blue : .gray)
                            .cornerRadius(8)
                        }
                        
                        Button(action: { selectedLanguage = "en" }) {
                            HStack {
                                Text("🇺🇸")
                                Text("English")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedLanguage == "en" ? Color.blue.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedLanguage == "en" ? .blue : .gray)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .fullScreenCover(isPresented: .init(
            get: { authViewModel.isAuthenticated },
            set: { _ in }
        )) {
            ContentView()
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        email.contains("@") && 
        email.contains(".")
    }
    
    private func login() {
        Task {
            await authViewModel.login(email: email, password: password)
        }
    }
    
    // Çoklu dil desteği fonksiyonu
    private func localizedString(key: String) -> String {
        let translations: [String: [String: String]] = [
            "tr": [
                "email": "E-posta",
                "password": "Şifre",
                "login": "Giriş Yap",
                "forgotPassword": "Şifremi Unuttum",
                "signUp": "Hesabın yok mu? Kayıt ol",
                "language": "Dil"
            ],
            "en": [
                "email": "Email",
                "password": "Password",
                "login": "Login",
                "forgotPassword": "Forgot Password",
                "signUp": "Don't have an account? Sign Up",
                "language": "Language"
            ]
        ]
        
        return translations[selectedLanguage]?[key] ?? key
    }
}

// Şifremi Unuttum sayfası
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showingAlert = false
    @State private var isLoading = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "tr"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // İkon
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 50)
                
                // Başlık ve açıklama
                VStack(spacing: 15) {
                    Text(localizedString(key: "resetPasswordTitle"))
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    Text(localizedString(key: "resetPasswordDescription"))
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Email girişi
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizedString(key: "email"))
                        .font(.headline)
                    
                    TextField(localizedString(key: "emailPlaceholder"), text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal)
                
                // Gönder butonu
                Button(action: sendResetEmail) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(localizedString(key: "sendResetLink"))
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidEmail ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isValidEmail || isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(localizedString(key: "forgotPassword"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizedString(key: "cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .alert(localizedString(key: "emailSent"), isPresented: $showingAlert) {
            Button(localizedString(key: "ok")) {
                dismiss()
            }
        } message: {
            Text(localizedString(key: "emailSentMessage"))
        }
    }
    
    private var isValidEmail: Bool {
        !email.isEmpty && email.contains("@") && email.contains(".")
    }
    
    private func sendResetEmail() {
        isLoading = true
        
        // Simüle edilmiş API çağrısı
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            showingAlert = true
        }
    }
    
    // Çoklu dil desteği fonksiyonu
    private func localizedString(key: String) -> String {
        let translations: [String: [String: String]] = [
            "tr": [
                "resetPasswordTitle": "Şifrenizi Sıfırlayın",
                "resetPasswordDescription": "E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.",
                "email": "E-posta",
                "emailPlaceholder": "E-posta adresinizi girin",
                "sendResetLink": "Sıfırlama Bağlantısı Gönder",
                "cancel": "İptal",
                "forgotPassword": "Şifremi Unuttum",
                "emailSent": "E-posta Gönderildi!",
                "emailSentMessage": "Mailinize şifre değiştirme linki gönderildi.",
                "ok": "Tamam"
            ],
            "en": [
                "resetPasswordTitle": "Reset Your Password",
                "resetPasswordDescription": "Enter your email address and we'll send you a password reset link.",
                "email": "Email",
                "emailPlaceholder": "Enter your email address",
                "sendResetLink": "Send Reset Link",
                "cancel": "Cancel",
                "forgotPassword": "Forgot Password",
                "emailSent": "Email Sent!",
                "emailSentMessage": "A password reset link has been sent to your email.",
                "ok": "OK"
            ]
        ]
        
        return translations[selectedLanguage]?[key] ?? key
    }
}

#Preview {
    LoginView()
}
