//
// Aura 2.0
// HomePage.swift
//
// Created on 7/15/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

struct MobileContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @State var selectedSpace: SpaceData
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Namespace var namespace
    
    @State var currentTab: BrowserTab?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    LinearGradient(colors: backgroundGradientColors, startPoint: .top, endPoint: .bottom)
                    
                    VStack {
                        ScrollView {
                            Spacer()
                                .frame(height: 75)
                            
                            LazyVGrid(columns: [GridItem(), GridItem()]) {
                                ForEach(selectedSpace.primaryTabs, id:\.id) { tab in
                                    NavigationLink {
                                        MobileWebView()
                                            .transition(.opacity)
                                            .animation(.easeInOut(duration: 0.3), value: storageManager.currentTabs.isEmpty)
                                            .onAppear {
                                                print("DEBUG: MobileWebView condition met and appeared")
                                            }
                                            
                                    } label: {
                                        UrlSnapshotView(urlString: tab.url)
                                            .scaledToFill()
                                            .frame(width: geo.size.width/2 - 50, height: (geo.size.width/2 - 50)*(4/3), alignment: .top)
                                            .clipped()
                                            .matchedGeometryEffect(id: tab.id.description, in: namespace)
                                            .matchedTransitionSource(id: tab.id.description, in: namespace)
                                    }
                                }
                            }
                        }
                        .allowsHitTesting(storageManager.currentTabs.isEmpty || storageManager.currentTabs[0].isEmpty)
                    }
                    
                    if uiViewModel.showStartpage {
                        VStack {
                            Startpage(selectedSpace: selectedSpace)
                        }
                    }
                    
                    
                    if !storageManager.currentTabs.isEmpty && !storageManager.currentTabs[0].isEmpty {
                        MobileWebView()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: storageManager.currentTabs.isEmpty)
                            .onAppear {
                                print("DEBUG: MobileWebView condition met and appeared")
                            }
                    } else {
                        Color.clear
                            .onAppear {
                                print("DEBUG: MobileWebView condition NOT met")
                                print("DEBUG: currentTabs.isEmpty: \(storageManager.currentTabs.isEmpty)")
                                if !storageManager.currentTabs.isEmpty {
                                    print("DEBUG: currentTabs[0].isEmpty: \(storageManager.currentTabs[0].isEmpty)")
                                }
                            }
                    }
                    
                    VStack {
                        Spacer()
                        
                        ZStack {
                            VStack {
                                VStack(spacing: 10) {
                                    HStack {
                                        Button {
                                            // Navigate back functionality
                                            if let focusedTab = storageManager.getFocusedTab() {
                                                focusedTab.page.goBack()
                                            }
                                        } label: {
                                            Image(systemName: "chevron.left")
                                        }
                                        
                                        Button {
                                            // Navigate forward functionality
                                            if let focusedTab = storageManager.getFocusedTab() {
                                                focusedTab.page.goForward()
                                            }
                                        } label: {
                                            Image(systemName: "chevron.right")
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            storageManager.currentTabs = [[]]
                                            storageManager.focusedWebsite = []
                                        } label: {
                                            Image(systemName: "plus")
                                        }.matchedGeometryEffect(id: "newTab", in: namespace)
                                    }
                                    
                                    // Command bar TextField
                                    TextField("Search or enter URL", text: $uiViewModel.commandBarText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .onSubmit {
                                            if !uiViewModel.commandBarText.isEmpty {
                                                if let space = storageManager.selectedSpace {
                                                    storageManager.newTab(
                                                        unformattedString: uiViewModel.commandBarText,
                                                        space: space,
                                                        modelContext: modelContext
                                                    )
                                                }
                                                uiViewModel.commandBarText = ""
                                            }
                                        }
                                }
                            }
                        }
                        .glassEffect(.clear, in: .rect(cornerRadius: 20))
                        .frame(width: geo.size.width-30, height: 200)
                        .padding(15)
                    }
                }
            }.rotationEffect(Angle(degrees: 180))
        }
        .rotationEffect(Angle(degrees: 180))
        .onAppear {
            print("DEBUG: MobileContent appeared, setting selectedSpace")
            storageManager.selectedSpace = selectedSpace
        }
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
