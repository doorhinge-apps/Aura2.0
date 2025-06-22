//
// Aura 2.0
// TabsManager.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import Combine
import LinkPresentation

class TabsManager: ObservableObject {
    @Published var linksWithTitles: [String: String] = [:]
    
    func fetchTitle(for urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        let metadataProvider = LPMetadataProvider()

        do {
            let title: String? = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
                metadataProvider.startFetchingMetadata(for: url) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: metadata?.title)
                    }
                }
            }
            let hideMagnifier = UserDefaults.standard.bool(forKey: "hideMagnifyingGlassSearch")
            let resolvedTitle = title ?? urlString
            return resolvedTitle.replacingOccurrences(of: hideMagnifier ? "🔎" : "", with: "")
        } catch {
            print("Failed to fetch metadata for url: \(urlString): \(error)")
            return nil
        }
    }
    
    @MainActor
    func fetchTitles(for urls: [String]) async {
        for urlString in urls {
            if let title = await fetchTitle(for: urlString) {
                linksWithTitles[urlString] = title
            }
        }
    }
    
    @MainActor
    func fetchTitlesIfNeeded(for urls: [String]) async {
        for urlString in urls where linksWithTitles[urlString] == nil {
            if let title = await fetchTitle(for: urlString) {
                linksWithTitles[urlString] = title.replacingOccurrences(of: "🔎", with: "")
            }
        }
    }
    
    @MainActor
    func clearCachedTitle(for url: String) {
        linksWithTitles.removeValue(forKey: url)
    }
}

