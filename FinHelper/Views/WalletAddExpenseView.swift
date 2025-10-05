import SwiftUI
import PhotosUI

struct WalletAddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MainViewModel
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory = ExpenseCategory.other
    @State private var customEmoji = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingEmojiPicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                // Görsel Seçimi
                Section(header: Text("Görsel")) {
                    VStack(spacing: 16) {
                        // Seçilen görsel gösterimi (sadece gösterim, tıklanamaz)
                        HStack {
                            Spacer()
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                                    .frame(width: 80, height: 80)
                                
                                if !customEmoji.isEmpty {
                                    Text(customEmoji)
                                        .font(.system(size: 40))
                                } else if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Görsel seçim butonları (ayrı ayrı)
                        VStack(spacing: 8) {
                            Button(action: {
                                showingEmojiPicker = true
                            }) {
                                HStack {
                                    Text("😊")
                                    Text("Emoji Seç")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                                HStack {
                                    Text("📷")
                                    Text("Galeriden Seç")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                showingCamera = true
                            }) {
                                HStack {
                                    Text("📸")
                                    Text("Fotoğraf Çek")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Harcama başlığı
                Section(header: Text("Harcama Detayları")) {
                    TextField("Başlık", text: $title)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tutar")
                            .font(.headline)
                        
                        HStack {
                            Text("₺")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            TextField("0,00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.title2)
                                .onChange(of: amount) { _, newValue in
                                    formatAmountInput(newValue)
                                }
                        }
                        .padding()
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(8)
                        
                        Text("Örnek: 1.250,75 veya 50,00")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Harcama Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ekle") {
                        addExpense()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $customEmoji, onEmojiSelected: {
                    photoData = nil // Emoji seçildiğinde fotoğrafı temizle
                })
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(sourceType: .camera, selectedImage: $inputImage)
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                Task {
                    if let data = try? await newPhoto?.loadTransferable(type: Data.self) {
                        photoData = data
                        customEmoji = "" // Fotoğraf seçildiğinde emoji'yi temizle
                    }
                }
            }
            .onChange(of: inputImage) { _, newImage in
                if let image = newImage {
                    photoData = image.jpegData(compressionQuality: 0.7)
                    customEmoji = "" // Fotoğraf çekildiğinde emoji'yi temizle
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && amount.turkishCurrencyToDouble() != nil
    }
    
    private func formatAmountInput(_ input: String) {
        // Sadece rakam, virgül ve nokta kabul et
        let filtered = input.filter { "0123456789.,".contains($0) }
        
        // Birden fazla virgül veya nokta varsa düzelt
        let parts = filtered.components(separatedBy: ",")
        if parts.count > 2 {
            // Sadece ilk virgülü koru
            let beforeComma = parts[0]
            let afterComma = parts[1...].joined()
            amount = beforeComma + "," + String(afterComma.prefix(2)) // En fazla 2 ondalık basamak
        } else if parts.count == 2 {
            // Ondalık kısmı en fazla 2 basamakla sınırla
            amount = parts[0] + "," + String(parts[1].prefix(2))
        } else {
            amount = filtered
        }
    }
    
    private func addExpense() {
        if let amountValue = amount.turkishCurrencyToDouble() {
            viewModel.addExpense(
                title: title,
                amount: amountValue,
                category: selectedCategory,
                customEmoji: customEmoji.isEmpty ? nil : customEmoji,
                photoData: photoData
            )
            dismiss()
        }
    }
}

// Emoji Seçici Görünümü
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    let onEmojiSelected: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    let emojis = [
        // Yemek & İçecek
        "🍎", "🍕", "🍔", "🍟", "🌭", "🥪", "🌮", "🍣", "🍜", "☕",
        "🥤", "🍺", "🍷", "🧁", "🍪", "🍰", "🎂", "🍓", "🥑", "🥕",
        
        // Ulaşım
        "🚗", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🛻",
        "🚚", "🚛", "🚜", "🏍️", "🛵", "🚲", "🛴", "✈️", "🚁", "⛵",
        
        // Alışveriş
        "🛍️", "🛒", "💳", "💰", "💎", "👕", "👖", "👗", "👠", "👜",
        "🎒", "👓", "⌚", "📱", "💻", "🖥️", "⌨️", "🖱️", "🎧", "📷",
        
        // Eğlence
        "🎬", "🎮", "🎯", "🎲", "♠️", "🃏", "🎪", "🎨", "🎭", "🎪",
        "🎡", "🎢", "🎠", "🎳", "⚽", "🏀", "🏈", "⚾", "🎾", "🏐",
        
        // Sağlık
        "💊", "🩺", "💉", "🌡️", "🩹", "🦷", "👁️", "🧠", "❤️", "🫁",
        
        // Diğer
        "🏠", "🏢", "🏪", "🏫", "🏥", "🏨", "⛽", "🔧", "🔨", "⚡",
        "💡", "📚", "📖", "✏️", "🖊️", "📝", "📊", "💼", "🎁", "🌟"
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Emoji Seç")
                    .font(.title2.bold())
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            onEmojiSelected()
                            dismiss()
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                                )
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Kamera ve Galeri için UIImagePickerController
struct ImagePickerView: UIViewControllerRepresentable {
    enum SourceType {
        case camera
        case photoLibrary
    }
    
    let sourceType: SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        switch sourceType {
        case .camera:
            picker.sourceType = .camera
        case .photoLibrary:
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 