//
// Aura 2.0
// Sidebar.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData
import WebKit
import UniformTypeIdentifiers

struct MobileHomepage: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @State private var dragOffset: CGFloat = 0
    
    @State private var startWidth: CGFloat?
    
    @State var hoverSearch = false
    
    @State private var draggingTabID: String?
    
    @State var currentTabType = TabType.primary
    
    @Namespace var namespace
    
    @State var dragUpGesture: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: backgroundGradientColors, startPoint: .top, endPoint: .bottom)
                HStack(spacing: 0) {
                    VStack {
                        Spacer()
                            .frame(height: 50)
                        
                        if !settingsManager.useUnifiedToolbar {
                            Toolbar()
                        }
                        
                        HStack {
                            Button {
                                withAnimation {
                                    if hoverSearch || !settingsManager.useUnifiedToolbar {
                                        uiViewModel.showCommandBar.toggle()
                                    }
                                    else {
                                        hoverSearch = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            withAnimation {
                                                hoverSearch = false
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if !hoverSearch && settingsManager.useUnifiedToolbar {
                                        Spacer()
                                    }
                                    
                                    HStack {
                                        if storageManager.currentTabs.first?.first?.page != nil {
                                            Menu {
                                                if storageManager.currentTabs.first?.first?.page.hasOnlySecureContent ?? false {
                                                    Label("Secure", systemImage: "lock.fill")
                                                        .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                                                }
                                                else {
                                                    Label("Not Secure", systemImage: "lock.open.fill")
                                                        .foregroundStyle(Color.red)
                                                }
                                            } label: {
                                                Image(systemName: storageManager.currentTabs.first?.first?.page.hasOnlySecureContent ?? false ? "lock.fill": "lock.open.fill")
                                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                                    .foregroundStyle(storageManager.currentTabs.first?.first?.page.hasOnlySecureContent ?? false ? Color.white: Color.red)
                                            }
                                            
                                        }
                                        else {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(.body, design: .rounded, weight: .semibold))
                                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                                        }
                                        
                                        Text(hoverSearch || !settingsManager.useUnifiedToolbar ? unformatURL(url: getFocusedOrFirstTabURL()): "")
                                            .lineLimit(1)
                                            .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                                    }
                                    //                            Label(hoverSearch || !settingsManager.useUnifiedToolbar ? unformatURL(url: storageManager.currentTabs.first?.first?.storedTab.url ?? "Search or Enter URL"): "", systemImage: "magnifyingglass")
                                    //                                .lineLimit(1)
                                    //                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                                    
                                    Spacer()
                                    
                                    if (hoverSearch) && storageManager.currentTabs.first?.first?.page != nil {
                                        Button {
                                            UIPasteboard.general.string = storageManager.currentTabs[0][0].storedTab.url
                                        } label: {
                                            ZStack {
                                                Color.white.opacity(uiViewModel.hoveringID == "searchbarCopy" ? 0.25: 0.0)
                                                
                                                Image(systemName: "link")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                                    .opacity(uiViewModel.hoveringID == "searchbarCopy" ? 1.0: 0.5)
                                                
                                            }.frame(width: 40, height: 40).cornerRadius(7)
                                                .onHover { hover in
                                                    withAnimation {
                                                        if uiViewModel.hoveringID == "searchbarCopy" {
                                                            uiViewModel.hoveringID = ""
                                                        }
                                                        else {
                                                            uiViewModel.hoveringID = "searchbarCopy"
                                                        }
                                                    }
                                                }
                                        }
                                        
                                        
                                        Button {
                                            let activityController = UIActivityViewController(activityItems: [storageManager.currentTabs.first?.first?.page.url ?? URL(string: "")!, storageManager.currentTabs.first?.first?.page ?? WebPageFallback()], applicationActivities: nil)
                                            
                                            if let popoverController = activityController.popoverPresentationController {
                                                popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                                                
                                                popoverController.permittedArrowDirections = [.up]
                                                popoverController.permittedArrowDirections = []
                                            }
                                            
                                            UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
                                        } label: {
                                            ZStack {
                                                Color.white.opacity(uiViewModel.hoveringID == "searchbarShare" ? 0.25: 0.0)
                                                
                                                Image(systemName: "square.and.arrow.up")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                                    .opacity(uiViewModel.hoveringID == "searchbarShare" ? 1.0: 0.5)
                                                
                                            }.frame(width: 40, height: 40).cornerRadius(7)
                                                .onHover { hover in
                                                    withAnimation {
                                                        if uiViewModel.hoveringID == "searchbarShare" {
                                                            uiViewModel.hoveringID = ""
                                                        }
                                                        else {
                                                            uiViewModel.hoveringID = "searchbarShare"
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                }
                                .padding(.horizontal, 15)
                                .frame(width: hoverSearch || !settingsManager.useUnifiedToolbar ? .infinity: 50, height: 50)
                                .background() {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(hoverSearch ? 0.25: 0.15))
                                }
                                .onHover { hover in
                                    withAnimation {
                                        hoverSearch = hover
                                    }
                                }
                            }
                            
                            if settingsManager.useUnifiedToolbar {
                                Toolbar()
                                    .frame(width: hoverSearch ? 0: .infinity)
                                    .clipped()
                            }
                            
                            Spacer()
                        }
                        
                        
                        
                        if let selectedSpace = storageManager.selectedSpace {
                            //                    TabView(selection: $storageManager.selectedSpace) {
                            //                        ForEach(spaces, id:\.id) { space in
                            ScrollView {
                                VStack {
                                    MobileTabGrid(space: selectedSpace, draggingTabID: $draggingTabID, currentTabType: currentTabType, namespace: namespace)
                                }
                            }//.scrollEdgeEffectDisabled(true)
                            .modifier(ScrollEdgeDisabledIfAvailable())
                            .tag(selectedSpace)
                            //                        }
                            //                    }
                            //                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        }
                        else {
                            EmptyView()
                                .onAppear() {
                                    storageManager.selectedSpace = spaces.first
                                }
                        }
                        
                        
                        HStack {
                            Button {
                                uiViewModel.showSettings = true
                            } label: {
                                ZStack {
                                    Color.white.opacity(uiViewModel.hoveringID == "settings" ? 0.25: 0.0)
                                    
                                    Image(systemName: "gearshape")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                        .opacity(uiViewModel.hoveringID == "settings" ? 1.0: 0.5)
                                    
                                }.frame(width: 40, height: 40).cornerRadius(7)
                                    .onHover { hover in
                                        withAnimation {
                                            if uiViewModel.hoveringID == "settings" {
                                                uiViewModel.hoveringID = ""
                                            }
                                            else {
                                                uiViewModel.hoveringID = "settings"
                                            }
                                        }
                                    }
                            }
                            
                            // MARK: - Switch Spaces
                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(spaces, id:\.self) { space in
                                            Button {
                                                storageManager.selectedSpace = space
                                                withAnimation {
                                                    proxy.scrollTo(space.id, anchor: .center)
                                                }
                                            } label: {
                                                ZStack {
                                                    Color.white.opacity(0.5)
                                                    
                                                    Label(space.spaceName, systemImage: space.spaceIcon)
                                                    //                                            Image(systemName: space.spaceIcon)
                                                    //                                                .resizable()
                                                    //                                                .scaledToFit()
                                                    //                                                .frame(width: 20, height: 20)
                                                    //                                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                                    //                                                .opacity(uiViewModel.hoveringID == space.spaceIdentifier ? 1.0: 0.5)
                                                        .foregroundStyle(storageManager.selectedSpace?.spaceIdentifier == space.spaceIdentifier ? Color.black: Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                                        .opacity(uiViewModel.hoveringID == space.spaceIdentifier ? 1.0: 0.5)
                                                        .padding(.horizontal, 20)
                                                    
                                                }.frame(height: 50)
                                                    .cornerRadius(10)
                                                    .onHover { hover in
                                                        withAnimation {
                                                            if uiViewModel.hoveringID == space.spaceIdentifier {
                                                                uiViewModel.hoveringID = ""
                                                            }
                                                            else {
                                                                uiViewModel.hoveringID = space.spaceIdentifier
                                                            }
                                                        }
                                                    }
                                            }.id(space.id.storeIdentifier)
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                let newSpace = SpaceData(
                                    spaceIdentifier: UUID().uuidString,
                                    spaceName: "Untitled",
                                    isIncognito: false,
                                    spaceBackgroundColors: ["8041E6", "A0F2FC"],
                                    textColor: "#ffffff"
                                )
                                
                                modelContext.insert(newSpace)
                            } label: {
                                ZStack {
                                    Color.white.opacity(uiViewModel.hoveringID == "addNewSpace" ? 0.25: 0.0)
                                    
                                    Image(systemName: "plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                        .opacity(uiViewModel.hoveringID == "addNewSpace" ? 1.0: 0.5)
                                    
                                }.frame(width: 40, height: 40).cornerRadius(7)
                                    .onHover { hover in
                                        withAnimation {
                                            if uiViewModel.hoveringID == "addNewSpace" {
                                                uiViewModel.hoveringID = ""
                                            }
                                            else {
                                                uiViewModel.hoveringID = "addNewSpace"
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 30)
                        .sheet(isPresented: $uiViewModel.showSettings) {
                            Settings()
                        }
                    }
                    .clipped()
                }//.blur(radius: max(0.5, 1.0 - 0.5 * (abs(dragUpGesture) / 800.0)))
                
                //            Rectangle()
                //                .fill(.regularMaterial)
                //                .ignoresSafeArea()
                //                .opacity(max(0.5, 1.0 - 0.5 * (abs(dragUpGesture) / 800.0)))
                
                if let thing = storageManager.currentTabs.first {
                    if !thing.isEmpty {
                        ZStack {
                            WebsitePanel()
                                .matchedGeometryEffect(id: thing.first?.storedTab.id ?? "websitePreview", in: namespace, properties: .frame, anchor: .center)
                                .background {
                                    Color("Automatic")
                                }
                                .offset(y: dragUpGesture)
                                .scaleEffect(max(0.5, 1.0 - 0.5 * (1.0 - exp(-abs(dragUpGesture) / 200.0))))
                            
                            VStack {
                                Spacer()
                                
                                ZStack {
                                    VStack {
                                        HStack {
                                            Button {
                                                if let page = storageManager.currentTabs.first?.first?.page {
                                                    page.goBack()
                                                }
                                            } label: {
                                                ZStack {
                                                    Image(systemName: "arrow.left")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 20, height: 20)
                                                        .foregroundStyle(Color(.systemBlue))
                                                    
                                                }.frame(width: 40, height: 40).cornerRadius(7)
                                            }
                                            
                                            Button {
                                                if let page = storageManager.currentTabs.first?.first?.page {
                                                    page.goForward()
                                                }
                                            } label: {
                                                ZStack {
                                                    Image(systemName: "arrow.right")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 20, height: 20)
                                                        .foregroundStyle(Color(.systemBlue))
                                                    
                                                }.frame(width: 40, height: 40).cornerRadius(7)
                                            }
                                            
                                            Button {
                                                
                                            } label: {
                                                ZStack {
                                                    Image(systemName: "square.and.arrow.up")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 20, height: 20)
                                                        .foregroundStyle(Color(.systemBlue))
                                                    
                                                }.frame(width: 40, height: 40).cornerRadius(7)
                                            }
                                            
                                            Button {
                                                withAnimation {
                                                    storageManager.currentTabs = [[]]
                                                }
                                            } label: {
                                                ZStack {
                                                    Image(systemName: "square.on.square")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 20, height: 20)
                                                        .foregroundStyle(Color(.systemBlue))
                                                    
                                                }.frame(width: 40, height: 40).cornerRadius(7)
                                            }
                                        }
                                        TextField("Search or enter URL", text: $uiViewModel.commandBarText)
                                            .padding(.horizontal, 10)
                                            .frame(width: geo.size.width - 75, height: 50)
                                            .glassEffect(.clear, in: .capsule)
                                    }.padding(10)
                                }.glassEffect(.regular, in: .rect(cornerRadius: 25))
                                    .padding(10)
                                    .offset(y: dragUpGesture)
                                    .highPriorityGesture(
                                        DragGesture(minimumDistance: 20)
                                            .onChanged { gesture in
                                                dragUpGesture = gesture.translation.height
                                                print(dragUpGesture)
                                            }
                                            .onEnded({ gesture in
                                                if abs(dragUpGesture) > 150 {
                                                    withAnimation {
                                                        storageManager.currentTabs = [[]]
                                                    }
                                                    dragUpGesture = 0
                                                }
                                                else {
                                                    withAnimation {
                                                        dragUpGesture = 0
                                                    }
                                                }
                                            })
                                    )
                            }
                        }
                    }
                }
                //            Text(dragUpGesture.description)
            }.onAppear() {
                storageManager.selectedSpace = spaces.first
            }
        }
    }
    
    /// Get the URL of the focused tab, or fallback to first tab
    private func getFocusedOrFirstTabURL() -> String {
        // Try to get focused tab URL
        if let focusedTab = storageManager.getFocusedTab() {
            return focusedTab.storedTab.url
        }
        
        // Fallback to first tab
        return storageManager.currentTabs.first?.first?.storedTab.url ?? "Search or Enter URL"
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
