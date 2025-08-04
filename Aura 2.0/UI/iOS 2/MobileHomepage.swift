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
    
    @State private var dragOffset2: CGFloat = 0
    @State private var initialSelectedIndex: Int = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: backgroundGradientColors, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .all)
                
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
//                            ScrollViewReader { proxy in
//                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: -100) {
//                                        ForEach(spaces, id:\.self) { space in
                                        ForEach(Array(spaces.enumerated()), id: \.element) { index, space in
                                            let (zIndex, scale, isVisible) = calculateDisplayProperties(
                                                currentIndex: index,
                                                selectedSpace: storageManager.selectedSpace,
                                                spaces: spaces
                                            )
                                            if isVisible {
                                                Button {
//                                                    withAnimation {
//                                                        proxy.scrollTo(space.id, anchor: .center)
//                                                    }
                                                    withAnimation {
                                                        storageManager.selectedSpace = space
                                                    }
                                                } label: {
                                                    ZStack {
                                                        Capsule()
//                                                            .fill(Color(hex: "7880B0"))
                                                            .fill(.regularMaterial)
                                                            .stroke(Color(hex: "7B7B7B"), lineWidth: 2)
                                                            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                                        
                                                        Label(space.spaceName, systemImage: space.spaceIcon)
                                                            .foregroundStyle(Color.black)
                                                            .opacity(uiViewModel.hoveringID == space.spaceIdentifier ? 1.0: 0.5)
                                                            .padding(.horizontal, 20)
                                                        
                                                    }.frame(width: 150, height: 50)
                                                        .cornerRadius(30)
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
                                                }
                                                .buttonStyle(PrimaryButtonStyle())
                                                .id(space.id)
                                                .zIndex(zIndex)
                                                .scaleEffect(scale)
                                            }
                                        }
                                        
//                                        Button {
//                                            let newSpace = SpaceData(
//                                                spaceIdentifier: UUID().uuidString,
//                                                spaceName: "Untitled",
//                                                isIncognito: false,
//                                                spaceBackgroundColors: ["8041E6", "A0F2FC"],
//                                                textColor: "#ffffff"
//                                            )
//                                            
//                                            modelContext.insert(newSpace)
//                                        } label: {
//                                            ZStack {
//                                                Color.white.opacity(0.5)
//                                                
//                                                Image(systemName: "plus")
//                                                    .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
//                                                    .opacity(uiViewModel.hoveringID == "createSpace" ? 1.0: 0.5)
//                                                    .padding(.horizontal, 20)
//                                            }
//                                        }.frame(width: 50, height: 50)
//                                            .cornerRadius(10)
//                                            .onHover { hover in
//                                                withAnimation {
//                                                    if uiViewModel.hoveringID == "createSpace" {
//                                                        uiViewModel.hoveringID = ""
//                                                    }
//                                                    else {
//                                                        uiViewModel.hoveringID = "createSpace"
//                                                    }
//                                                }
//                                            }
                                    }.ignoresSafeArea(.container, edges: .all)
                                .highPriorityGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                handleDragChanged(translation: value.translation.width, spaces: spaces)
                                            }
                                            .onEnded { value in
                                                handleDragEnded()
                                            }
                                    )
//                                }
//                            }.ignoresSafeArea(.container, edges: .all)
                        }
                        .padding(.bottom, 30)
                        .sheet(isPresented: $uiViewModel.showSettings) {
                            Settings()
                        }
                    }
                    .clipped()
                }
                
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
//                                            .glassEffect(.clear, in: .capsule)
                                            .modifier(WrappedGlassEffect(glass: .clear, shape: AnyShape(.capsule)))
                                    }.padding(10)
                                }
                                .ignoresSafeArea(.container, edges: .all)
                                    .modifier(WrappedGlassEffect(glass: .regular, shape: AnyShape(.rect(cornerRadius: 25))))
                                    .padding(10)
                                    .offset(y: dragUpGesture)
                                    .background(content: {
                                        Color.white.opacity(0.001)
                                    })
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
    
    func calculateZIndex(currentIndex: Int, selectedSpace: SpaceData?, spaces: [SpaceData]) -> Double {
        guard let selectedSpace = selectedSpace,
              let selectedIndex = spaces.firstIndex(where: { $0.spaceIdentifier == selectedSpace.spaceIdentifier }) else {
            return 12
        }
        
        let distance = abs(currentIndex - selectedIndex)
        let zIndex = max(12, 14 - distance)
        return Double(zIndex)
    }
    
    func calculateDisplayProperties(currentIndex: Int, selectedSpace: SpaceData?, spaces: [SpaceData]) -> (zIndex: Double, scale: Double, isVisible: Bool) {
        guard let selectedSpace = selectedSpace,
              let selectedIndex = spaces.firstIndex(where: { $0.spaceIdentifier == selectedSpace.spaceIdentifier }) else {
            return (12, 1.0, true) // Default if no selection
        }
        
        let distance = abs(currentIndex - selectedIndex)
        
        let isVisible = distance <= 2
        
        let zIndex = max(12, 14 - distance)
        
        let scale = pow(0.8, Double(distance))
        
        return (Double(zIndex), scale, isVisible)
    }
    
    func handleDragChanged(translation: CGFloat, spaces: [SpaceData]) {
        guard let currentSelectedSpace = storageManager.selectedSpace,
              let currentIndex = spaces.firstIndex(where: { $0.spaceIdentifier == currentSelectedSpace.spaceIdentifier }) else {
            return
        }
        
        if dragOffset == 0 {
            initialSelectedIndex = currentIndex
        }
        
        dragOffset = translation
        
        let steps = calculateStepsFromTranslation(translation)
        
        let newIndex = initialSelectedIndex - steps
        
        let clampedIndex = max(0, min(spaces.count - 1, newIndex))
        
        if clampedIndex != currentIndex {
            withAnimation(.easeOut(duration: 0.2)) {
                storageManager.selectedSpace = spaces[clampedIndex]
            }
        }
    }

    func calculateStepsFromTranslation(_ translation: CGFloat) -> Int {
        let absTranslation = abs(translation)
        var steps = 0
        var currentThreshold: CGFloat = 40
        
        while absTranslation >= currentThreshold {
            steps += 1
            currentThreshold += 100
        }
        
        return translation >= 0 ? steps : -steps
    }

    func handleDragEnded() {
        dragOffset = 0
        initialSelectedIndex = 0
    }
}
