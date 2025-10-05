import Foundation

// Para formatı için extension
extension Double {
    func formatAsTurkishCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        
        if let formatted = formatter.string(from: NSNumber(value: self)) {
            return "₺\(formatted)"
        }
        return "₺0,00"
    }
    
    // Double'dan türkçe para girişi formatına çevirici (düzenleme için)
    func toTurkishCurrencyInput() -> String {
        // Sayıyı Türkçe formatında (virgül ile) string'e çevir
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        
        if let formatted = formatter.string(from: NSNumber(value: self)) {
            return formatted
        }
        return "0,00"
    }
    
    // Para hesaplamalarında precision hatalarını önlemek için yuvarlama fonksiyonu
    func roundToCurrency() -> Double {
        return (self * 100).rounded() / 100
    }
}

// String'den Double'a Türkçe formatında çevirici
extension String {
    func turkishCurrencyToDouble() -> Double? {
        let cleaned = self.replacingOccurrences(of: ".", with: "")
                         .replacingOccurrences(of: ",", with: ".")
                         .replacingOccurrences(of: "₺", with: "")
                         .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
} 