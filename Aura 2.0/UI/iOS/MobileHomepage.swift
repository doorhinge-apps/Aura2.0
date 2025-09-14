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
    
    @FocusState var searchFocused
    
    @State var showNewTabPage = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: backgroundGradientColors, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .all)
                
                if let selectedSpace = storageManager.selectedSpace {
                    ScrollView {
                        VStack {
                            Spacer()
                                .frame(height: 50)
                            
                            MobileTabGrid(space: selectedSpace, draggingTabID: $draggingTabID, currentTabType: currentTabType, namespace: namespace)
                        }
                    }
                    .modifier(ScrollEdgeDisabledIfAvailable())
                    .tag(selectedSpace)
                }
                else {
                    EmptyView()
                        .onAppear() {
                            storageManager.selectedSpace = spaces.first
                        }
                }
                
                VStack {
                    HStack {
                        Spacer()
                        
                        Menu {
                            Button {
                                uiViewModel.showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape")
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
                                Label("New Space", systemImage: "plus.app")
                            }
                            
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.thinMaterial)
                                    .stroke(Color.black.opacity(0.5), lineWidth: 2)
                                
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                    .opacity(uiViewModel.hoveringID == "settings" ? 1.0: 0.5)
                                
                            }.frame(width: 40, height: 40)
                                .cornerRadius(20)
                        }
                    }.padding(20)
                    
                    Spacer()
                    
                    
                    VStack {
                        HStack {
                            TextField(text: $uiViewModel.commandBarText) {
                                Label("Search Open Tabs", systemImage: "magnifyingglass")
                            }
                                .padding(10)
                                .focused($searchFocused)
                                .background(content: {
                                    Capsule()
                                        .fill(.regularMaterial)
                                        .stroke(Color(hex: "7B7B7B").opacity(0.5), lineWidth: 1)
//                                        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                        .onTapGesture {
                                            searchFocused = true
                                        }
                                })
                            
                            Button {
                                showNewTabPage = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.regularMaterial)
                                        .stroke(Color(hex: "7B7B7B"), lineWidth: 2)
                                        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                    
                                    Image(systemName: "plus")
                                        .foregroundStyle(Color.black)
                                        .opacity(0.5)
                                        .padding(.horizontal, 20)
                                    
                                }.frame(width: 50, height: 50)
                                    .cornerRadius(30)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding(10)
                        
                        HStack(spacing: -100) {
                            ForEach(Array(spaces.enumerated()), id: \.element) { index, space in
                                let (zIndex, scale, isVisible) = calculateDisplayProperties(
                                    currentIndex: index,
                                    selectedSpace: storageManager.selectedSpace,
                                    spaces: spaces
                                )
                                if isVisible {
                                    Button {
                                        withAnimation {
                                            storageManager.selectedSpace = space
                                        }
                                    } label: {
                                        ZStack {
                                            Capsule()
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
                        
                        Spacer()
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .frame(width: geo.size.width-40, height: 130)
                    .background(content: {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial)
                        
                    })
                    .padding(.bottom, 20)
                    .sheet(isPresented: $uiViewModel.showSettings) {
                        Settings()
                    }
                }
                
                if showNewTabPage {
                    ZStack {
                        LinearGradient(colors: backgroundGradientColors, startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea(edges: .all)
                        VStack {
                            LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem()]) {
                                if let favoriteTabs = storageManager.selectedSpace?.favoriteTabGroups {
                                    ForEach(favoriteTabs, id:\.id) { favoriteTab in
                                        if let url = favoriteTab.tabRows?.first?.tabs?.first?.url {
                                            Favicon(url: url)
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                TextField(text: $uiViewModel.commandBarText) {
                                    Text("Search or Enter URL")
                                }
                                .padding(10)
                                .focused($searchFocused)
                                .background(content: {
                                    Capsule()
                                        .fill(.regularMaterial)
                                        .stroke(Color(hex: "7B7B7B").opacity(0.5), lineWidth: 1)
                                    //                                        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                        .onTapGesture {
                                            searchFocused = true
                                        }
                                })
                                
                                Button {
                                    withAnimation {
                                        if let selectedSpace = storageManager.selectedSpace {
                                            storageManager.newTab(unformattedString: uiViewModel.commandBarText, space: selectedSpace, modelContext: modelContext)
                                        }
                                        
                                        showNewTabPage = false
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(.regularMaterial)
                                            .stroke(Color(hex: "7B7B7B"), lineWidth: 2)
                                            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                        
                                        Image(systemName: "magnifyingglass")
                                            .foregroundStyle(Color.black)
                                            .opacity(0.5)
                                            .padding(.horizontal, 20)
                                        
                                    }.frame(width: 50, height: 50)
                                        .cornerRadius(30)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        }
                    }.animation(.easeInOut, value: showNewTabPage)
                }
                
                if let thing = storageManager.currentTabs.first {
                    if !thing.isEmpty {
                        ZStack {
                            WebsiteMobile()
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
