//
// Aura 2.0
// WebViewFallback.swift
//
// Created on 6/30/25
//
// Copyright ©2025 DoorHinge Apps.
//

import SwiftUI
import WebKit
import Combine


class CustomSafeAreaWebViewContainer: UIView {
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

// MARK: - WebView Fallback
class WebPageFallback: ObservableObject {
    private var webKitWebView: WKWebView?
    
    var containerView: CustomSafeAreaWebViewContainer?
    
    @Published var url: URL?
    @Published var title: String?
    @Published var hasOnlySecureContent: Bool = false
    @Published var isLoading: Bool = false
    @Published var themeColor: Color?
    
    init() {
        setupWKWebView()
    }
    
//    private func setupWKWebView() {
//        let configuration = WKWebViewConfiguration()
//        configuration.allowsInlineMediaPlayback = true
//        configuration.mediaTypesRequiringUserActionForPlayback = []
//        
//        let webView = WKWebView(frame: .zero, configuration: configuration)
//        webView.navigationDelegate = WebViewNavigationDelegate(parent: self)
//        self.webKitWebView = webView
//    }
    private func setupWKWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = WebViewNavigationDelegate(parent: self)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create container view with custom safe area
        let container = CustomSafeAreaWebViewContainer()
        container.backgroundColor = UIColor.clear
        container.addSubview(webView)
        
        // Add constraints to fill the container
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        self.webKitWebView = webView
        self.containerView = container
    }
    
    
    func load(_ request: URLRequest) {
        webKitWebView?.load(request)
        self.url = request.url
    }
    
    func callJavaScript(_ script: String) async throws {
        _ = try await webKitWebView?.evaluateJavaScript(script)
    }
    
    func reload() {
        webKitWebView?.reload()
    }
    
    func goBack() {
        webKitWebView?.goBack()
    }
    
    func goForward() {
        webKitWebView?.goForward()
    }
    
    var canGoBack: Bool {
        return webKitWebView?.canGoBack ?? false
    }
    
    var canGoForward: Bool {
        return webKitWebView?.canGoForward ?? false
    }
    
    // Extract theme color from meta tags
    func extractThemeColor() {
        guard let webView = webKitWebView else { return }
        
        let script = """
        (function() {
            var themeColorMeta = document.querySelector('meta[name="theme-color"]');
            if (themeColorMeta) {
                return themeColorMeta.getAttribute('content');
            }
            
            // Also check for msapplication-TileColor
            var tileMeta = document.querySelector('meta[name="msapplication-TileColor"]');
            if (tileMeta) {
                return tileMeta.getAttribute('content');
            }
            
            return null;
        })();
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            DispatchQueue.main.async {
                if let colorString = result as? String {
                    self?.themeColor = self?.parseColorString(colorString)
                }
            }
        }
    }
    
    // Parse color string (hex, rgb, rgba, named colors)
    private func parseColorString(_ colorString: String) -> Color? {
        let trimmed = colorString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Handle hex colors
        if trimmed.hasPrefix("#") {
            return parseHexColor(trimmed)
        }
        
        // Handle rgb/rgba colors
        if trimmed.hasPrefix("rgb") {
            return parseRGBColor(trimmed)
        }
        
        // Handle named colors
        return parseNamedColor(trimmed)
    }
    
    private func parseHexColor(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        if length == 6 {
            let red = Double((rgb & 0xFF0000) >> 16) / 255.0
            let green = Double((rgb & 0x00FF00) >> 8) / 255.0
            let blue = Double(rgb & 0x0000FF) / 255.0
            return Color(red: red, green: green, blue: blue)
        } else if length == 3 {
            let red = Double((rgb & 0xF00) >> 8) / 15.0
            let green = Double((rgb & 0x0F0) >> 4) / 15.0
            let blue = Double(rgb & 0x00F) / 15.0
            return Color(red: red, green: green, blue: blue)
        }
        
        return nil
    }
    
    private func parseRGBColor(_ rgb: String) -> Color? {
        let pattern = #"rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: rgb, options: [], range: NSRange(location: 0, length: rgb.count)) else {
            return nil
        }
        
        guard let redRange = Range(match.range(at: 1), in: rgb),
              let greenRange = Range(match.range(at: 2), in: rgb),
              let blueRange = Range(match.range(at: 3), in: rgb),
              let red = Int(rgb[redRange]),
              let green = Int(rgb[greenRange]),
              let blue = Int(rgb[blueRange]) else {
            return nil
        }
        
        return Color(red: Double(red) / 255.0, green: Double(green) / 255.0, blue: Double(blue) / 255.0)
    }
    
    private func parseNamedColor(_ name: String) -> Color? {
        switch name {
        case "black": return .black
        case "white": return .white
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        default: return nil
        }
    }
    
    // Internal access to WKWebView for the SwiftUI wrapper
    internal var wkWebView: WKWebView? {
        return webKitWebView
    }
}

// MARK: - WKWebView Navigation Delegate
class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var parent: WebPageFallback?
    
    init(parent: WebPageFallback) {
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        parent?.isLoading = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent?.isLoading = false
        parent?.url = webView.url
        parent?.title = webView.title
        parent?.hasOnlySecureContent = webView.hasOnlySecureContent
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        parent?.isLoading = false
    }
}

// MARK: - SwiftUI WebView Wrapper
struct WebViewFallback: UIViewRepresentable {
    @ObservedObject var webPage: WebPageFallback
    
    init(_ webPage: WebPageFallback) {
        self.webPage = webPage
    }
    
//    func makeUIView(context: Context) -> UIView {
//        if let wkWebView = webPage.wkWebView {
//            wkWebView.backgroundColor = UIColor.clear
//            wkWebView.scrollView.backgroundColor = UIColor.clear
//            return wkWebView
//        }
//        return UIView()
//    }
    func makeUIView(context: Context) -> UIView {
        if let containerView = webPage.containerView {
            return containerView
        }
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Updates are handled through the WebPageFallback class
    }
}

// MARK: - Compatibility Extensions

extension WebViewFallback {
    func scrollEdgeEffectDisabled(_ disabled: Bool) -> some View {
        if #available(iOS 18.0, *) {
            return self.modifier(ScrollEdgeDisabledIfAvailable())
        } else {
            return self
        }
    }
    
    func scrollBounceBehavior(_ behavior: Any, axes: Axis.Set) -> some View {
        return self
    }
    
//    func webViewScrollPosition(_ position: Binding<ScrollPosition>) -> some View {
//        return self
//    }
    
    func findNavigator(isPresented: Binding<Bool>) -> some View {
        return self
    }
}
