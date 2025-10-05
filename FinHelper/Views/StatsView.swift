import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingMonthDetail = false
    @State private var selectedMonth: MonthDetail?
    @State private var showingYearPicker = false
    @State private var monthlyTarget: Double = UserDefaults.standard.double(forKey: "monthlyTarget") // Aylık hedef
    @State private var showingTargetInput = false
    
    struct MonthDetail: Identifiable, Equatable {
        let id = UUID()
        let month: String
        let amount: Double
        let expenses: [Expense]
    }
    
    // Mevcut yıldan başlayarak son 5 yılı göster
    var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return [currentYear]  // Sadece mevcut yıl
    }
    
    // Yıl formatını düzeltme
    private func formatYear(_ year: Int) -> String {
        return "\(year)"
    }
    
    // Seçili yıl için aylık harcamaları hesapla
    func calculateMonthlyExpenses() -> [(String, Double, [Expense])] {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        // Türkçe ay isimleri
        let turkishMonths = [
            "OCAK", "ŞUBAT", "MART", "NİSAN", "MAYIS", "HAZİRAN",
            "TEMMUZ", "AĞUSTOS", "EYLÜL", "EKİM", "KASIM", "ARALIK"
        ]
        
        // Her ay için harcamaları grupla
        var monthlyExpenses: [(String, Double, [Expense])] = []
        
        // Sadece seçili yılın aylarını göster
        let startMonth = (selectedYear == currentYear) ? 0 : 0
        let endMonth = (selectedYear == currentYear) ? currentMonth - 1 : 11
        
        for monthIndex in startMonth...endMonth {
            let monthExpenses = viewModel.personalExpenses.filter { expense in
                let expenseYear = calendar.component(.year, from: expense.date)
                let expenseMonth = calendar.component(.month, from: expense.date) - 1
                return expenseYear == selectedYear && expenseMonth == monthIndex
            }
            
            let totalAmount = monthExpenses.reduce(0) { $0 + $1.amount }
            
            // Harcama olan ayları ekle
            if totalAmount > 0 {
                monthlyExpenses.append((turkishMonths[monthIndex], totalAmount, monthExpenses))
            }
        }
        
        return monthlyExpenses.reversed()
    }
    
    // Aylık ortalama harcama
    private var monthlyAverage: Double {
        let expenses = calculateMonthlyExpenses()
        guard !expenses.isEmpty else { return 0 }
        let total = expenses.reduce(0) { $0 + $1.1 }
        return total / Double(expenses.count)
    }
    
    // Önceki aya göre değişim yüzdesi
    private func calculateMonthlyChange() -> (Double, Bool)? {
        let expenses = calculateMonthlyExpenses()
        guard expenses.count >= 2 else { return nil }
        
        let currentMonth = expenses[0].1
        let previousMonth = expenses[1].1
        
        guard previousMonth > 0 else { return nil }
        
        let change = ((currentMonth - previousMonth) / previousMonth) * 100
        return (abs(change), change >= 0)
    }
    
    // Kategori bazlı trend analizi
    private func calculateCategoryTrends() -> [(ExpenseCategory, Double, Bool)] {
        let expenses = calculateMonthlyExpenses()
        guard expenses.count >= 2 else { return [] }
        
        let currentMonthExpenses = expenses[0].2
        let previousMonthExpenses = expenses[1].2
        
        var trends: [(ExpenseCategory, Double, Bool)] = []
        
        for category in ExpenseCategory.allCases {
            let currentTotal = currentMonthExpenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            let previousTotal = previousMonthExpenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            
            if currentTotal > 0 || previousTotal > 0 {
                let change = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal) * 100 : 100
                trends.append((category, abs(change), change >= 0))
            }
        }
        
        return trends.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Yıl seçici
                Button(action: { showingYearPicker = true }) {
                    HStack {
                            Text(formatYear(selectedYear))
                            .font(.title2.bold())
                        Image(systemName: "chevron.down")
                            .font(.headline)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                    
                    // Özet kartları
                    HStack(spacing: 12) {
                        // Aylık ortalama
                        VStack(spacing: 4) {
                            Text("Aylık Ortalama")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("₺\(monthlyAverage, specifier: "%.0f")")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Aylık değişim
                        if let (change, isIncrease) = calculateMonthlyChange() {
                            VStack(spacing: 4) {
                                Text("Aylık Değişim")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                HStack(spacing: 2) {
                                    Image(systemName: isIncrease ? "arrow.up" : "arrow.down")
                                    Text("%\(change, specifier: "%.1f")")
                                }
                                .font(.headline)
                                .foregroundColor(isIncrease ? .red : .green)
                            }
                            .frame(maxWidth: .infinity)
                .padding()
                            .background(Color(isIncrease ? .red : .green).opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Aylık hedef
                    VStack(spacing: 8) {
                        HStack {
                            Text("Aylık Hedef")
                                .font(.headline)
                            Spacer()
                            Button(action: { showingTargetInput = true }) {
                                Image(systemName: "pencil")
                            }
                        }
                        
                        if let currentMonthAmount = calculateMonthlyExpenses().first?.1 {
                            let progress = monthlyTarget > 0 ? min(currentMonthAmount / monthlyTarget, 1.0) : 0
                            VStack(spacing: 8) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 20)
                                            .cornerRadius(10)
                                        
                                        Rectangle()
                                            .fill(progress >= 1.0 ? Color.red : Color.blue)
                                            .frame(width: geometry.size.width * progress, height: 20)
                                            .cornerRadius(10)
                                    }
                                }
                                .frame(height: 20)
                                
                                HStack {
                                    Text("₺\(currentMonthAmount, specifier: "%.0f")")
                                    Spacer()
                                    Text("₺\(monthlyTarget, specifier: "%.0f")")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                                }
                            }
                        }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Kategori trendleri
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kategori Trendleri")
                            .font(.headline)
                        
                        ForEach(calculateCategoryTrends(), id: \.0) { category, change, isIncrease in
                            HStack {
                                // Kategori için emoji veya varsayılan ikon
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(uiColor: .systemGray6))
                                        .frame(width: 30, height: 30)
                                    
                                    Text(category.icon)
                                        .font(.system(size: 18))
                                }
                                
                                Text(category.rawValue)
                                    .font(.subheadline)
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: isIncrease ? "arrow.up" : "arrow.down")
                                    Text("%\(change, specifier: "%.1f")")
                                }
                                .foregroundColor(isIncrease ? .red : .green)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                // Aylık harcamalar listesi
                    VStack(spacing: 12) {
                        let monthlyExpenses = calculateMonthlyExpenses()
                        let maxAmount = monthlyExpenses.map { $0.1 }.max() ?? 1
                        
                        ForEach(monthlyExpenses, id: \.0) { month, amount, expenses in
                            Button(action: {
                                selectedMonth = MonthDetail(month: month, amount: amount, expenses: expenses)
                            }) {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text(month)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("₺\(amount, specifier: "%.0f")")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 8)
                                                .cornerRadius(4)
                                            
                                            Rectangle()
                                                .fill(Color.blue)
                                                .frame(width: calculateBarWidth(amount: amount, maxAmount: maxAmount, totalWidth: geometry.size.width), height: 8)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("İstatistikler")
            .sheet(isPresented: $showingYearPicker) {
                NavigationView {
                    List(availableYears, id: \.self) { year in
                        Button(action: {
                            selectedYear = year
                            showingYearPicker = false
                        }) {
                            HStack {
                                Text(formatYear(year))
                                    .foregroundColor(.primary)
                                Spacer()
                                if year == selectedYear {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .navigationTitle("Yıl Seçin")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Kapat") {
                                showingYearPicker = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTargetInput) {
                    NavigationView {
                    Form {
                        Section(header: Text("Aylık Harcama Hedefi")) {
                            TextField("Hedef Tutar", value: $monthlyTarget, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                        }
                    }
                    .navigationTitle("Hedef Belirle")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Kaydet") {
                                UserDefaults.standard.set(monthlyTarget, forKey: "monthlyTarget")
                                showingTargetInput = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Vazgeç") {
                                showingTargetInput = false
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedMonth) { monthDetail in
                NavigationView {
                    MonthDetailView(month: monthDetail.month, amount: monthDetail.amount, expenses: monthDetail.expenses)
                        .navigationBarItems(trailing: Button("Kapat") {
                            selectedMonth = nil
                        })
                }
            }
        }
    }
    
    private func calculateBarWidth(amount: Double, maxAmount: Double, totalWidth: CGFloat) -> CGFloat {
        let ratio = amount / maxAmount
        return CGFloat(ratio) * totalWidth
    }
}

// Kategori kartı bileşeni
struct CategoryCard: View {
    let icon: String
    let name: String
    let amount: String
    
    var body: some View {
        VStack {
            Text(icon)
                .font(.system(size: 30))
            Text(name)
                .font(.headline)
            Text(amount)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
} 