import SwiftUI

struct DebtDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let group: Group
    @ObservedObject var viewModel: MainViewModel
    @State private var showingPaymentAlert = false
    @State private var selectedMember: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst kısım
            VStack(spacing: 16) {
                Text("Sana Borçlu")
                    .font(.title2.bold())
                
                Text(calculateTotalDebt().formatAsTurkishCurrency())
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color(uiColor: .systemBackground))
            
            // Borçlu listesi
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(getBorclular(), id: \.self) { member in
                        if let debt = group.calculateDebts()[member], debt < 0 {
                            DebtMemberCard(
                                memberName: member,
                                amount: abs(debt),
                                onMarkAsPaid: {
                                    selectedMember = member
                                    showingPaymentAlert = true
                                },
                                onRequestPayment: {
                                    // Ödeme talebi gönderme işlemi
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Kapat") {
                    dismiss()
                }
            }
        }
        .alert("Ödeme Onayı", isPresented: $showingPaymentAlert) {
            Button("İptal", role: .cancel) { }
            Button("Onayla") {
                if let member = selectedMember {
                    markDebtAsPaid(for: member)
                }
            }
        } message: {
            if let member = selectedMember {
                Text("\(member) borcunu ödedi olarak işaretlensin mi?")
            }
        }
    }
    
    private func calculateTotalDebt() -> Double {
        let debts = group.calculateDebts()
        var total = 0.0
        for (member, debt) in debts {
            if debt < 0 && member != viewModel.currentUser.name {
                total += abs(debt)
            }
        }
        return total
    }
    
    private func getBorclular() -> [String] {
        let debts = group.calculateDebts()
        return group.members.filter { member in
            if let debt = debts[member], debt < 0 && member != viewModel.currentUser.name {
                return true
            }
            return false
        }
    }
    
    private func markDebtAsPaid(for member: String) {
        // Borç ödendi olarak işaretleme işlemi
        // Bu kısım backend entegrasyonunda implement edilecek
    }
}

struct DebtMemberCard: View {
    let memberName: String
    let amount: Double
    let onMarkAsPaid: () -> Void
    let onRequestPayment: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Kişi bilgisi
            VStack(spacing: 8) {
                Text("\(memberName), Sühan'a borçlu")
                    .font(.headline)
                Text(amount.formatAsTurkishCurrency())
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.top)
            
            // Butonlar
            HStack(spacing: 12) {
                Button(action: onMarkAsPaid) {
                    Text("Ödendi Olarak İşaretle")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                
                Button(action: onRequestPayment) {
                    Text("Ödeme Talep Et")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .systemGray5))
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
} 