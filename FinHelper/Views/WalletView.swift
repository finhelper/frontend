import SwiftUI
import PhotosUI

struct WalletView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingAddExpense = false
    @State private var showingExpenseDetail = false
    @State private var selectedExpense: Expense?
    
    var body: some View {
        NavigationView {
            VStack {
                // Kullanıcı profil bilgisi
                HStack {
                    // Kullanıcının profil görseli
                    VStack {
                        if let photoData = viewModel.currentUser.photoData, 
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else if let avatar = viewModel.currentUser.avatarType {
                            Text(avatar.rawValue)
                                .font(.system(size: 35))
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(viewModel.currentUser.name)
                            .font(.headline)
                        Text("Aylık Harcamalarım")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                
                // Toplam harcama göstergesi
                if let totalExpense = viewModel.totalExpenses {
                    Text(totalExpense.formatAsTurkishCurrency())
                        .font(.system(size: 40, weight: .bold))
                        .padding()
                } else {
                    Text("₺0,00")
                    .font(.system(size: 40, weight: .bold))
                    .padding()
                }
                
                // Harcama listesi
                if viewModel.expenses.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Henüz harcama bulunmuyor")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Yeni harcama eklemek için + butonuna tıklayın")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    Spacer()
                } else {
                List {
                        ForEach(viewModel.expenses) { expense in
                            Button(action: {
                                selectedExpense = expense
                            }) {
                                ExpenseRow(expense: expense)
                            }
                    }
                    .onDelete { indexSet in
                            deleteExpenses(at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Cüzdan")
            .navigationBarItems(trailing:
                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus")
                }
            )
        }
        .sheet(isPresented: $showingAddExpense) {
            NavigationView {
                WalletAddExpenseView(viewModel: viewModel)
            }
        }
        .sheet(item: $selectedExpense) { expense in
            NavigationView {
                ExpenseDetailView(expense: expense, viewModel: viewModel) {
                    selectedExpense = nil
                }
            }
        }
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            let expense = viewModel.expenses[index]
            viewModel.deleteExpense(expense)
        }
    }
}

// Harcama satırı bileşeni
struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            // Emoji, fotoğraf veya kategori ikonu
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: 50, height: 50)
                
                if let customEmoji = expense.customEmoji, !customEmoji.isEmpty {
                    // Özel emoji göster
                    Text(customEmoji)
                        .font(.system(size: 25))
                } else if let photoData = expense.photoData, let uiImage = UIImage(data: photoData) {
                    // Fotoğraf göster
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Varsayılan kategori ikonu
                    Text(expense.category.icon)
                .font(.title)
                }
            }
            
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.headline)
                Text(expense.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(expense.amount.formatAsTurkishCurrency())
                .font(.headline)
        }
        .padding(.vertical, 8)
    }
}

// Harcama detay görünümü
struct ExpenseDetailView: View {
    let expense: Expense
    @ObservedObject var viewModel: MainViewModel
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: ExpenseCategory
    
    // Görsel seçimi için state'ler
    @State private var selectedEmoji: String?
    @State private var selectedPhoto: UIImage?
    @State private var showingEmojiPicker = false
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    init(expense: Expense, viewModel: MainViewModel, onDismiss: @escaping () -> Void) {
        self.expense = expense
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        // State değişkenlerini başlangıç değerleriyle ayarla
        _title = State(initialValue: expense.title)
        
        // Para formatını Türkçe formatına çevir
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        let formattedAmount = formatter.string(from: NSNumber(value: expense.amount)) ?? "0,00"
        _amount = State(initialValue: formattedAmount)
        
        _selectedCategory = State(initialValue: expense.category)
        _selectedEmoji = State(initialValue: expense.customEmoji)
        
        // Fotoğrafı UIImage olarak yükle
        if let photoData = expense.photoData {
            _selectedPhoto = State(initialValue: UIImage(data: photoData))
        }
    }
    
    var body: some View {
            Form {
                // Görsel Seçimi Bölümü
                Section(header: Text("Görsel")) {
                    VStack(spacing: 16) {
                        // Seçilen görsel gösterimi
                        HStack {
                            Spacer()
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                                    .frame(width: 80, height: 80)
                                
                                if let emoji = selectedEmoji, !emoji.isEmpty {
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
                        
                        // Görsel seçim butonları
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
                    .padding(.vertical, 8)
                }
                
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
                
                Section {
                    Button(action: saveChanges) {
                        Text("Değişiklikleri Kaydet")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                
                Button(action: deleteExpense) {
                    Text("Harcamayı Sil")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.red)
                }
                }
            }
            .navigationTitle("Harcama Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
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
    
    private func saveChanges() {
        guard let amountValue = amount.turkishCurrencyToDouble() else { return }
        
        // Fotoğraf verisi hazırla
        var photoData: Data? = nil
        if let photo = selectedPhoto {
            photoData = photo.jpegData(compressionQuality: 0.8)
        }
        
        var updatedExpense = expense
        updatedExpense.title = title
        updatedExpense.amount = amountValue
        updatedExpense.category = selectedCategory
        updatedExpense.customEmoji = selectedEmoji
        updatedExpense.photoData = photoData
        
        // Harcamayı güncelle
        viewModel.updateExpense(updatedExpense)
        
        dismiss()
        onDismiss()
    }
    
    private func deleteExpense() {
        viewModel.deleteExpense(expense)
        dismiss()
        onDismiss()
    }
} 