import SwiftUI

struct MonthDetailView: View {
    let month: String
    let amount: Double
    let expenses: [Expense]
    
    // Kategorilere göre harcamaları grupla
    private var expensesByCategory: [(ExpenseCategory, Double)] {
        var categoryTotals: [ExpenseCategory: Double] = [:]
        
        for expense in expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    // Günlük ortalama harcama
    private var dailyAverage: Double {
        let uniqueDays = Set(expenses.map { Calendar.current.startOfDay(for: $0.date) }).count
        return uniqueDays > 0 ? amount / Double(uniqueDays) : 0
    }
    
    // En yüksek harcama günü
    private var highestSpendingDay: (Date, Double)? {
        let groupedByDay = Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
        let dailyTotals = groupedByDay.mapValues { $0.reduce(0) { $0 + $1.amount } }
        return dailyTotals.max { $0.value < $1.value }
    }
    
    // Harcamaları tarihe göre grupla
    private var expensesByDate: [(Date, [Expense])] {
        let grouped = Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Toplam harcama
                VStack(spacing: 8) {
                    Text("Toplam Harcama")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("₺\(amount, specifier: "%.2f")")
                        .font(.system(size: 34, weight: .bold))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Özet kartları
                HStack(spacing: 12) {
                    // Günlük ortalama
                    VStack(spacing: 4) {
                        Text("Günlük Ortalama")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("₺\(dailyAverage, specifier: "%.0f")")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // En yüksek gün
                    if let (date, maxAmount) = highestSpendingDay {
                        VStack(spacing: 4) {
                            Text("En Yüksek Gün")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(formatDate(date))
                                .font(.caption)
                            Text("₺\(maxAmount, specifier: "%.0f")")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                // Kategori dağılımı
                VStack(alignment: .leading, spacing: 16) {
                    Text("Kategori Dağılımı")
                        .font(.headline)
                    
                    ForEach(expensesByCategory, id: \.0) { category, amount in
                        VStack(spacing: 8) {
                            HStack {
                                // Kategori ikonu için daha güzel görünüm
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(uiColor: .systemGray6))
                                        .frame(width: 40, height: 40)
                                    
                                    Text(category.icon)
                                        .font(.system(size: 20))
                                }
                                
                                Text(category.rawValue)
                                    .font(.headline)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("₺\(amount, specifier: "%.2f")")
                                        .font(.headline)
                                    Text("%\((amount / self.amount) * 100, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // İlerleme çubuğu
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: calculateBarWidth(amount: amount, totalWidth: geometry.size.width), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                            }
                        }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Harcama listesi
                VStack(alignment: .leading, spacing: 16) {
                    Text("Harcamalar")
                        .font(.headline)
                    
                    ForEach(expensesByDate, id: \.0) { date, dayExpenses in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(formatDate(date))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                            ForEach(dayExpenses.sorted(by: { $0.date > $1.date })) { expense in
                                VStack {
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
                                                    .font(.title2)
                                            }
                                        }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                            Text(expense.title)
                                        .font(.headline)
                                            Text(formatTime(expense.date))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                        Text("₺\(expense.amount, specifier: "%.2f")")
                                    .font(.headline)
                            }
                                }
                            .padding()
                                .background(Color.white)
                            .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                        }
                    }
            .padding()
            }
        .navigationTitle("\(month) Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func calculateBarWidth(amount: Double, totalWidth: CGFloat) -> CGFloat {
        let ratio = amount / self.amount
        return CGFloat(ratio) * totalWidth
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
} 