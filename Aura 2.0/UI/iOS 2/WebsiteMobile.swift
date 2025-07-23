//
// Aura 2.0
// WebsiteMobile.swift
//
// Created on 7/22/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit
import SwiftData

struct WebsiteMobile: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Environment(\.modelContext) private var modelContext
    
    @State var findNavigatorIsPresent: Bool = false
    
    @State var presentWebsiteNavigatorIn: [Int] = []
    
    @State var temporaryEditText = ""
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.25))
                
                VStack {
                    ZStack {
                        ForEach(Array(storageManager.currentTabs.enumerated()), id:\.offset) { rowIdx, tabRow in
                            ZStack {
                                HStack {
                                    ForEach(Array(tabRow.enumerated()), id:\.element.id) { colIdx, website in
                                        GeometryReader { geo in
                                            ZStack {
                                                if website.storedTab.isTemporary {
                                                    // Show temporary tab view
                                                    TemporaryTabView(
                                                        onURLSubmit: { url in
                                                            storageManager.convertTemporaryTabToPermanent(
                                                                browserTab: website,
                                                                newURL: url,
                                                                modelContext: modelContext
                                                            )
                                                        },
                                                        onClose: {
                                                            // Handle close for temporary tab
                                                            storageManager.cleanupTemporaryTabs()
                                                        }
                                                    )
                                                    .shadow(color: Color(.systemBlue).opacity(storageManager.focusedWebsite == [rowIdx, colIdx] ? 0.5: 0.0), radius: 5, x: 0, y: 0)
                                                    .onTapGesture {
                                                        if storageManager.focusedWebsite != [rowIdx, colIdx] {
                                                            storageManager.updateFocusedWebsite([rowIdx, colIdx])
                                                            storageManager.cleanupTemporaryTabs()
                                                        }
                                                    }
                                                } else {
                                                    // Show regular web view
                                                    WebViewFallback(website.page)
//                                                        .scrollEdgeEffectDisabled(true)
                                                        .modifier(ScrollEdgeDisabledIfAvailable())
//                                                        .modifier(WebViewModifiersIfAvailable(scrollPosition: $scrollPosition))
                                                        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                                                        .findNavigator(isPresented: $findNavigatorIsPresent)
                                                        .padding(.vertical, 10)
                                                        .frame(height: geo.size.height + 20)
                                                        .shadow(color: Color(.systemBlue).opacity(storageManager.focusedWebsite == [rowIdx, colIdx] ? 0.5: 0.0), radius: 5, x: 0, y: 0)
                                                        .onTapGesture {
                                                            if storageManager.focusedWebsite != [rowIdx, colIdx] {
                                                                storageManager.updateFocusedWebsite([rowIdx, colIdx])
                                                                storageManager.cleanupTemporaryTabs()
                                                            }
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
                                                if let url = newVal, !website.storedTab.isTemporary {
                                                    storageManager.updateURL(for: website.id, newURL: url.absoluteString, modelContext: modelContext)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                HStack {
                                    Spacer()
                                    Button {
                                        // Horizontal split - add new tab to current row
                                        storageManager.addTabToCurrentRow(rowIndex: rowIdx, modelContext: modelContext)
                                    } label: {
                                        ZStack {
                                            Color.blue.opacity(0.001)
                                                .frame(width: 30)
                                            
                                            ZStack {
                                                Color.white.opacity(1)
                                                
                                                Image(systemName: "plus")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .padding(2)
                                            }.frame(width: 30)
                                                .cornerRadius(10)
                                                .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 0)
                                                .offset(x: uiViewModel.hoveringID == "horizontalSplit" ? 0: 50)
                                        }.onHover { hover in
                                            withAnimation {
                                                if uiViewModel.hoveringID == "horizontalSplit" {
                                                    uiViewModel.hoveringID = ""
                                                }
                                                else {
                                                    uiViewModel.hoveringID = "horizontalSplit"
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                            }
                        }
                        
                        /*VStack {
                            Spacer()
                            
                            // Vertical split button - add new row
                            HStack {
                                Button {
                                    // Vertical split - add new row to current tabs
                                    storageManager.addNewRowToCurrentTabs(modelContext: modelContext)
                                } label: {
                                    ZStack {
                                        Color.blue.opacity(0.001)
                                            .frame(height: 30)
                                        
                                        ZStack {
                                            Color.white.opacity(1)
                                            
                                            Image(systemName: "plus")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(2)
                                        }
                                        .frame(height: 30)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 0)
                                        .offset(y: uiViewModel.hoveringID == "verticalSplit" ? 0: 50)
                                    }
                                }.onHover { hover in
                                    withAnimation {
                                        if uiViewModel.hoveringID == "verticalSplit" {
                                            uiViewModel.hoveringID = ""
                                        }
                                        else {
                                            uiViewModel.hoveringID = "verticalSplit"
                                        }
                                    }
                                }
                            }
//                            .padding(.horizontal, 10)
//                            .padding(.bottom, 10)
                        }*/
                    }
                }
            }
        }//.scrollEdgeEffectDisabled(true)
        .modifier(ScrollEdgeDisabledIfAvailable())
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
