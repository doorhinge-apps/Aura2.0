//
// Aura 2.0
// WebsitePanel.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit
import SwiftData

struct WebsitePanel: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Environment(\.modelContext) private var modelContext
    
    @State var scrollPosition = ScrollPosition()
    
    @State var findNavigatorIsPresent: Bool = false
    
    @State var websiteFocus: [Int] = []
    
    @State var presentWebsiteNavigatorIn: [Int] = []
    
    @State var temporaryEditText = ""
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Button {
                    presentWebsiteNavigatorIn = websiteFocus
                } label: {
                    Color.white.opacity(0.001)
                }.keyboardShortcut("t", modifiers: [.command, .option])
                
                Button {
                    findNavigatorIsPresent.toggle()
                } label: {
                    Color.white.opacity(0.001)
                }.keyboardShortcut("f", modifiers: .command)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.25))
                
                VStack {
//                    Spacer()
//                        .frame(height: 50)
                    ForEach(Array(storageManager.currentTabs.enumerated()), id:\.offset) { rowIdx, tabRow in
                        ZStack {
                            HStack {
                                ForEach(Array(tabRow.enumerated()), id:\.element.id) { colIdx, website in
                                    GeometryReader { geo in
                                        ZStack {
                                            WebView(website.page)
                                                .scrollEdgeEffectDisabled(true)
                                                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                                                .webViewScrollPosition($scrollPosition)
                                                .findNavigator(isPresented: $findNavigatorIsPresent)
                                                .padding(.vertical, 10)
                                                .frame(height: geo.size.height + 20)
                                                .shadow(color: Color(.systemBlue).opacity(websiteFocus == [rowIdx, colIdx] ? 0.5: 0.0), radius: 5, x: 0, y: 0)
                                                .onTapGesture {
                                                    if websiteFocus != [rowIdx, colIdx] {
                                                        websiteFocus = [rowIdx, colIdx]
                                                    }
                                                }
                                            
                                            if presentWebsiteNavigatorIn == [rowIdx, colIdx] {
                                                let tab = storageManager.currentTabs[rowIdx][colIdx]
                                                
                                                VStack {
                                                    TextField("Search or Enter URL", text: $temporaryEditText)
                                                        .onSubmit {
                                                            handleURLSubmission(rowIdx: rowIdx, colIdx: colIdx)
                                                        }
                                                }
                                            }
                                        }
                                        .frame(height: geo.size.height)
                                        .cornerRadius(10)
                                        .clipped()
                                        .onChange(of: website.page.url) { _, newVal in
                                            if let url = newVal {
                                                storageManager.updateURL(for: website.id, newURL: url.absoluteString, modelContext: modelContext)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Button {
                                    
                                } label: {
                                    ZStack {
                                        Color.white.opacity(1)
                                        
                                        Image(systemName: "plus")
                                            .resizable()
                                            .scaledToFit()
                                            .padding(2)
                                    }.frame(width: 30)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 0)
                                }

                            }
                        }
                    }
                }
            }
        }.scrollEdgeEffectDisabled(true)
    }
    
    private func handleURLSubmission(rowIdx: Int, colIdx: Int) {
            let text = temporaryEditText
            let url = formatURL(from: text)
            let request = URLRequest(url: URL(string: url)!)
            
            // Ensure the indices are still valid before accessing
            guard rowIdx < storageManager.currentTabs.count,
                  colIdx < storageManager.currentTabs[rowIdx].count else {
                return
            }
            
            storageManager.currentTabs[rowIdx][colIdx].page.load(request)
            temporaryEditText = ""
            presentWebsiteNavigatorIn = [] // Hide the navigator after submission
        }
}

#Preview {
    WebsitePanel()
}
