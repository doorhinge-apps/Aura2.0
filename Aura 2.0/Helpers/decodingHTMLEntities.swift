//
// Aura 2.0
// decodingHTMLEntities.swift
//
// Created on 8/6/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

//extension String {
//    func decodingHTMLEntities() -> String {
//        guard let data = self.data(using: .utf8) else { return self }
//
//        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
//            .documentType: NSAttributedString.DocumentType.html,
//            .characterEncoding: String.Encoding.utf8.rawValue
//        ]
//
//        guard let attributedString = try? NSAttributedString(
//            data: data,
//            options: options,
//            documentAttributes: nil
//        ) else { return self }
//
//        return attributedString.string
//    }
//}

extension String {
    func decodingHTMLEntities() -> String {
        guard !self.isEmpty else { return self }
        
        do {
            guard let data = self.data(using: .utf8) else { return self }
            
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            
            return attributedString.string
            
        } catch {
            print("HTML decoding failed: \(error)")
            return self
        }
    }
    
    func decodingGoogleSearchEntities() -> String {
        return self
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#x2F;", with: "/")
            .replacingOccurrences(of: "&#x3D;", with: "=")
            .replacingOccurrences(of: "&mdash;", with: "—")
            .replacingOccurrences(of: "&ndash;", with: "–")
            .replacingOccurrences(of: "&hellip;", with: "…")
            .replacingOccurrences(of: "&trade;", with: "™")
            .replacingOccurrences(of: "&copy;", with: "©")
            .replacingOccurrences(of: "&reg;", with: "®")
    }
}
