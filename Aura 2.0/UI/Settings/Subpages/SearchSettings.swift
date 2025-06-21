//
// Aura 2.0
// SearchSettings.swift
//
// Created on 6/21/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct SearchSettings: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State var searchEngineOptions = ["Google", "Bing", "DuckDuckGo", "Yahoo!", "Ecosia", "Perplexity"]
    @State var searchEngineIconColors = ["Google":"FFFFFF", "Bing":"B5E3FF", "DuckDuckGo":"DE5833", "Yahoo!":"8A3CEF", "Ecosia": "9AD39E", "Perplexity": "000000"]
    @State var searchEngines: [String: String] = [
        "Google": "https://www.google.com/search?q=",
        "Bing": "https://www.bing.com/search?q=",
        "DuckDuckGo": "https://duckduckgo.com/?q=",
        "Yahoo!": "https://search.yahoo.com/search?q=",
        "Ecosia": "https://www.ecosia.org/search?q=",
        "Perplexity": "https://www.perplexity.ai/search?q="
    ]
    
#if !os(macOS)
    @StateObject var motionManager = MotionManager()
    #endif
    private let maxDegrees: Double = 30
    private let rotationScale: Double = 0.5
    
    @State var temporarySearchField = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ).ignoresSafeArea()
            
            ScrollView {
                VStack {
                    ZStack {
                        Color(hex: searchEngineIconColors[searchEngines.someKey(forValue: settingsManager.searchEngine).unsafelyUnwrapped] ?? "ffffff")
                        
                        Image("\(searchEngines.someKey(forValue: settingsManager.searchEngine).unsafelyUnwrapped) Icon")
                            .resizable()
                            .scaledToFit()
                        
                    }.frame(width: 200, height: 200)
                    .cornerRadius(CGFloat(settingsManager.faviconShape == "circle" ? 100: settingsManager.faviconShape == "square" ? 0: 20))
                    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 0)
#if !os(visionOS) && !os(macOS)
                    .rotation3DEffect(
                        max(min(Angle.radians(motionManager.magnitude * rotationScale), Angle.degrees(maxDegrees)), Angle.degrees(-maxDegrees)),
                        axis: (x: CGFloat(UIDevice.current.orientation == .portrait ? motionManager.x: -motionManager.y), y: CGFloat(UIDevice.current.orientation == .portrait ? -motionManager.y: -motionManager.x), z: 0.0)
                    )
#elseif !os(macOS)
                    .hoverEffect(.lift)
                #endif
                    
                    Spacer()
                        .frame(height: 30)
                    
                    List {
                        ForEach(searchEngineOptions, id:\.self) { searchEngine in
                            Button {
                                settingsManager.searchEngine = searchEngines[searchEngine] ?? "https://www.google.com/search?q="
                            } label: {
                                HStack {
                                    Image("\(searchEngine) Icon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 30)
                                        .background {
                                            Color(hex: searchEngineIconColors[searchEngine] ?? "ffffff")
                                                .cornerRadius(50)
                                        }
                                    
                                    Text(searchEngine)
                                }
                            }
                        }
                        
                        TextField("Enter a Custom Search Engine", text: $temporarySearchField)
                            .onChange(of: temporarySearchField) { oldValue, newValue in
                                settingsManager.searchEngine = temporarySearchField
                            }
                            .onAppear() {
                                if !searchEngines.values.contains(settingsManager.searchEngine) {
                                    temporarySearchField = settingsManager.searchEngine
                                }
                            }
                    }.frame(height: 500)
                        .scrollDisabled(true)
                        .scrollContentBackground(.hidden)
                }
            }
        }
    }
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}

#Preview {
    SearchSettings()
}
