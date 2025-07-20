//
//  TabOverview.swift
//  Aura
//
//  Created by Reyna Myers on 25/6/24.
//

import SwiftUI
import WebKit
import SDWebImage
import SDWebImageSwiftUI
import SwiftData

struct TabOverview: View {
    @Namespace var namespace
    @Query(sort: \SpaceData.spaceOrder) var spaces: [SpaceData]
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedSpaceIndex: Int
    
    @EnvironmentObject var mobileTabs: MobileTabsModel
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    
    @FocusState var newTabFocus: Bool
    @FocusState var inTabFocus: Bool
    
    @State private var inTabSearchText: String = ""
    
    // Single web page for fullscreen viewing
    @State private var fullscreenWebPage = WebPageFallback()
    
    // MARK: - Computed Properties
    
    private var currentTabURL: String {
        guard let selectedTabId = uiViewModel.currentSelectedTab,
              let currentSpace = storageManager.selectedSpace,
              let selectedStoredTab = findTabById(selectedTabId, in: currentSpace) else {
            return ""
        }
        return selectedStoredTab.url
    }
    
    init(selectedSpaceIndex: Binding<Int>) {
        self._selectedSpaceIndex = selectedSpaceIndex
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if selectedSpaceIndex < spaces.count && !spaces[selectedSpaceIndex].spaceBackgroundColors.isEmpty {
                    LinearGradient(colors: spaces[selectedSpaceIndex].spaceBackgroundColors.map { Color(hex: $0) }, startPoint: .bottomLeading, endPoint: .topTrailing).ignoresSafeArea()
                        .animation(.linear)
                }
                else {
                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .bottomLeading, endPoint: .topTrailing).ignoresSafeArea()
                        .animation(.linear)
                }
                
                ScrollView {
                    TabList(selectedSpaceIndex: $selectedSpaceIndex, newTabFocus: $newTabFocus, geo: geo)
                        .namespace(namespace)
                }
                .defaultScrollAnchor(UnitPoint.bottom)
                .onTapGesture(perform: {
                    mobileTabs.newTabFromTab = false
                    
                    if newTabFocus {
                        newTabFocus = false
                    }
                })
                .onOpenURL { url in
                    if url.absoluteString.starts(with: "aura://") {
                        // Handle aura:// scheme URLs
                        let httpsURL = "https\(url.absoluteString.dropFirst(4))"
                        createTab(url: httpsURL, isBrowseForMeTab: false)
                    }
                    else {
                        createTab(url: url.absoluteString, isBrowseForMeTab: false)
                    }
                    print("Url:")
                    print(url)
                }
                .scrollDisabled(mobileTabs.closeTabScrollDisabledCounter > 50)
                
                
                TabTypeSwitcherOld()
                
                
                if mobileTabs.fullScreenWebView {
                    if let selectedTabId = uiViewModel.currentSelectedTab,
                       let currentSpace = storageManager.selectedSpace,
                       let selectedStoredTab = findTabById(selectedTabId, in: currentSpace) {
                        let browserTab = BrowserTab(
                            lastActiveTime: selectedStoredTab.timestamp,
                            tabType: selectedStoredTab.tabType,
                            page: fullscreenWebPage,
                            storedTab: selectedStoredTab
                        )
                        WebsiteView(namespace: namespace, url: Binding(
                            get: { selectedStoredTab.url },
                            set: { _ in }
                        ), webViewManager: nil, parentGeo: geo, webURL: Binding(
                            get: { selectedStoredTab.url },
                            set: { _ in }
                        ), fullScreenWebView: $mobileTabs.fullScreenWebView, tab: browserTab, browseForMeTabs: $mobileTabs.browseForMeTabs)
                        .offset(x: mobileTabs.tabOffset.width, y: mobileTabs.tabOffset.height)
                        .scaleEffect(mobileTabs.tabScale)
                        .onAppear {
                            // Load the URL when fullscreen appears
                            if let url = URL(string: selectedStoredTab.url) {
                                fullscreenWebPage.load(URLRequest(url: url))
                            }
                        }
                    }
                }
                
                VStack {
                    if !mobileTabs.fullScreenWebView {
                        HStack {
                            Button(action: {
                                uiViewModel.showSettings = true
                            }, label: {
                                Image(systemName: "gearshape")
                                
                            }).buttonStyle(ToolbarButtonStyle())
                                .sheet(isPresented: $uiViewModel.showSettings, content: {
                                    if selectedSpaceIndex < spaces.count && !spaces[selectedSpaceIndex].spaceBackgroundColors.isEmpty {
                                        Settings()
                                    }
                                    else {
                                        Settings()
                                    }
                                })
                            
                            Spacer()
                        }.padding(.top, 50)
                            .padding(.leading, 20)
                    }
                    
                    Spacer()
                    
                    ScrollView(showsIndicators: false) {
                        VStack {
                            if newTabFocus {
                                ForEach(Array(uiViewModel.searchSuggestions.prefix(5)), id:\.self) { suggestion in
                                    HStack {
                                        Button(action: {
                                            withAnimation {
                                                newTabFocus = false
                                                createTab(url: formatURL(from: suggestion), isBrowseForMeTab: false)
                                                uiViewModel.commandBarText = ""
                                            }
                                        }, label: {
                                            ZStack {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .fill(
                                                            .white.gradient.shadow(.inner(color: .black.opacity(0.2), radius: 10, x: 0, y: -3))
                                                        )
                                                        .animation(.default, value: newTabFocus)
                                                }
                                                
                                                HStack {
                                                    Text(.init(suggestion))
                                                        .animation(.default)
                                                        .foregroundColor(Color(hex: "4D4D4D"))
                                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                                        .padding(.horizontal, 10)
                                                    
                                                    Spacer()
                                                    
                                                    Button(action: {
                                                        withAnimation {
                                                            newTabFocus = false
                                                            createTab(url: formatURL(from: suggestion), isBrowseForMeTab: true)
                                                            uiViewModel.commandBarText = ""
                                                        }
                                                    }, label: {
                                                        
                                                    }).buttonStyle(BrowseForMeButtonStyle())
                                                }
                                                
                                            }.frame(minHeight: 50)
                                                .padding(.horizontal, 10)
                                        })
                                    }
                                }.animation(.easeInOut)
                            }
                        }.rotationEffect(Angle(degrees: 180))
                            .onChange(of: uiViewModel.commandBarText, perform: { value in
                                uiViewModel.updateSearchSuggestions()
                            })
                            .onChange(of: newTabFocus, perform: { newValue in
                                if mobileTabs.newTabFromTab && !newTabFocus {
                                    mobileTabs.newTabFromTab = false
                                }
                                if !newTabFocus {
                                    uiViewModel.searchSuggestions.removeAll()
                                }
                            })
                    }.rotationEffect(Angle(degrees: 180))
                        .onTapGesture(perform: {
                            mobileTabs.newTabFromTab = false
                            
                            if newTabFocus {
                                newTabFocus = false
                                uiViewModel.commandBarText = ""
                            }
                        })
                    
                    ZStack {
                        Rectangle()
                            .fill(.thinMaterial)
                            .frame(height: newTabFocus || inTabFocus ? 75: 150)
                            // Tab URL updates are handled automatically by StorageManager
                        
                        VStack {
                            if !mobileTabs.fullScreenWebView || mobileTabs.newTabFromTab {
                                HStack(spacing: 0) {
                                    ZStack {
                                        ZStack {
                                            //Capsule()
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(.white)
                                            
                                            if uiViewModel.commandBarText.isEmpty {
                                                Label("Search or enter url", systemImage: "magnifyingglass")
                                                    .foregroundColor(Color(hex: "4D4D4D"))
                                                    .font(.system(.headline, design: .default, weight: .bold))
                                                    .padding(.horizontal, newTabFocus ? 10: 0)
                                                    //.animation(.default, value: newTabFocus)
                                                
                                                if newTabFocus {
                                                    Spacer()
                                                }
                                            }
                                            
                                        }.onTapGesture {
                                            newTabFocus = true
                                        }
                                        
                                        TextField("", text: $uiViewModel.commandBarText)
                                            .focused($newTabFocus)
                                            .padding(.horizontal, 10)
                                            .textFieldStyle(.plain)
#if !os(macOS)
                                            .keyboardType(.webSearch)
                                            .textInputAutocapitalization(.never)
#endif
                                            .autocorrectionDisabled(true)
                                            .submitLabel(.search)
#if !os(visionOS) && !os(macOS)
                                            .scrollDismissesKeyboard(.immediately)
#endif
                                            .tint(Color(.systemBlue))
                                            .foregroundColor(Color(hex: "4D4D4D"))
                                            .font(.system(.headline, design: .rounded, weight: .bold))
                                            .padding(.horizontal, newTabFocus ? 10: 0)
                                            .onSubmit({
                                                withAnimation {
                                                    mobileTabs.newTabFromTab = false
                                                    newTabFocus = false
                                                    createTab(url: formatURL(from: uiViewModel.commandBarText), isBrowseForMeTab: false)
                                                    uiViewModel.commandBarText = ""
                                                }
                                            })
                                        
                                    }.frame(height: 50)
                                    
                                    Spacer()
                                        .frame(width: 10)
                                    
                                    Button(action: {
                                        if uiViewModel.commandBarText == "" && newTabFocus {
                                            newTabFocus = false
                                            mobileTabs.newTabFromTab = false
                                        }
                                        else if !newTabFocus {
                                            withAnimation {
                                                newTabFocus = true
                                            }
                                        } else {
                                            withAnimation {
                                                mobileTabs.newTabFromTab = false
                                                newTabFocus = false
                                                createTab(url: formatURL(from: uiViewModel.commandBarText), isBrowseForMeTab: false)
                                                uiViewModel.commandBarText = ""
                                            }
                                        }
                                    }, label: {
                                        if uiViewModel.commandBarText == "" && newTabFocus {
                                            Image(systemName: "xmark")
                                        }
                                        else {
                                            Image(systemName: newTabFocus ? "magnifyingglass": "plus")
                                        }
                                    }).buttonStyle(PlusButtonStyle())
                                        .onAppear() {
                                            // TODO: Add commandBarOnLaunch setting to SettingsManager
                                            // if settingsManager.commandBarOnLaunch {
                                            //     withAnimation {
                                            //         newTabFocus = true
                                            //     }
                                            // }
                                        }
                                        .scaleEffect(!newTabFocus ? 0: 1)
                                        .frame(width: !newTabFocus ? 0: .infinity)
                                    
                                }//.padding(.leading, newTabFocus ? 10: 0)
                                .padding(.horizontal, 15)
                                    .onChange(of: uiViewModel.commandBarText, {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                            if uiViewModel.commandBarText == "" {
                                                uiViewModel.searchSuggestions.removeAll()
                                            }
                                        })
                                    })
                                
                                if !newTabFocus && !inTabFocus {
                                    spaceSelector
                                }
                            }
                            else {
                                VStack {
                                    ZStack {
                                        HStack(spacing: 0) {
                                            ZStack {
                                                ZStack {
                                                    Capsule()
                                                        .fill(.white)
                                                    
                                                    if inTabSearchText.isEmpty {
                                                        Label("Search or enter url", systemImage: inTabFocus ? "": "magnifyingglass")
                                                            .foregroundColor(Color(hex: "4D4D4D"))
                                                            .font(.system(.headline, design: .rounded, weight: .bold))
                                                            .padding(.horizontal, inTabFocus ? 10: 0)
                                                            //.animation(.default, value: newTabFocus)
                                                        
                                                        if newTabFocus {
                                                            Spacer()
                                                        }
                                                    }
                                                    
                                                }.onTapGesture {
                                                    inTabFocus = true
                                                }
                                                
                                                TextField("", text: $inTabSearchText)
                                                    .focused($inTabFocus)
                                                    .multilineTextAlignment(inTabFocus ? .leading: .center)
                                                    .padding(.horizontal, 10)
                                                    //.opacity(newTabFocus ? 1.0: 0.0)
                                                    .textFieldStyle(.plain)
        #if !os(macOS)
                                                    .keyboardType(.webSearch)
                                                    .textInputAutocapitalization(.never)
        #endif
                                                    .autocorrectionDisabled(true)
                                                    .submitLabel(.search)
        #if !os(visionOS) && !os(macOS)
                                                    .scrollDismissesKeyboard(.immediately)
        #endif
                                                    .tint(Color(.systemBlue))
                                                    .foregroundColor(Color(hex: "4D4D4D"))
                                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                                    .padding(.horizontal, inTabFocus ? 10: 0)
                                                    .onSubmit({
                                                        withAnimation {
                                                            DispatchQueue.main.async {
                                                                if let selectedTabId = uiViewModel.currentSelectedTab,
                                                                   let currentSpace = storageManager.selectedSpace,
                                                                   let selectedStoredTab = findTabById(selectedTabId, in: currentSpace),
                                                                   let url = URL(string: formatURL(from: inTabSearchText)) {
                                                                    selectedStoredTab.url = formatURL(from: inTabSearchText)
                                                                    try? modelContext.save()
                                                                }
                                                                print("Loading url:")
                                                                print(formatURL(from: inTabSearchText))
                                                                
                                                                mobileTabs.newTabFromTab = false
                                                                inTabFocus = false
                                                            }
                                                        }
                                                    })
                                                    .onAppear() {
                                                        inTabSearchText = unformatURL(url: currentTabURL)
                                                    }
                                                    .onChange(of: currentTabURL) { oldValue, newValue in
                                                        inTabSearchText = unformatURL(url: currentTabURL)
                                                    }
                                                
                                            }.frame(height: 50)
                                            
                                            
                                            Spacer()
                                                .frame(width: 10)
                                            
                                            Button(action: {
                                                if inTabSearchText == "" && inTabFocus {
                                                    inTabFocus = false
                                                    mobileTabs.newTabFromTab = false
                                                }
                                                else if !newTabFocus {
                                                    withAnimation {
                                                        inTabFocus = true
                                                    }
                                                } else {
                                                    withAnimation {
                                                        if let selectedTabId = uiViewModel.currentSelectedTab,
                                                           let currentSpace = storageManager.selectedSpace,
                                                           let selectedStoredTab = findTabById(selectedTabId, in: currentSpace),
                                                           let url = URL(string: formatURL(from: inTabSearchText)) {
                                                            selectedStoredTab.url = formatURL(from: inTabSearchText)
                                                            try? modelContext.save()
                                                        }
                                                        mobileTabs.newTabFromTab = false
                                                        inTabFocus = false
                                                        //mobileTabs.newTabSearch = ""
                                                    }
                                                }
                                            }, label: {
                                                if inTabSearchText == "" && inTabFocus {
                                                    Image(systemName: "xmark")
                                                }
                                                else {
                                                    Image(systemName: inTabFocus ? "magnifyingglass": "plus")
                                                }
                                            }).buttonStyle(PlusButtonStyle())
                                                .scaleEffect(!inTabFocus ? 0: 1)
                                                .frame(width: !inTabFocus ? 0: .infinity)
                                            
                                        }//.padding(.leading, newTabFocus ? 10: 0)
                                        .padding(.horizontal, 15)
                                            .onChange(of: inTabSearchText, {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                                    if inTabSearchText == "" {
                                                        uiViewModel.searchSuggestions.removeAll()
                                                    }
                                                })
                                            })
                                        
//                                        RoundedRectangle(cornerRadius: 10)
//                                            .fill(.white)
//                                            .frame(height: 50)
//                                            .padding(.horizontal, 15)
//                                        
//                                        Text(unformatURL(url: mobileTabs.webURL).prefix(30))
//                                            .lineLimit(1)
                                        
                                    }.offset(x: mobileTabs.tabOffset.width, y: mobileTabs.tabOffset.height * 3)
                                        .scaleEffect(mobileTabs.tabScale)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { gesture in
                                                    withAnimation {
                                                        mobileTabs.gestureStarted = true
                                                    }
                                                    mobileTabs.exponentialThing = mobileTabs.exponentialThing * 0.99
                                                    var dragX = min(max(gesture.translation.width, -50), 50)
                                                    dragX *= mobileTabs.exponentialThing
                                                    
                                                    let dragY = gesture.translation.height
                                                    if dragY < 0 { // Only allow upward movement
                                                        let slowDragY = dragY * 0.3 // Drag up slower
                                                        mobileTabs.tabOffset = CGSize(width: dragX, height: slowDragY)
                                                        mobileTabs.tabScale = 1 - min(-slowDragY / 200, 0.5)
                                                    }
                                                }
                                                .onEnded { gesture in
                                                    mobileTabs.exponentialThing = 1
                                                    withAnimation {
                                                        mobileTabs.gestureStarted = false
                                                    }
                                                    if gesture.translation.height < -100 {
                                                        //self.presentationMode.wrappedValue.dismiss()
                                                        withAnimation {
                                                            mobileTabs.fullScreenWebView = false
                                                        }
                                                    }
                                                    withAnimation(.spring()) {
                                                        mobileTabs.tabOffset = .zero
                                                        mobileTabs.tabScale = 1.0
                                                    }
                                                    
                                                }
                                        )
                                    
                                    if !newTabFocus && !inTabFocus {
                                        HStack {
                                            Button(action: {
                                                // Navigation handled by web view in fullscreen mode
                                            }, label: {
                                                Image(systemName: "chevron.left")
                                            })
                                            .disabled(true) // TODO: Implement navigation state tracking
                                            .foregroundStyle(Color.gray)
                                            .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                // Navigation handled by web view in fullscreen mode
                                            }, label: {
                                                Image(systemName: "chevron.right")
                                            })
                                            .disabled(true) // TODO: Implement navigation state tracking
                                            .foregroundStyle(Color.gray)
                                            .shadow(color: .white.opacity(0.5), radius: 5, x: 0, y: 0)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                mobileTabs.newTabFromTab = true
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                                    mobileTabs.newTabFromTab = true
                                                    
                                                    if !newTabFocus {
                                                        withAnimation {
                                                            newTabFocus = true
                                                        }
                                                    } else {
                                                        withAnimation {
                                                            newTabFocus = false
                                                            createTab(url: formatURL(from: uiViewModel.commandBarText), isBrowseForMeTab: false)
                                                            uiViewModel.commandBarText = ""
                                                        }
                                                    }
                                                })
                                            }, label: {
                                                Image(systemName: "plus")
                                            })
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                withAnimation {
                                                    mobileTabs.fullScreenWebView = false
                                                }
                                            }, label: {
                                                Image(systemName: "square.on.square")
                                            })
                                        }
                                        .font(.system(.title2, design: .rounded, weight: .regular))
                                        .foregroundStyle(Color(.systemBlue))
                                        .opacity(Double(mobileTabs.tabScale))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                    }
                                }
                            }
                        }
                    }//.offset(y: newTabFocus || inTabFocus ? 50: 0)
                }.ignoresSafeArea(newTabFocus || inTabFocus ? .container: .all, edges: .all)
            }
        }
        .environmentObject(mobileTabs)
        .onAppear {
            updateTabs()
        }
    }
    
    private var spaceSelector: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 10) {
                        ForEach(spaces.indices, id: \.self) { index in
                            Button(action: {
                                withAnimation {
                                    withAnimation {
                                        selectedSpaceIndex = index
                                        updateTabs()
                                        proxy.scrollTo(index, anchor: .center) // Snap to center on tap
                                    }
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.regularMaterial)
                                        .frame(width: geometry.size.width - 50, height: 50)
                                    
                                    HStack {
                                        Image(systemName: spaces[index].spaceIcon)
                                        Text(spaces[index].spaceName)
                                    }
                                    .foregroundStyle(Color(hex: "4D4D4D"))
                                    .font(.system(size: 16, weight: .bold))
                                    .opacity(selectedSpaceIndex == index ? 1.0 : 0.4)
                                    .padding(.horizontal, 15)
                                }
                                .frame(width: geometry.size.width / 2, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(15)
                                .contentShape(Rectangle())
                                .id(index)
                                .onAppear {
                                    if selectedSpaceIndex == index {
                                        proxy.scrollTo(index, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                }
            }
            .padding(.bottom)
        }.frame(height: 75)
    }
    
    
    private func handleDragChange(_ gesture: DragGesture.Value, for id: UUID) {
        mobileTabs.offsets[id] = gesture.translation
        mobileTabs.zIndexes[id] = 100
        var tilt = min(Double(abs(gesture.translation.width)) / 20, 15)
        if gesture.translation.width < 0 {
            tilt *= -1
        }
        mobileTabs.tilts[id] = tilt
        
        mobileTabs.closeTabScrollDisabledCounter = abs(Int(gesture.translation.width))
    }
    
    private func handleDragEnd(_ gesture: DragGesture.Value, for id: UUID) {
        mobileTabs.zIndexes[id] = 1
        if abs(gesture.translation.width) > 100 {
            withAnimation {
                if gesture.translation.width < 0 {
                    mobileTabs.offsets[id] = CGSize(width: -500, height: 0)
                } else {
                    mobileTabs.offsets[id] = CGSize(width: 500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        removeItem(id)
                    }
                }
            }
        } else {
            withAnimation {
                mobileTabs.offsets[id] = .zero
                mobileTabs.tilts[id] = 0.0
            }
        }
        
        mobileTabs.closeTabScrollDisabledCounter = 0
    }
    
    private func updateTabs() {
        if UserDefaults.standard.integer(forKey: "savedSelectedSpaceIndex") > spaces.count - 1 {
            selectedSpaceIndex = 0
        }
        
        Task {
            if spaces.count <= 0 {
                let newSpace = SpaceData()
                newSpace.spaceName = "Untitled"
                newSpace.spaceIcon = "circle.fill"
                newSpace.spaceOrder = 0
                modelContext.insert(newSpace)
                try? modelContext.save()
            }
        }
        
        // Update the storage manager's selected space
        if spaces.count > selectedSpaceIndex {
            storageManager.selectedSpace = spaces[selectedSpaceIndex]
        }
    }
    
    private func saveTabs() {
        if UserDefaults.standard.integer(forKey: "savedSelectedSpaceIndex") > spaces.count - 1 {
            selectedSpaceIndex = 0
        }
        
        if spaces.count > selectedSpaceIndex {
            // Save changes to SwiftData model
            try? modelContext.save()
        }
    }
    
    private func removeItem(_ id: UUID) {
        mobileTabs.browseForMeTabs.removeAll { $0 == id.description }
        
        // Find and remove the tab from the current space
        guard let currentSpace = storageManager.selectedSpace else { return }
        
        let allTabs: [StoredTab]
        switch uiViewModel.currentTabTypeMobile {
        case .primary:
            allTabs = currentSpace.primaryTabs
        case .pinned:
            allTabs = currentSpace.pinnedTabs
        case .favorites:
            allTabs = currentSpace.favoriteTabs
        }
        
        if let tabToRemove = allTabs.first(where: { UUID(uuidString: $0.id) == id }) {
            modelContext.delete(tabToRemove)
            try? modelContext.save()
        }
        
        withAnimation {
            mobileTabs.offsets.removeValue(forKey: id)
            mobileTabs.tilts.removeValue(forKey: id)
            mobileTabs.zIndexes.removeValue(forKey: id)
        }
    }
    
    private func updateTabURL(for id: UUID, with newURL: String) {
        // URL updates are handled by StorageManager automatically
    }
    
    
    private func createTab(url: String, isBrowseForMeTab: Bool) {
        guard let currentSpace = storageManager.selectedSpace else { return }
        
        // Create a new StoredTab
        let storedTab = StoredTab(
            id: UUID().uuidString,
            url: url,
            orderIndex: 0,
            tabType: uiViewModel.currentTabTypeMobile,
            parentSpace: currentSpace
        )
        
        // Add to model context and save
        modelContext.insert(storedTab)
        
        if isBrowseForMeTab {
            mobileTabs.browseForMeTabs.append(storedTab.id)
        }
        
        try? modelContext.save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            withAnimation {
                uiViewModel.currentSelectedTab = storedTab.id
                mobileTabs.fullScreenWebView = true
            }
        })
    }
    
    // MARK: - Helper Functions
    
    private func findTabById(_ id: String, in space: SpaceData) -> StoredTab? {
        let allTabs = space.primaryTabs + space.pinnedTabs + space.favoriteTabs
        return allTabs.first { $0.id == id }
    }
}


struct NamespaceEnvironmentKey: EnvironmentKey {
    static var defaultValue: Namespace.ID = Namespace().wrappedValue
}

extension EnvironmentValues {
    var namespace: Namespace.ID {
        get { self[NamespaceEnvironmentKey.self] }
        set { self[NamespaceEnvironmentKey.self] = newValue }
    }
}

extension View {
    func namespace(_ value: Namespace.ID) -> some View {
        environment(\.namespace, value)
    }
}
