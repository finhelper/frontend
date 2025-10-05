import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var username: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var birthDate: Date
    @State private var gender: User.Gender
    
    // Profil görseli için state'ler
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var selectedAvatar: User.AvatarType?
    @State private var showingImagePicker = false
    @State private var showingAvatarPicker = false
    @State private var showingPasswordChange = false
    @State private var showingSaveAlert = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.currentUser.name)
        _username = State(initialValue: viewModel.currentUser.username ?? "")
        _email = State(initialValue: viewModel.currentUser.email)
        _phoneNumber = State(initialValue: viewModel.currentUser.phoneNumber ?? "")
        _birthDate = State(initialValue: viewModel.currentUser.birthDate ?? Date())
        _gender = State(initialValue: viewModel.currentUser.gender ?? .other)
        _profileImageData = State(initialValue: viewModel.currentUser.photoData)
        _selectedAvatar = State(initialValue: viewModel.currentUser.avatarType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profil görseli seçimi
                Section {
                    VStack(spacing: 20) {
                        // Görsel önizleme
                        profileImagePreview
                            .frame(width: 120, height: 120)
                        
                        // Görsel seçim butonları
                        VStack(spacing: 12) {
                            Button(action: { 
                                sourceType = .photoLibrary
                                showingImagePicker = true 
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Galeriden Seç")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .foregroundColor(.primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { 
                                sourceType = .camera
                                showingImagePicker = true 
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Kameradan Çek")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .foregroundColor(.primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { showingAvatarPicker = true }) {
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                    Text("Avatar Seç (Kadın/Erkek)")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .foregroundColor(.primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Profil Görseli")
                }
                
                // Kişisel bilgiler
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $name)
                    TextField("Kullanıcı Adı", text: $username)
                    TextField("E-posta", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefon", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    DatePicker("Doğum Tarihi", selection: $birthDate, displayedComponents: .date)
                    
                    Picker("Cinsiyet", selection: $gender) {
                        ForEach(User.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }
                
                // Şifre değiştirme
                Section {
                    Button("Şifre Değiştir") {
                        showingPasswordChange = true
                    }
                }
            }
            .navigationTitle("Profil Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        saveChanges()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ProfileImagePickerView(sourceType: sourceType) { imageData in
                    profileImageData = imageData
                    selectedAvatar = nil // Fotoğraf seçilince avatar'ı temizle
                }
            }
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerView(selectedAvatar: $selectedAvatar) {
                    profileImageData = nil // Avatar seçilince fotoğrafı temizle
                    showingAvatarPicker = false
                }
            }
            .sheet(isPresented: $showingPasswordChange) {
                PasswordChangeView(viewModel: viewModel)
            }
            .alert("Profil Güncellendi", isPresented: $showingSaveAlert) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text("Profil bilgileriniz başarıyla güncellendi.")
            }
        }
    }
    
    private var profileImagePreview: some View {
        ZStack {
            if let imageData = profileImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if let avatar = selectedAvatar {
                Text(avatar.rawValue)
                    .font(.system(size: 80))
                    .frame(width: 120, height: 120)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.gray)
                    .clipShape(Circle())
            }
        }
    }
    
    private func saveChanges() {
        var updatedUser = viewModel.currentUser
        updatedUser.update(
            name: name,
            username: username,
            email: email,
            photoData: profileImageData,
            avatarType: selectedAvatar,
            phoneNumber: phoneNumber,
            birthDate: birthDate,
            gender: gender
        )
        
        // ViewModel'de kullanıcıyı güncelle
        viewModel.currentUser = updatedUser
        
        // UserDefaults'a kaydet
        if let encoded = try? JSONEncoder().encode(updatedUser) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        
        showingSaveAlert = true
    }
}

// Avatar seçici view
struct AvatarPickerView: View {
    @Binding var selectedAvatar: User.AvatarType?
    let onSelection: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Avatar Seç")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                HStack(spacing: 40) {
                    // Kadın Avatar
                    Button(action: {
                        selectedAvatar = .femaleAvatar
                        onSelection()
                    }) {
                        VStack(spacing: 12) {
                            Text(User.AvatarType.femaleAvatar.rawValue)
                                .font(.system(size: 80))
                                .frame(width: 120, height: 120)
                                .background(selectedAvatar == .femaleAvatar ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedAvatar == .femaleAvatar ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            
                            Text("Kadın")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Erkek Avatar
                    Button(action: {
                        selectedAvatar = .maleAvatar
                        onSelection()
                    }) {
                        VStack(spacing: 12) {
                            Text(User.AvatarType.maleAvatar.rawValue)
                                .font(.system(size: 80))
                                .frame(width: 120, height: 120)
                                .background(selectedAvatar == .maleAvatar ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedAvatar == .maleAvatar ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            
                            Text("Erkek")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Avatar Seçimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Şifre değiştirme view
struct PasswordChangeView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isCurrentPasswordVisible = false
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Mevcut Şifre
                    HStack {
                        if isCurrentPasswordVisible {
                            TextField("Mevcut Şifre", text: $currentPassword)
                        } else {
                            SecureField("Mevcut Şifre", text: $currentPassword)
                        }
                        Button(action: {
                            isCurrentPasswordVisible.toggle()
                        }) {
                            Image(systemName: isCurrentPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Yeni Şifre
                    HStack {
                        if isNewPasswordVisible {
                            TextField("Yeni Şifre", text: $newPassword)
                        } else {
                            SecureField("Yeni Şifre", text: $newPassword)
                        }
                        Button(action: {
                            isNewPasswordVisible.toggle()
                        }) {
                            Image(systemName: isNewPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Şifre Doğrulama
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("Yeni Şifre (Tekrar)", text: $confirmPassword)
                        } else {
                            SecureField("Yeni Şifre (Tekrar)", text: $confirmPassword)
                        }
                        Button(action: {
                            isConfirmPasswordVisible.toggle()
                        }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                } header: {
                    Text("Şifre Bilgileri")
                } footer: {
                    Text("Güvenliğiniz için mevcut şifrenizi girmeniz gereklidir.")
                }
                
                // Şifre gereksinimleri
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(newPassword.count >= 8 ? .green : .gray)
                            Text("En az 8 karakter")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: newPassword != confirmPassword || confirmPassword.isEmpty ? "circle" : "checkmark.circle.fill")
                                .foregroundColor(newPassword == confirmPassword && !confirmPassword.isEmpty ? .green : .gray)
                            Text("Şifreler eşleşiyor")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Şifre Gereksinimleri")
                }
                
                // Kaydet butonu
                Section {
                    Button(action: changePassword) {
                        HStack {
                            Spacer()
                            Text("Şifreyi Kaydet")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .white : .gray)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                }
            }
            .navigationTitle("Şifre Değiştir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .alert("Şifre Başarıyla Değiştirildi", isPresented: $showingSuccessAlert) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text("Şifreniz başarıyla güncellendi.")
            }
            .alert("Hata", isPresented: $showingErrorAlert) {
                Button("Tamam") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !currentPassword.isEmpty && 
               !newPassword.isEmpty && 
               !confirmPassword.isEmpty &&
               newPassword.count >= 8 &&
               newPassword == confirmPassword
    }
    
    private func changePassword() {
        // Mevcut şifre kontrolü
        if currentPassword != viewModel.currentUser.password {
            errorMessage = "Mevcut şifreniz yanlış."
            showingErrorAlert = true
            return
        }
        
        // Yeni şifre validasyonu
        if newPassword.count < 8 {
            errorMessage = "Yeni şifre en az 8 karakter olmalıdır."
            showingErrorAlert = true
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "Yeni şifreler eşleşmiyor."
            showingErrorAlert = true
            return
        }
        
        // Şifreyi güncelle
        var updatedUser = viewModel.currentUser
        updatedUser.password = newPassword
        viewModel.currentUser = updatedUser
        
        // UserDefaults'a kaydet
        if let encoded = try? JSONEncoder().encode(updatedUser) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        
        showingSuccessAlert = true
    }
}

// Profile ImagePicker wrapper
struct ProfileImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileImagePickerView
        
        init(_ parent: ProfileImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Resmi compress et
                if let imageData = image.jpegData(compressionQuality: 0.5) {
                    parent.onImageSelected(imageData)
                }
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 