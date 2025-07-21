//
//  WebsiteView.swift
//  Aura
//
//  Created by Reyna Myers on 26/6/24.
//

import SwiftUI

struct WebsiteView: View {
    let namespace: Namespace.ID
//    @Binding var url: String
    @State private var offset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
//    @EnvironmentObject var webViewManager: WebViewManager
    @EnvironmentObject var mobileTabs: MobileTabsModel
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var parentGeo: GeometryProxy
    
    @State var gestureStarted = false
    @State var exponentialThing = 1.0
    
    @State private var webTitle: String = ""
    #if !os(macOS)
    @State var webViewBackgroundColor: UIColor? = UIColor.white
    #else
    @State var webViewBackgroundColor: NSColor? = NSColor.white
    #endif
    @Binding var fullScreenWebView: Bool
    
    @State var tab: BrowserTab
    
    @Binding var browseForMeTabs: [String]
    
    @State var searchText = ""
    @State var searchResponse = ""
    
    var body: some View {
        GeometryReader { geo in
            WebViewMobile(
                urlString: tab.storedTab.url,
                title: $webTitle,
                webViewBackgroundColor: $webViewBackgroundColor,
                currentURLString: Binding(get: {
                    tab.storedTab.url
                }, set: { value in
                    tab.storedTab.url = value
                })
            )
            .navigationBarBackButtonHidden(true)
            .matchedGeometryEffect(id: tab.id, in: namespace)
            .ignoresSafeArea()
        }.ignoresSafeArea(.container, edges: [.leading, .trailing, .bottom])
    }
    
    private func getCurrentTabs() -> [(id: UUID, url: String)] {
        switch mobileTabs.selectedTabsSection {
        case .tabs:
            return mobileTabs.tabs
        case .pinned:
            return mobileTabs.pinnedTabs
        case .favorites:
            return mobileTabs.favoriteTabs
        }
    }
}

