//
// Aura 2.0
// SearchSuggestionsModel.swift
//
// Created on 7/21/25
//
// Copyright ©2025 DoorHinge Apps.
//


import Foundation
import Combine
import Playgrounds

struct SearchSuggestion {
    let id = UUID()
    let url: String
    var visited: Int = 1
}

class SearchSuggestionsModel: ObservableObject {
    @Published var searchSuggestions: [String] = []
    
    func updateGoogleSearchSuggestions(inputString: String) {
        Task {
            if let xml = await fetchXML(searchRequest: inputString) {
                searchSuggestions = formatXML(from: xml)
            }
        }
    }

    func fetchXML(searchRequest: String) async -> String? {
        guard let url = URL(string: "https://toolbarqueries.google.com/complete/search?q=\(searchRequest.replacingOccurrences(of: " ", with: "+"))&output=toolbar&hl=en") else {
            print("Invalid URL")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Fetch error: \(error.localizedDescription)")
            return nil
        }
    }

    func formatXML(from input: String) -> [String] {
        var results = [String]()
        var currentIndex = input.startIndex

        while let startIndex = input[currentIndex...].range(of: "data=\"")?.upperBound {
            let remainingSubstring = input[startIndex...]

            if let endIndex = remainingSubstring.range(of: "\"")?.lowerBound {
                let attributeValue = input[startIndex..<endIndex]
                results.append(String(attributeValue))
                currentIndex = endIndex
            } else {
                break
            }
        }

        return results
    }
}
