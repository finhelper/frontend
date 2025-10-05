import SwiftUI
import PhotosUI

struct GroupAddExpenseView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.presentationMode) var presentationMode
    let group: Group // Grup parametresi ekledik
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory = ExpenseCategory.other
    @State private var paidBy = ""
    @State private var splitEqually = true
    @State private var selectedMembers: Set<String> = []
    
    // Görsel seçimi için state'ler
    @State private var selectedEmoji: String?
    @State private var selectedPhoto: UIImage?
    @State private var showingEmojiPicker = false
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            Form {
                // Görsel Seçimi Bölümü (En üstte)
                VisualSelectionSection(
                    selectedEmoji: $selectedEmoji,
                    selectedPhoto: $selectedPhoto,
                    showingEmojiPicker: $showingEmojiPicker,
                    showingImagePicker: $showingImagePicker,
                    selectedPhotoItem: $selectedPhotoItem
                )
                
                // Harcama başlığı
                ExpenseDetailsSection(
                    title: $title,
                    amount: $amount,
                    selectedCategory: $selectedCategory,
                    formatAmountInput: formatAmountInput
                )
                
                // Ödeme yapan kişi
                PayerSelectionSection(
                    group: group,
                    paidBy: $paidBy,
                    viewModel: viewModel
                )
                
                // Bölüşme seçenekleri
                SplitOptionsSection(
                    group: group,
                    splitEqually: $splitEqually,
                    selectedMembers: $selectedMembers
                )
            }
            .navigationTitle("Grup Harcaması Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Vazgeç") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Ekle") {
                    addExpense()
                }
                .disabled(!isFormValid)
            )
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView(selectedEmoji: Binding(
                get: { selectedEmoji ?? "" },
                set: { selectedEmoji = $0.isEmpty ? nil : $0 }
            ), onEmojiSelected: {
                selectedPhoto = nil // Emoji seçildiğinde fotoğrafı temizle
            })
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(sourceType: .camera, selectedImage: $selectedPhoto)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadSelectedPhoto(from: newItem)
        }
        .onChange(of: selectedEmoji) { _, newEmoji in
            if newEmoji != nil {
                selectedPhoto = nil // Emoji seçildiğinde fotoğrafı temizle
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && !paidBy.isEmpty &&
        (splitEqually || (!splitEqually && !selectedMembers.isEmpty))
    }
    
    private func loadSelectedPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task.detached { @MainActor in
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    self.selectedPhoto = uiImage
                    self.selectedEmoji = nil // Fotoğraf seçildiğinde emoji'yi temizle
                }
            } catch {
                print("Fotoğraf yüklenirken hata: \(error)")
            }
        }
    }
    
    private func formatAmountInput(_ input: String) {
        // Sadece rakam, virgül ve nokta kabul et
        let filtered = input.filter { "0123456789.,".contains($0) }
        
        // Birden fazla virgül veya nokta varsa sadece ilkini tut
        var finalAmount = ""
        var decimalSeparatorFound = false
        
        for char in filtered {
            if char == "," || char == "." {
                if !decimalSeparatorFound {
                    finalAmount += ","
                    decimalSeparatorFound = true
                }
            } else {
                finalAmount += String(char)
            }
        }
        
        // Ondalık kısmını en fazla 2 basamakla sınırla
        if let commaIndex = finalAmount.firstIndex(of: ",") {
            let beforeComma = String(finalAmount[..<commaIndex])
            let afterCommaStartIndex = finalAmount.index(after: commaIndex)
            let afterComma = String(finalAmount[afterCommaStartIndex...])
            
            let limitedAfterComma = String(afterComma.prefix(2))
            finalAmount = beforeComma + "," + limitedAfterComma
        }
        
        amount = finalAmount
    }
    
    private func addExpense() {
        guard let amountValue = amount.turkishCurrencyToDouble() else { return }
        
        let splitBetween = splitEqually ? group.members : Array(selectedMembers)
        
        // Fotoğraf verisi hazırla
        var photoData: Data? = nil
        if let photo = selectedPhoto {
            photoData = photo.jpegData(compressionQuality: 0.8)
        }
        
        viewModel.addExpense(
            to: group,
            title: title,
            amount: amountValue,
            paidBy: paidBy,
            splitBetween: splitBetween,
            category: selectedCategory,
            customEmoji: selectedEmoji,
            photoData: photoData
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Alt Bileşenler

struct VisualSelectionSection: View {
    @Binding var selectedEmoji: String?
    @Binding var selectedPhoto: UIImage?
    @Binding var showingEmojiPicker: Bool
    @Binding var showingImagePicker: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        Section(header: Text("Görsel")) {
            VStack(spacing: 16) {
                // Seçilen görsel gösterimi (sadece gösterim, tıklanamaz)
                PreviewArea(selectedEmoji: selectedEmoji, selectedPhoto: selectedPhoto)
                
                // Görsel seçim butonları (ayrı ayrı)
                SelectionButtons(
                    showingEmojiPicker: $showingEmojiPicker,
                    showingImagePicker: $showingImagePicker,
                    selectedPhotoItem: $selectedPhotoItem
                )
            }
            .padding(.vertical, 8)
        }
    }
}

struct PreviewArea: View {
    let selectedEmoji: String?
    let selectedPhoto: UIImage?
    
    var body: some View {
        HStack {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: 80, height: 80)
                
                if let emoji = selectedEmoji {
                    Text(emoji)
                        .font(.system(size: 40))
                } else if let photo = selectedPhoto {
                    Image(uiImage: photo)
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
    }
}

struct SelectionButtons: View {
    @Binding var showingEmojiPicker: Bool
    @Binding var showingImagePicker: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
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
            
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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
                showingImagePicker = true
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

struct ExpenseDetailsSection: View {
    @Binding var title: String
    @Binding var amount: String
    @Binding var selectedCategory: ExpenseCategory
    let formatAmountInput: (String) -> Void
    
    var body: some View {
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
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: amount) { _, newValue in
                            formatAmountInput(newValue)
                        }
                }
                
                Text("Virgül kullanarak ondalık giriniz (örn: 5,50)")
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
}

struct PayerSelectionSection: View {
    let group: Group
    @Binding var paidBy: String
    let viewModel: MainViewModel
    
    var body: some View {
        Section(header: Text("Ödeyen Kişi")) {
            ForEach(group.members, id: \.self) { member in
                Button(action: {
                    paidBy = member
                }) {
                    HStack {
                        // Profil ikonu
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member)
                                .foregroundColor(.primary)
                                .font(.headline)
                            
                            if member == viewModel.currentUser.name {
                                Text("Sen")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        if paidBy == member {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct SplitOptionsSection: View {
    let group: Group
    @Binding var splitEqually: Bool
    @Binding var selectedMembers: Set<String>
    
    var body: some View {
        Section(header: Text("Bölüşme Şekli")) {
            Picker("Bölüşme Tipi", selection: $splitEqually) {
                Text("Eşit Olarak Böl").tag(true)
                Text("Kişileri Seç").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if !splitEqually {
                ForEach(group.members, id: \.self) { member in
                    Button(action: {
                        if selectedMembers.contains(member) {
                            selectedMembers.remove(member)
                        } else {
                            selectedMembers.insert(member)
                        }
                    }) {
                        HStack {
                            // Profil ikonu
                            Image(systemName: "person.circle")
                                .foregroundColor(selectedMembers.contains(member) ? .blue : .gray)
                                .font(.title3)
                            
                            Text(member)
                                .foregroundColor(.primary)
                                .font(.headline)
                            
                            Spacer()
                            
                            if selectedMembers.contains(member) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
} 
