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
        
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: backgroundGradientColors, startPoint: .top, endPoint: .bottom)
                
                VStack {
                    ScrollView {
                        Spacer()
                            .frame(height: 75)
                        
                        LazyVGrid(columns: [GridItem(), GridItem()]) {
                            ForEach(selectedSpace.primaryTabs, id:\.id) { tab in
                                Button {
                                    Task {
                                        await storageManager.selectOrLoadTab(tabObject: tab)
                                    }
                                } label: {
                                    UrlSnapshotView(urlString: tab.url)
                                        .scaledToFill()
                                        .frame(width: geo.size.width/2 - 50, height: (geo.size.width/2 - 50)*(4/3), alignment: .top)
                                        .clipped()
                                        .matchedGeometryEffect(id: tab.id.description, in: namespace)
                                }
                                
                            }
                        }
                    }
                }
                
                if storageManager.currentTabs.first?.first != nil || uiViewModel.showStartpage {
                    VStack {
                        if uiViewModel.showStartpage {
                            Startpage(selectedSpace: selectedSpace)
                        }
                        else {
                            WebsitePanel()
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    
                    ZStack {
                        VStack {
                            HStack {
                                Button {
                                    withAnimation(.easeInOut) {
                                        uiViewModel.showStartpage = true
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                }
                                
                                Button {
                                    withAnimation(.easeInOut) {
                                        uiViewModel.showStartpage = true
                                    }
                                } label: {
                                    Image(systemName: "chevron.right")
                                }
                                
                                Spacer()
                                
                                Button {
                                    withAnimation(.easeInOut) {
                                        uiViewModel.showStartpage = true
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                }.matchedGeometryEffect(id: "newTab", in: namespace)
                            }
                        }
                    }
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                    .frame(width: geo.size.width-30, height: 100)
                    .padding(15)
                }
            }
        }
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
