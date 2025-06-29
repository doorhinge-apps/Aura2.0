//
// Aura 2.0
// CommandBar.swift
//
// Created on 6/12/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct CommandBar: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Environment(\.modelContext) private var modelContext
    
    @FocusState private var commandBarFocus: Bool
    
    @State var currentSuggestionIndex = -1
    
    @State var previewSuggestionInCommandBar = ""
    
    @State var geo: GeometryProxy
    
    var body: some View {
        VStack {
            if #available(iOS 26.0, *), settingsManager.liquidGlassCommandBar {
                GlassEffectContainer {
                    content
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 0)
                }
            }
            else {
                content
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                            .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 0)
                    )
            }
        }
        .frame(width: geo.size.width / 2)
        .onAppear() {
            commandBarFocus = true
        }
        .onKeyPress(.upArrow) {
            if uiViewModel.searchSuggestions.count >= 5 {
                if currentSuggestionIndex == -1 {
                    currentSuggestionIndex = 4
                }
                else {
                    currentSuggestionIndex -= 1
                }
                
                if currentSuggestionIndex != -1 {
                    previewSuggestionInCommandBar = uiViewModel.searchSuggestions[currentSuggestionIndex]
                }
            }
            return KeyPress.Result.handled
        }
        .onKeyPress(.downArrow) {
            if uiViewModel.searchSuggestions.count >= 5 {
                if currentSuggestionIndex == 4 {
                    currentSuggestionIndex = -1
                }
                else {
                    currentSuggestionIndex += 1
                }
                
                if currentSuggestionIndex != -1 {
                    previewSuggestionInCommandBar = uiViewModel.searchSuggestions[currentSuggestionIndex]
                }
            }
            return KeyPress.Result.handled
        }
    }
    
    var content: some View {
        VStack {
            HStack(spacing: 20) {
                TextField("Search or enter URL", text: currentSuggestionIndex == -1 ? $uiViewModel.commandBarText: $previewSuggestionInCommandBar)
                    .padding(20)
//                    .glassEffect(isEnabled: settingsManager.liquidGlassCommandBar)
                    .modifier(GlassEffectIfAvailable())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .lineLimit(1)
                    .zIndex(2)
                    .focused($commandBarFocus)
                    .onSubmit {
                        if (!uiViewModel.commandBarText.isEmpty && currentSuggestionIndex ==  -1) || (!previewSuggestionInCommandBar.isEmpty && currentSuggestionIndex !=  -1) {
                            if let space = storageManager.selectedSpace {
                                storageManager.newTab(
                                    unformattedString: currentSuggestionIndex ==  -1 ? uiViewModel.commandBarText: previewSuggestionInCommandBar,
                                    space: space,
                                    modelContext: modelContext
                                )
                            }
                            uiViewModel.commandBarText = ""
                            previewSuggestionInCommandBar = ""
                            uiViewModel.showCommandBar = false
                        }
                    }
                    .onTapGesture {
                        commandBarFocus = true
                    }
                    .onChange(of: uiViewModel.commandBarText, perform: { value in
                        Task {
                            await uiViewModel.updateSearchSuggestions()
                        }
                    })
                
                Button {
                    if (!uiViewModel.commandBarText.isEmpty && currentSuggestionIndex ==  -1) || (!previewSuggestionInCommandBar.isEmpty && currentSuggestionIndex !=  -1) {
                        if let space = storageManager.selectedSpace {
                            storageManager.newTab(
                                unformattedString: currentSuggestionIndex ==  -1 ? uiViewModel.commandBarText: previewSuggestionInCommandBar,
                                space: space,
                                modelContext: modelContext
                            )
                        }
                        uiViewModel.commandBarText = ""
                        previewSuggestionInCommandBar = ""
                        uiViewModel.showCommandBar = false
                    }
                } label: {
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(20)
                }
                .zIndex(1)
                .frame(width: 80)
//                .glassEffect(.regular.tint(
//                    Color(hex: storageManager.selectedSpace?.spaceBackgroundColors.first ?? "8041E6")
//                        .opacity(uiViewModel.commandBarText.isEmpty ? 0.0 : 0.5)
//                ).interactive(), isEnabled: settingsManager.liquidGlassCommandBar)
                .modifier(TintedGlassEffect1IfAvailable())
                
            }
            
            ForEach(uiViewModel.searchSuggestions.prefix(5), id:\.self) { suggestion in
                Button {
                    if let space = storageManager.selectedSpace {
                        storageManager.newTab(
                            unformattedString: suggestion,
                            space: space,
                            modelContext: modelContext
                        )
                    }
                    uiViewModel.commandBarText = ""
                    uiViewModel.showCommandBar = false
                } label: {
                    HStack {
                        Text(suggestion)
                        
                        Spacer()
                    }.foregroundStyle(Color(.label))
                }
                .padding(20)
                .frame(width: geo.size.width/2)
//                .glassEffect(
//                    .regular.tint(
//                        Color(hex: storageManager.selectedSpace?.spaceBackgroundColors.first ?? "8041E6")
//                            .opacity(currentSuggestionIndex == uiViewModel.searchSuggestions.firstIndex(of: suggestion) ? 0.5: 0.0)
//                    ),
//                    isEnabled: settingsManager.liquidGlassCommandBar
//                )
                .modifier(TintedGlassEffect2IfAvailable(suggestion: suggestion, currentSuggestionIndex: currentSuggestionIndex))
                .background(content: {
                    if !settingsManager.liquidGlassCommandBar {
                        Color(hex: storageManager.selectedSpace?.spaceBackgroundColors.first ?? "8041E6")
                            .opacity(currentSuggestionIndex == uiViewModel.searchSuggestions.firstIndex(of: suggestion) ? 0.5: 0.0)
                            .cornerRadius(15)
                    }
                })
                
            }.onAppear() {
                uiViewModel.searchSuggestions = UserDefaults.standard.stringArray(forKey: "commandBarHistory") ?? ["arc.net", "thebrowser.company", "notion.so", "figma.com", "google.com", "apple.com"]
            }
        }
    }
}
