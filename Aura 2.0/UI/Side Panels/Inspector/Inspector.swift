//
// Aura 2.0
// Inspector.swift
//
// Created on 6/13/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI


struct Inspector: View {
    @EnvironmentObject var uiViewModel: UIViewModel
    
    @Binding var htmlString: String
    @State private var highlightedHTML: AttributedString = ""

    var body: some View {
        VStack {
            HStack {
                Button {
                    uiViewModel.showInspector = false
                } label: {
                    Image(systemName: "xmark")
                }
                Spacer()
            }.padding()
            
            ScrollView {
                Text(highlightedHTML)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .background(Color.white)
        .onChange(of: htmlString) { _ in startHighlighting() }
        .task { startHighlighting() }
    }

    private func startHighlighting() {
        highlightedHTML = AttributedString(htmlString)
        let base = NSMutableAttributedString(string: htmlString)
        let fullRange = NSRange(location: 0, length: base.length)
        let rules: [(pattern: String, color: UIColor)] = [
            ("<!--.*?-->", .systemGray),
            ("</?\\w[\\w\\-]*", .systemBlue),
            ("\\b\\w[\\w\\-]*(?=\\=)", .systemTeal),
            ("\".*?\"", .systemRed)
        ]

        var matches: [(NSRange, UIColor)] = []
        for (pattern, color) in rules {
            if let rx = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
                rx.matches(in: base.string, range: fullRange).forEach {
                    matches.append(($0.range, color))
                }
            }
        }
        matches.sort { $0.0.location < $1.0.location }

        DispatchQueue.global(qos: .userInitiated).async { // highlight in background
            for (range, color) in matches {
                base.addAttribute(.foregroundColor, value: color, range: range)
                let updated = AttributedString(base)
                DispatchQueue.main.async { // update UI
                    highlightedHTML = updated
                }
            }
        }
    }
}



enum HTMLSyntaxHighlighter {
    static func highlightIncrementally(_ html: String) async -> AttributedString {
        let base = NSMutableAttributedString(string: html)
        let full = NSRange(location: 0, length: base.length)
        
        let rules: [(String, UIColor)] = [
            ("<!--.*?-->", .systemGray),
            ("</?\\w[\\w\\-]*", .systemBlue),
            ("\\b\\w[\\w\\-]*(?=\\=)", .systemTeal),
            ("\".*?\"", .systemRed)
        ]
        
        for (pattern, color) in rules {
            // Execute sequentially in the same task to avoid data races
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
                regex.matches(in: base.string, range: full).forEach {
                    base.addAttribute(.foregroundColor, value: color, range: $0.range)
                }
                // Yield between rule applications for responsiveness
                await Task.yield()
            }
        }
        
        return AttributedString(base)
    }
}




func fetchHTML(from urlString: String) async throws -> String {
    guard let url = URL(string: urlString) else { throw URLError(.badURL) }
    let (data, _) = try await URLSession.shared.data(from: url)
    guard var html = String(data: data, encoding: .utf8) else {
        throw NSError(domain: "InvalidEncoding", code: 0)
    }

    // Normalize newlines
    html = html.replacingOccurrences(of: "\r\n", with: "\n")
    
    // Remove all blank lines (lines that are empty or contain only whitespace)
    html = html
        .components(separatedBy: .newlines)
        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        .joined(separator: "\n")

    return html
}

