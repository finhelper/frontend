import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(String)
    case networkError(String)
    case validationError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Geçersiz URL adresi"
        case .noData:
            return "Sunucudan veri alınamadı"
        case .decodingError(let detail):
            return "Sunucudan gelen veri işlenemedi: \(detail)"
        case .serverError(let message):
            if message.contains("Server error: 401") {
                return "E-posta veya şifre hatalı"
            } else if message.contains("Server error: 409") {
                return "Bu e-posta adresi zaten kullanımda"
            } else if message.contains("Server error: 404") {
                return "Kullanıcı bulunamadı"
            } else if message.contains("Server error: 500") {
                return "Sunucu hatası, lütfen daha sonra tekrar deneyin"
            }
            return "Sunucu hatası: \(message)"
        case .networkError(let message):
            return "Bağlantı hatası: \(message)"
        case .validationError(let message):
            return "Doğrulama hatası: \(message)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://finhelper.onrender.com"
    private var authToken: String?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    private init() {}
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    func makeRequest<T: Decodable>(endpoint: String, method: HTTPMethod = .get, body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 saniye timeout
        
        // Token varsa ekle
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
            print("\n📤 Request Details:")
            print("📤 URL: \(url)")
            print("📤 Method: \(method.rawValue)")
            if let jsonStr = String(data: body, encoding: .utf8) {
                print("📤 Body: \(jsonStr)")
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("\n📥 Response Details:")
            print("📥 Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            if let jsonStr = String(data: data, encoding: .utf8) {
                print("📥 Data: \(jsonStr)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError("Geçersiz sunucu yanıtı")
            }
            
            // HTTP durum koduna göre hata kontrolü
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    let result = try decoder.decode(T.self, from: data)
                    print("\n✅ Decoding başarılı:")
                    print("✅ Tip: \(T.self)")
                    return result
                } catch {
                    print("\n🚫 Decoding Error Details:")
                    print("🚫 Error: \(error)")
                    print("🚫 Data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, _):
                            throw NetworkError.decodingError("Eksik alan: \(key.stringValue)")
                        case .typeMismatch(_, let context):
                            throw NetworkError.decodingError("Tip uyuşmazlığı: \(context.debugDescription)")
                        case .valueNotFound(_, let context):
                            throw NetworkError.decodingError("Değer bulunamadı: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            throw NetworkError.decodingError("Bozuk veri: \(context.debugDescription)")
                        @unknown default:
                            throw NetworkError.decodingError(error.localizedDescription)
                        }
                    }
                    throw NetworkError.decodingError(error.localizedDescription)
                }
            case 400:
                throw NetworkError.validationError("Geçersiz istek")
            case 401:
                throw NetworkError.serverError("Server error: 401")
            case 404:
                throw NetworkError.serverError("Server error: 404")
            case 409:
                throw NetworkError.serverError("Server error: 409")
            case 500:
                throw NetworkError.serverError("Server error: 500")
            default:
                throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            print("\n🚫 Network Error:")
            print("🚫 \(error)")
            throw NetworkError.networkError(error.localizedDescription)
        }
    }
} 