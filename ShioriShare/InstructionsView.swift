import SwiftUI

struct InstructionsView: View {
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    Divider()
                    howToUseSection
                    Divider()
                    tipSection
                    Divider()
                    aboutSection
                }
                .padding()
            }
            .navigationTitle("Shiori Share")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Shiori Share", systemImage: "books.vertical")
                .font(.title2.weight(.semibold))
            
            Text("Save bookmarks from Safari to your Shiori server")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("How to Use", systemImage: "iphone")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                instructionStep(number: 1, text: "Tap the ⚙️ button above to configure your server")
                instructionStep(number: 2, text: "In Safari, tap the share button on any page")
                instructionStep(number: 3, text: "Select \"Shiori Share\" from the share sheet")
                instructionStep(number: 4, text: "Add tags and details, then tap Save")
            }
        }
    }
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
        }
    }
    
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tip", systemImage: "lightbulb")
                .font(.headline)
            
            Text("To move Shiori Share higher in the share sheet, scroll right and tap \"More\", then tap \"Edit\" to reorder.")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About Shiori", systemImage: "info.circle")
                .font(.headline)
            
            Text("Shiori is a simple, self-hosted, bookmark manager built with Go.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Link(destination: URL(string: "https://github.com/go-shiori/shiori")!) {
                Label("github.com/go-shiori/shiori", systemImage: "link")
                    .font(.body)
            }
        }
    }
}

#Preview {
    InstructionsView()
}
