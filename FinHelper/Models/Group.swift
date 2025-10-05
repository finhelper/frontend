import Foundation

// Grup modelini tanımlayan yapı
struct Group: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [String]
    var expenses: [Expense]
    var date: Date
    var icon: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, members, expenses, date, icon
    }
    
    // Gruptaki toplam harcama (borç ödemeleri hariç)
    var totalExpenses: Double {
        expenses.filter { $0.title != "Borç Ödemesi" }.reduce(0) { $0 + $1.amount }
    }
    
    // Kişi başı borç hesaplama
    func calculateDebts() -> [String: Double] {
        var debts: [String: Double] = [:]
        
        // Her üye için başlangıç borcu 0
        for member in members {
            debts[member] = 0
        }
        
        // Her harcama için borç hesaplama
        for expense in expenses {
            guard let paidBy = expense.paidBy, let splitBetween = expense.splitBetween else {
                continue
            }
            
            if expense.title == "Borç Ödemesi" {
                // Borç ödemesi özel işlem
                // paidBy: borçlu (ödeme yapan)
                // splitBetween[0]: alacaklı (parayı alan)
                if splitBetween.count == 1 {
                    let creditor = splitBetween[0]
                    
                    // Borç ödeme = ters harcama
                    debts[paidBy, default: 0] += expense.amount     // Borçlu: negatiften sıfıra
                    debts[creditor, default: 0] -= expense.amount   // Alacaklı: pozitiften sıfıra
                }
            } else {
                // Normal harcama
                let amountPerPerson = expense.amountPerPerson
                
                // Harcamaya dahil olan her kişi için
                for person in splitBetween {
                    if person != paidBy {
                        // Ödeme yapan kişi dışındaki herkes, ödeme yapan kişiye borçlu
                        debts[person, default: 0] -= amountPerPerson
                        debts[paidBy, default: 0] += amountPerPerson
                    }
                }
            }
        }
        
        return debts
    }
    
    // Grup harcaması ekleme
    mutating func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }
    
    // Grup üyesi ekleme
    mutating func addMember(_ member: String) {
        if !members.contains(member) {
            members.append(member)
        }
    }
    
    // Grup üyesi çıkarma
    mutating func removeMember(_ member: String) {
        members.removeAll { $0 == member }
    }
    
    // Borç ödeme işlemi
    mutating func markDebtAsPaid(from debtor: String, to creditor: String, amount: Double, userId: String) {
        let paymentExpense = Expense(
            title: "Borç Ödemesi",
            amount: amount,
            date: Date(),
            category: .other,
            paidBy: debtor,
            splitBetween: [creditor],
            userId: userId
        )
        expenses.append(paymentExpense)
    }
    
    init(name: String, members: [String], expenses: [Expense], date: Date, icon: String) {
        self.id = UUID()
        self.name = name
        self.members = members
        self.expenses = expenses
        self.date = date
        self.icon = icon
    }
} 