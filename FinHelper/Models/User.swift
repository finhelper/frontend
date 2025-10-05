import Foundation

// Kullanıcı modelini tanımlayan yapı
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var password: String?
    var username: String?
    var profileImage: String?
    var photoData: Data? // Profil fotoğrafı verisi
    var avatarType: AvatarType? // Avatar seçimi (kadın/erkek bitmoji)
    var phoneNumber: String?
    var birthDate: Date?
    var gender: Gender?
    var createdAt: Date?
    var updatedAt: Date?
    
    // Avatar türleri enum'ı
    enum AvatarType: String, Codable, CaseIterable {
        case femaleAvatar = "👩‍💼"
        case maleAvatar = "👨‍💼"
        
        var displayName: String {
            switch self {
            case .femaleAvatar:
                return "Kadın Avatar"
            case .maleAvatar:
                return "Erkek Avatar"
            }
        }
    }
    
    // Cinsiyet enum'ı
    enum Gender: String, Codable, CaseIterable {
        case male = "Erkek"
        case female = "Kadın"
        case other = "Diğer"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mongoId = "id" // Alternatif id alanı
        case name
        case email
        case password
        case username
        case profileImage
        case photoData
        case avatarType
        case phoneNumber
        case birthDate
        case gender
        case createdAt
        case updatedAt
    }
    
    // Manuel initializer
    init(id: String, name: String, email: String, password: String? = nil, username: String? = nil, 
         profileImage: String? = nil, photoData: Data? = nil, avatarType: AvatarType? = nil, phoneNumber: String? = nil, birthDate: Date? = nil, gender: Gender? = nil,
         createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.username = username
        self.profileImage = profileImage
        self.photoData = photoData
        self.avatarType = avatarType
        self.phoneNumber = phoneNumber
        self.birthDate = birthDate
        self.gender = gender
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID alanını farklı anahtarlardan dene
        if let _id = try? container.decode(String.self, forKey: .id) {
            id = _id
        } else if let mongoId = try? container.decode(String.self, forKey: .mongoId) {
            id = mongoId
        } else {
            // Eğer id bulunamazsa UUID oluştur
            id = UUID().uuidString
        }
        
        // Zorunlu alanlar
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        
        // Opsiyonel alanlar
        password = try container.decodeIfPresent(String.self, forKey: .password)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        avatarType = try container.decodeIfPresent(AvatarType.self, forKey: .avatarType)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    // Encoder function
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // ID'yi _id olarak encode et
        try container.encode(id, forKey: .id)
        
        // Zorunlu alanlar
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        
        // Opsiyonel alanlar
        try container.encodeIfPresent(password, forKey: .password)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(profileImage, forKey: .profileImage)
        try container.encodeIfPresent(photoData, forKey: .photoData)
        try container.encodeIfPresent(avatarType, forKey: .avatarType)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // Boş kullanıcı oluşturmak için static fonksiyon
    static func emptyUser() -> User {
        return User(
            id: UUID().uuidString,
            name: "",
            email: "",
            username: nil,
            phoneNumber: nil,
            gender: nil
        )
    }
    
    // Kullanıcı bilgilerini güncelleme
    mutating func update(
        name: String? = nil,
        username: String? = nil,
        email: String? = nil,
        profileImage: String? = nil,
        photoData: Data? = nil,
        avatarType: AvatarType? = nil,
        password: String? = nil,
        phoneNumber: String? = nil,
        birthDate: Date? = nil,
        gender: Gender? = nil
    ) {
        if let name = name { self.name = name }
        if let username = username { self.username = username }
        if let email = email { self.email = email }
        if let profileImage = profileImage { self.profileImage = profileImage }
        if let photoData = photoData { self.photoData = photoData }
        if let avatarType = avatarType { self.avatarType = avatarType }
        if let password = password { self.password = password }
        if let phoneNumber = phoneNumber { self.phoneNumber = phoneNumber }
        if let birthDate = birthDate { self.birthDate = birthDate }
        if let gender = gender { self.gender = gender }
    }
}

// API Yanıt Modelleri
struct AuthResponse: Codable {
    let token: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case token
        case user
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
        
        do {
            user = try container.decode(User.self, forKey: .user)
        } catch {
            print("🚫 User Decoding Error: \(error)")
            throw error
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(user, forKey: .user)
    }
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let name: String
} 
