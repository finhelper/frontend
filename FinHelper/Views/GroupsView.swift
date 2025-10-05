import SwiftUI
import PhotosUI
import UIKit

struct GroupsView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group, viewModel: viewModel)) {
                        GroupRow(group: group)
                    }
                }
                .onDelete { indexSet in
                    deleteGroups(at: indexSet)
                }
            }
            .navigationTitle("Gruplar")
            .toolbar {
                Button(action: { showingCreateGroup = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateGroup) {
            CreateGroupView(viewModel: viewModel)
        }
    }
    
    private func deleteGroups(at offsets: IndexSet) {
        viewModel.deleteGroups(at: offsets)
    }
}

// Grup satırı bileşeni
struct GroupRow: View {
    let group: Group
    
    var body: some View {
        HStack {
            Text(group.icon)
                .font(.title)
            VStack(alignment: .leading) {
                Text(group.name)
                    .font(.headline)
                Text("\(group.members.count) Kişi")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// Grup detay görünümü
struct GroupDetailView: View {
    let group: Group
    @ObservedObject var viewModel: MainViewModel
    @State private var showingAddExpense = false
    @State private var selectedTab = 0 // 0: Harcamalar, 1: Bakiyeler
    @State private var showingDebtDetail = false
    @State private var selectedExpense: Expense?
    @State private var selectedPerson: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Grup başlığı
            HStack {
                Text(group.icon)
                    .font(.title)
                Text(group.name)
                    .font(.title2)
                Spacer()
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            
            // Sekmeler
            HStack(spacing: 0) {
                TabButton(title: "Harcamalar", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Bakiyeler", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .padding(.horizontal)
            
            if selectedTab == 0 {
                // Harcamalar Görünümü
                VStack(spacing: 0) {
                    // Özet kartları
                    HStack(spacing: 15) {
                        SummaryCard(title: "Harcamlarım", amount: calculateMyExpenses())
                        SummaryCard(title: "Toplam Harcananlar", amount: group.totalExpenses)
                    }
                    .padding()
                    
                    // Harcama listesi
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(groupExpensesByDate(), id: \.0) { date, expenses in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(formatDate(date))
                                        .font(.headline)
                                        .padding(.horizontal)
                                        .padding(.top, 16)
                                    
                                    ForEach(expenses) { expense in
                                        ExpenseRowView(expense: expense) {
                                            selectedExpense = expense
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                deleteExpense(expense)
                                            } label: {
                                                Label("Sil", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // Bakiyeler Görünümü
                VStack(spacing: 16) {
                    Text("Bakiyeler")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Kişilerin bakiyeleri
                    ScrollView {
                    VStack(spacing: 8) {
                        ForEach(group.members, id: \.self) { member in
                            if let debt = group.calculateDebts()[member] {
                                Button(action: {
                                    selectedPerson = member
                                }) {
                                HStack {
                                    // Profil resmi
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                            .foregroundColor(.blue)
                                    
                                    // Kişi adı ve durumu
                                        VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(member)
                                                .font(.headline)
                                                    .foregroundColor(.primary)
                                            if member == viewModel.currentUser.name {
                                                    Text("Sen")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.2))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(8)
                                            }
                                        }
                                            
                                            if debt < 0 {
                                                Text("Borçlu")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            } else if debt > 0 {
                                                Text("Alacaklı")
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            } else {
                                                Text("Eşit")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                        // Borç miktarı ve ok işareti
                                        HStack(spacing: 8) {
                                            Text(abs(debt).formatAsTurkishCurrency())
                                        .font(.headline)
                                        .foregroundColor(debt >= 0 ? .green : .red)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    }
                }
                .sheet(isPresented: $showingDebtDetail) {
                    NavigationView {
                        DebtDetailView(group: group, viewModel: viewModel)
                    }
                }
            }
            
            Spacer()
            
            // Harcama Ekle Butonu
            Button(action: { showingAddExpense = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.bottom, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExpense) {
            GroupAddExpenseView(viewModel: viewModel, group: group)
        }
        .sheet(item: $selectedExpense) { expense in
            NavigationView {
                GroupExpenseDetailView(
                    expense: expense,
                    group: group,
                    viewModel: viewModel,
                    onDismiss: { selectedExpense = nil }
                )
            }
        }
        .sheet(item: Binding<PersonWrapper?>(
            get: { selectedPerson.map(PersonWrapper.init) },
            set: { _ in selectedPerson = nil }
        )) { personWrapper in
            PersonDebtDetailView(
                person: personWrapper.name,
                group: group,
                viewModel: viewModel
            )
        }
    }
    
    private func calculateMyExpenses() -> Double {
        let myExpenses = group.expenses.filter { 
            $0.paidBy == viewModel.currentUser.name && $0.title != "Borç Ödemesi" 
        }
        return myExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private func groupExpensesByDate() -> [(Date, [Expense])] {
        let grouped = Dictionary(grouping: group.expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    // Toplam borç hesaplama
    private func calculateTotalDebt() -> Double? {
        let debts = group.calculateDebts()
        return debts[viewModel.currentUser.name]
    }
    
    // Borçlu kişileri bulma
    private func getBorclular() -> String {
        let debts = group.calculateDebts()
        let borclular = group.members.filter { member in
            if let debt = debts[member], debt < 0 {
                return true
            }
            return false
        }
        
        if borclular.isEmpty {
            return "Kimse borçlu değil"
        } else if borclular.count == 1 {
            return "\(borclular[0]) sana borçlu"
        } else {
            return "\(borclular[0]) ve \(borclular.count - 1) kişi daha sana borçlu"
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        viewModel.deleteGroupExpense(groupId: group.id, expenseId: expense.id)
    }
    

}

// Kişi wrapper'ı (sheet için gerekli)
struct PersonWrapper: Identifiable {
    let id = UUID()
    let name: String
}

// Tab Butonu
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .primary : .gray)
                Rectangle()
                    .fill(isSelected ? Color.gray : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// Özet Kartı
struct SummaryCard: View {
    let title: String
    let amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(amount.formatAsTurkishCurrency())
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// Harcama Satırı
struct ExpenseRowView: View {
    let expense: Expense
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
        HStack {
            // Görsel (Emoji, Fotoğraf veya Kategori İkonu)
            ZStack {
                if let emoji = expense.customEmoji {
                    Text(emoji)
                        .font(.system(size: 24))
                } else if let photoData = expense.photoData,
                          let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
            CategoryIcon(category: expense.category)
                .font(.system(size: 24))
                }
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    if let paidBy = expense.paidBy {
                        Text("\(paidBy) Tarafından Ödendi")
                    .font(.caption)
                    .foregroundColor(.gray)
                    }
            }
            
            Spacer()
            
                Text(expense.amount.formatAsTurkishCurrency())
                .font(.headline)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Kategori İkonu
struct CategoryIcon: View {
    let category: ExpenseCategory
    
    var body: some View {
        switch category {
        case .food:
            Text("🍕")
        case .transportation:
            Text("⛽️")
        case .accommodation:
            Text("🏨")
        case .health:
            Text("💊")
        case .other:
            Text("💰")
        }
    }
}

// Grup harcama detay görünümü
struct GroupExpenseDetailView: View {
    let expense: Expense
    let group: Group
    @ObservedObject var viewModel: MainViewModel
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: ExpenseCategory
    @State private var paidBy: String
    @State private var splitEqually: Bool
    @State private var selectedMembers: Set<String>
    
    // Görsel seçimi için state'ler
    @State private var selectedEmoji: String?
    @State private var selectedPhoto: UIImage?
    @State private var showingEmojiPicker = false
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    init(expense: Expense, group: Group, viewModel: MainViewModel, onDismiss: @escaping () -> Void) {
        self.expense = expense
        self.group = group
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        _title = State(initialValue: expense.title)
        _amount = State(initialValue: expense.amount.toTurkishCurrencyInput())
        _selectedCategory = State(initialValue: expense.category)
        _paidBy = State(initialValue: expense.paidBy ?? "")
        _splitEqually = State(initialValue: expense.splitBetween == nil || expense.splitBetween == group.members)
        _selectedMembers = State(initialValue: Set(expense.splitBetween ?? []))
        _selectedEmoji = State(initialValue: expense.customEmoji)
        
        // Fotoğrafı UIImage olarak yükle
        if let photoData = expense.photoData {
            _selectedPhoto = State(initialValue: UIImage(data: photoData))
        }
    }
    
    var body: some View {
        NavigationView {
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
                
                Section(header: Text("Ödeyen Kişi")) {
                    ForEach(group.members, id: \.self) { member in
                        Button(action: {
                            paidBy = member
                        }) {
                            HStack {
                                Text(member)
                                    .foregroundColor(.primary)
                                Spacer()
                                if paidBy == member {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
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
                                    Text(member)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedMembers.contains(member) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: saveChanges) {
                        Text("Değişiklikleri Kaydet")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                }

                Section {
                    Button(action: deleteExpense) {
                        Text("Harcamayı Sil")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Grup Harcaması Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
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
        updatedExpense.paidBy = paidBy
        updatedExpense.splitBetween = splitEqually ? group.members : Array(selectedMembers)
        updatedExpense.customEmoji = selectedEmoji
        updatedExpense.photoData = photoData
        
        viewModel.updateGroupExpense(groupId: group.id, expense: updatedExpense)
        
        dismiss()
        onDismiss()
    }

    private func deleteExpense() {
        viewModel.deleteGroupExpense(groupId: group.id, expenseId: expense.id)
        dismiss()
        onDismiss()
    }
} 