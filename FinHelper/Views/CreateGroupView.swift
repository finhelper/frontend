import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var groupName = ""
    @State private var newMemberName = ""
    @State private var members: [String] = []
    @State private var selectedIcon = "🏠"
    
    let icons = ["🏠", "🌍", "🎉", "🍽️", "🎮", "🚗", "💼", "🏖️", "🎭", "⚽️"]
    
    var body: some View {
        NavigationView {
            Form {
                // Grup adı ve ikonu
                Section(header: Text("Grup Detayları")) {
                    TextField("Grup Başlığı", text: $groupName)
                    
                    // İkon seçici
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Text(icon)
                                        .font(.system(size: 30))
                                        .padding(8)
                                        .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Üye ekleme
                Section(header: Text("Üyeler")) {
                    HStack {
                        TextField("Katılımcı Adı", text: $newMemberName)
                        
                        Button("Ekle") {
                            if !newMemberName.isEmpty {
                                members.append(newMemberName)
                                newMemberName = ""
                            }
                        }
                        .disabled(newMemberName.isEmpty)
                    }
                    
                    ForEach(members, id: \.self) { member in
                        HStack {
                            Text(member)
                            Spacer()
                            Button(action: { members.removeAll { $0 == member } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Grup Oluştur")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") {
                        createGroup()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !groupName.isEmpty && !members.isEmpty
    }
    
    private func createGroup() {
        // Mevcut kullanıcıyı otomatik olarak gruba ekleme
        var allMembers = members
        if !allMembers.contains(viewModel.currentUser.name) {
            allMembers.append(viewModel.currentUser.name)
        }
        
        viewModel.createGroup(
            name: groupName,
            members: allMembers,
            icon: selectedIcon
        )
        
        presentationMode.wrappedValue.dismiss()
    }
} 