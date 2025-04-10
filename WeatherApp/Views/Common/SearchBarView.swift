import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onCommit: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for a city", text: $searchText)
                    .focused($isFocused)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        onCommit()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .animation(.default, value: searchText)
            .onTapGesture {
                isSearching = true
                isFocused = true
            }
            
            if isSearching {
                Button("Cancel") {
                    searchText = ""
                    isSearching = false
                    onCancel()
                    isFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .transition(.move(edge: .trailing))
                .animation(.default, value: isSearching)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        SearchBarView(
            searchText: .constant("London"),
            isSearching: .constant(false),
            onCommit: {},
            onCancel: {}
        )
        .padding(.vertical)
        
        SearchBarView(
            searchText: .constant(""),
            isSearching: .constant(true),
            onCommit: {},
            onCancel: {}
        )
        .padding(.vertical)
    }
    .padding()
}
