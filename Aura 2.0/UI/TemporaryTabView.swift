import SwiftUI

struct TemporaryTabView: View {
    @State private var urlInput: String = ""
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var storageManager: StorageManager
    
    let onURLSubmit: (String) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Enter a URL")
                    .font(.title2)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Search or enter URL", text: $urlInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            submitURL()
                        }
                    
                    Button(action: submitURL) {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .frame(maxWidth: 400)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                    .shadow(radius: 10)
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.gray.opacity(0.1))
        .onAppear {
            // Focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This will be handled by the system automatically
            }
        }
    }
    
    private func submitURL() {
        let trimmedInput = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        let formattedURL = formatURL(from: trimmedInput)
        onURLSubmit(formattedURL)
    }
}