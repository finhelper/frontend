import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    
    init() {
        Task {
            await checkAuth()
        }
    }
    
    func checkAuth() async {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let token = UserDefaults.standard.string(forKey: "authToken"),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            
            // Token'ı NetworkManager'a ayarla
            NetworkManager.shared.setAuthToken(token)
            
            // Kullanıcı bilgilerini güncelle
            self.currentUser = savedUser
            self.isAuthenticated = true
        }
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let signUpRequest = SignUpRequest(email: email, password: password, name: name)
            let jsonData = try JSONEncoder().encode(signUpRequest)
            
            print("Kayıt isteği gönderiliyor...")
            let response: AuthResponse = try await networkManager.makeRequest(
                endpoint: "/api/auth/register",
                method: .post,
                body: jsonData
            )
            print("Kayıt başarılı!")
            
            self.currentUser = response.user
            self.isAuthenticated = true
            saveToken(response.token)
            saveUser(response.user)
            
        } catch let error as NetworkError {
            print("Kayıt hatası: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        } catch {
            print("Beklenmeyen hata: \(error.localizedDescription)")
            self.errorMessage = "Beklenmeyen bir hata oluştu"
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loginRequest = ["email": email, "password": password]
            let jsonData = try JSONEncoder().encode(loginRequest)
            
            print("Giriş isteği gönderiliyor...")
            let response: AuthResponse = try await networkManager.makeRequest(
                endpoint: "/api/auth/login",
                method: .post,
                body: jsonData
            )
            print("Giriş başarılı!")
            
            self.currentUser = response.user
            self.isAuthenticated = true
            saveToken(response.token)
            saveUser(response.user)
            
        } catch let error as NetworkError {
            print("Giriş hatası: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        } catch {
            print("Beklenmeyen hata: \(error.localizedDescription)")
            self.errorMessage = "Beklenmeyen bir hata oluştu"
        }
        
        isLoading = false
    }
    
    func logout() {
        // Çıkış yapılmadan önce mevcut kullanıcı ID'sini al
        let currentUserId = currentUser?.id
        
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        NetworkManager.shared.clearAuthToken()
        
        // Eğer kullanıcı ID'si varsa, o kullanıcıya ait tüm verileri temizle
        if let userId = currentUserId {
            UserDefaults.standard.removeObject(forKey: "expenses_\(userId)")
            UserDefaults.standard.removeObject(forKey: "groups_\(userId)")
            UserDefaults.standard.removeObject(forKey: "personalExpenses_\(userId)")
        }
        
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "authToken")
        NetworkManager.shared.setAuthToken(token)
    }
    
    private func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
} 