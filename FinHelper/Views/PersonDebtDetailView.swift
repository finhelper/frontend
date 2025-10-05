import SwiftUI

struct PersonDebtDetailView: View {
    let person: String
    let group: Group
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaymentSheet = false
    @State private var selectedCreditor: String = ""
    @State private var selectedDebtAmount: Double = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
                // Kişi Başlığı
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(person)
                        .font(.title2.bold())
                    
                    if person == viewModel.currentUser.name {
                        Text("Sen")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemGroupedBackground))
                
                // Borç Detayları
                ScrollView {
                    VStack(spacing: 16) {
                        let debtDetails = calculatePersonDebts()
                        
                        if !debtDetails.isEmpty {
                            Text("Borç Durumu")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ForEach(debtDetails, id: \.creditor) { debt in
                                SimpleDebtCard(
                                    debt: debt,
                                    person: person,
                                    viewModel: viewModel,
                                    onPayment: { creditor, amount in
                                        selectedCreditor = creditor
                                        selectedDebtAmount = amount
                                        showingPaymentSheet = true
                                    }
                                )
                            }
                        } else {
                            // Borç yok durumu
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                
                                Text("Harika!")
                                    .font(.title2.bold())
                                
                                Text(person == viewModel.currentUser.name ? "Hiç borcun yok!" : "\(person)'in hiç borcu yok!")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 50)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Borç Detayları")
            .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentSheetWrapper(
                person: person,
                selectedCreditor: selectedCreditor,
                group: group,
                viewModel: viewModel,
                onComplete: { dismiss() }
            )
        }
    }
    
    // Detaylı borç hesaplaması - her alacaklıya olan borcu ayrı hesapla
    private func calculatePersonDebts() -> [SimpleDebtInfo] {
        var detailedDebts: [SimpleDebtInfo] = []
        
        // Her harcama için bu kişinin borcunu hesapla
        for expense in group.expenses {
            // Borç ödemelerini atla
            if expense.title == "Borç Ödemesi" {
                continue
            }
            
            guard let paidBy = expense.paidBy, 
                  let splitBetween = expense.splitBetween,
                  splitBetween.contains(person), // Bu kişi harcamaya dahil mi?
                  paidBy != person else { // Kendisi ödememişse
                continue
            }
            
            // Bu harcamada kişi başı düşen miktar
            let amountPerPerson = expense.amountPerPerson
            
            // Bu harcamayı ödeyen kişiye olan borcu ekle/güncelle
            if let existingDebtIndex = detailedDebts.firstIndex(where: { $0.creditor == paidBy }) {
                detailedDebts[existingDebtIndex].amount += amountPerPerson
            } else {
                detailedDebts.append(SimpleDebtInfo(creditor: paidBy, amount: amountPerPerson))
            }
        }
        
        // Borç ödemelerini hesaba kat (borcu azaltır)
        for expense in group.expenses {
            if expense.title == "Borç Ödemesi",
               let paidBy = expense.paidBy,
               let splitBetween = expense.splitBetween,
               paidBy == person, // Bu kişi ödeme yapmışsa
               splitBetween.count == 1 {
                
                let creditor = splitBetween[0]
                
                // Bu alacaklıya olan borcu azalt
                if let existingDebtIndex = detailedDebts.firstIndex(where: { $0.creditor == creditor }) {
                    detailedDebts[existingDebtIndex].amount -= expense.amount
                    
                    // Eğer borç 0 veya negatif olduysa kaldır
                    if detailedDebts[existingDebtIndex].amount <= 0.01 {
                        detailedDebts.remove(at: existingDebtIndex)
                    }
                }
            }
        }
        
        // Sadece pozitif borçları döndür (yuvarlama hatasını önle)
        return detailedDebts.filter { $0.amount > 0.01 }
    }
}

// Basit borç bilgisi
struct SimpleDebtInfo {
    let creditor: String
    var amount: Double
}

// Basit borç kartı
struct SimpleDebtCard: View {
    let debt: SimpleDebtInfo
    let person: String
    @ObservedObject var viewModel: MainViewModel
    let onPayment: (String, Double) -> Void
    
    var body: some View {
        HStack {
            // Alacaklı bilgisi
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(.gray)
                    Text(debt.creditor)
                        .font(.headline)
                    
                    if debt.creditor == viewModel.currentUser.name {
                        Text("Sen")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(person == viewModel.currentUser.name ? "Borcun" : "\(person)'in borcu")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Borç miktarı ve ödeme butonu
            VStack(alignment: .trailing, spacing: 8) {
                Text(debt.amount.formatAsTurkishCurrency())
                    .font(.title3.bold())
                    .foregroundColor(.red)
                
                                                Button(action: {
                                    onPayment(debt.creditor, debt.amount)
                                }) {
                    Text("Ödeme Yap")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// Basit ödeme sayfası
struct SimplePaymentSheet: View {
    let debtor: String
    let creditor: String
    let maxAmount: Double
    let group: Group
    @ObservedObject var viewModel: MainViewModel
    let onPaymentComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var paymentAmount: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Başlık bilgisi
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Ödeme Yap")
                        .font(.title2.bold())
                    
                    Text("\(debtor) → \(creditor)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Toplam Borç: \(maxAmount.formatAsTurkishCurrency())")
                        .font(.body.bold())
                        .foregroundColor(.red)
                }
                .padding()
                
                // Ödeme miktarı girişi
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ödeme Miktarı")
                        .font(.headline)
                    
                    HStack {
                        Text("₺")
                            .font(.title2)
                            .foregroundColor(.gray)
                        TextField("0,00", text: $paymentAmount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: paymentAmount) { _, newValue in
                                formatPaymentInput(newValue)
                            }
                    }
                    
                    // Hızlı seçim butonları
                    HStack(spacing: 12) {
                        Button("Tamamını Öde") {
                            paymentAmount = maxAmount.toTurkishCurrencyInput()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                        
                        Button("Yarısını Öde") {
                            paymentAmount = (maxAmount / 2).toTurkishCurrencyInput()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Ödeme butonu
                Button(action: processPayment) {
                    Text("Ödeme Yap")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidPayment() ? Color.green : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValidPayment())
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Ödeme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Sayfa açıldığında maksimum tutarı otomatik doldur (2 ondalık basamağa yuvarlanmış)
            let roundedMaxAmount = (maxAmount * 100).rounded() / 100
            paymentAmount = roundedMaxAmount.toTurkishCurrencyInput()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("Tamam", role: .cancel) {
                if alertTitle == "Başarılı!" {
                    onPaymentComplete()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func formatPaymentInput(_ input: String) {
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
        
        paymentAmount = finalAmount
    }
    
    private func isValidPayment() -> Bool {
        guard let amount = paymentAmount.turkishCurrencyToDouble() else { 
            return false 
        }
        
        // Para miktarlarını 2 ondalık basamağa yuvarla
        let roundedAmount = (amount * 100).rounded() / 100
        let roundedMaxAmount = (maxAmount * 100).rounded() / 100
        
        // 0.01 TL tolerance ile karşılaştır
        return roundedAmount > 0 && roundedAmount <= roundedMaxAmount + 0.01
    }
    
    private func processPayment() {
        guard let amount = paymentAmount.turkishCurrencyToDouble() else {
            alertTitle = "Hata"
            alertMessage = "Geçerli bir miktar girin"
            showingAlert = true
            return
        }
        
        // Para miktarlarını 2 ondalık basamağa yuvarla
        let roundedAmount = (amount * 100).rounded() / 100
        let roundedMaxAmount = (maxAmount * 100).rounded() / 100
        
        guard roundedAmount <= roundedMaxAmount + 0.01 else {
            alertTitle = "Hata"
            alertMessage = "Ödeme miktarı borç miktarından fazla olamaz"
            showingAlert = true
            return
        }
        
        // Ödeme işlemini gerçekleştir (yuvarlanan miktar ile)
        var updatedGroup = group
        updatedGroup.markDebtAsPaid(
            from: debtor,
            to: creditor,
            amount: roundedAmount,
            userId: viewModel.currentUser.id
        )
        viewModel.updateGroup(updatedGroup)
        
        // Başarı mesajı göster
        alertTitle = "Başarılı!"
        alertMessage = "\(roundedAmount.formatAsTurkishCurrency()) ödeme başarıyla yapıldı!"
        showingAlert = true
    }
}

// PaymentSheet Wrapper
struct PaymentSheetWrapper: View {
    let person: String
    let selectedCreditor: String
    let group: Group
    @ObservedObject var viewModel: MainViewModel
    let onComplete: () -> Void
    
    var body: some View {
        // selectedCreditor boşsa, hesaplanmış ana alacaklıyı kullan
        let groupDebts = group.calculateDebts()
        let creditorToUse = selectedCreditor.isEmpty ? (groupDebts.filter { $0.value > 0 && $0.key != person }.max(by: { $0.value < $1.value })?.key ?? "") : selectedCreditor
        
        // Bu kişinin sadece seçilen alacaklıya olan borcunu hesapla
        let detailedDebts = calculatePersonDebtsHelper(person: person, group: group)
        let debtToCreditor = detailedDebts.first(where: { $0.creditor == creditorToUse })?.amount ?? 0.0
        
        return SimplePaymentSheet(
            debtor: person,
            creditor: creditorToUse,
            maxAmount: debtToCreditor,
            group: group,
            viewModel: viewModel,
            onPaymentComplete: onComplete
        )
    }
    
    // Detaylı borç hesaplaması helper fonksiyonu
    private func calculatePersonDebtsHelper(person: String, group: Group) -> [SimpleDebtInfo] {
        var detailedDebts: [SimpleDebtInfo] = []
        
        // Her harcama için bu kişinin borcunu hesapla
        for expense in group.expenses {
            // Borç ödemelerini atla
            if expense.title == "Borç Ödemesi" {
                continue
            }
            
            guard let paidBy = expense.paidBy, 
                  let splitBetween = expense.splitBetween,
                  splitBetween.contains(person), // Bu kişi harcamaya dahil mi?
                  paidBy != person else { // Kendisi ödememişse
                continue
            }
            
            // Bu harcamada kişi başı düşen miktar
            let amountPerPerson = expense.amountPerPerson
            
            // Bu harcamayı ödeyen kişiye olan borcu ekle/güncelle
            if let existingDebtIndex = detailedDebts.firstIndex(where: { $0.creditor == paidBy }) {
                detailedDebts[existingDebtIndex].amount += amountPerPerson
            } else {
                detailedDebts.append(SimpleDebtInfo(creditor: paidBy, amount: amountPerPerson))
            }
        }
        
        // Borç ödemelerini hesaba kat (borcu azaltır)
        for expense in group.expenses {
            if expense.title == "Borç Ödemesi",
               let paidBy = expense.paidBy,
               let splitBetween = expense.splitBetween,
               paidBy == person, // Bu kişi ödeme yapmışsa
               splitBetween.count == 1 {
                
                let creditor = splitBetween[0]
                
                // Bu alacaklıya olan borcu azalt
                if let existingDebtIndex = detailedDebts.firstIndex(where: { $0.creditor == creditor }) {
                    detailedDebts[existingDebtIndex].amount -= expense.amount
                    
                    // Eğer borç 0 veya negatif olduysa kaldır
                    if detailedDebts[existingDebtIndex].amount <= 0.01 {
                        detailedDebts.remove(at: existingDebtIndex)
                    }
                }
            }
        }
        
        // Sadece pozitif borçları döndür (yuvarlama hatasını önle)
        return detailedDebts.filter { $0.amount > 0.01 }
    }
} 