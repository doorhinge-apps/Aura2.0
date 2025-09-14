//
// Aura 2.0
// SpaceToolsBar.swift
//
// Created on 6/21/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData
import WebKit

struct SpaceToolsBar: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @State var space: SpaceData
    
    @FocusState var renameIsFocused: Bool
    
    @State var temporaryRenameSpace = ""
    
    @State private var presentIcons = false
    
    @State private var changeColorSheet = false
    
    @State private var changingIcon = ""
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                    .frame(width: 50, height: 40)
                
                ZStack {
                    TextField("", text: $temporaryRenameSpace)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color(hex: space.textColor ?? "ffffff"))
                        .opacity(renameIsFocused ? 0.75: 0)
                        .tint(Color.white)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .focused($renameIsFocused)
                        .onSubmit {
                            storageManager.selectedSpace?.spaceName = temporaryRenameSpace
                            
                            Task {
                                do {
                                    try modelContext.save()
                                }
                                catch {
                                    print(error.localizedDescription)
                                }
                            }
                            
                            temporaryRenameSpace = ""
                        }
                    
                }
                
            }
            
            HStack {
                Button {
                    presentIcons.toggle()
                } label: {
                    ZStack {
                        Color.white.opacity(uiViewModel.hoveringID == "sidebarIconChanging" ? 0.25: 0.0)
                        
                        Image(systemName: space.spaceIcon ?? "circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color(hex: space.textColor ?? "ffffff"))
                            .opacity(uiViewModel.hoveringID == "sidebarIconChanging" ? 1.0: 0.5)
                        
                    }.frame(width: 40, height: 40).cornerRadius(7)
                        .onHover { hover in
                            withAnimation {
                                if uiViewModel.hoveringID == "sidebarIconChanging" {
                                    uiViewModel.hoveringID = ""
                                }
                                else {
                                    uiViewModel.hoveringID = "sidebarIconChanging"
                                }
                            }
                        }
                }.buttonStyle(.plain)
                
                Text((!renameIsFocused ? space.spaceName: temporaryRenameSpace) ?? "Untitled")
                    .foregroundStyle(Color(hex: space.textColor ?? "ffffff"))
                    .opacity(!renameIsFocused ? 1.0: 0)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .onTapGesture {
                        temporaryRenameSpace = space.spaceName ?? ""
                        temporaryRenameSpace = String(temporaryRenameSpace)
                        renameIsFocused = true
                    }
#if !os(visionOS) && !os(macOS)
                    .hoverEffect(.lift)
#endif
                
                if renameIsFocused {
                    Button(action: {
                        renameIsFocused = false
                    }, label: {
                        Image(systemName: "checkmark.circle.fill")
                            .frame(height: 20)
                            .foregroundStyle(Color.white)
                            .opacity(0.5)
                    })
                }
                
                Color(hex: space.textColor ?? "ffffff")
                    .opacity(0.5)
                    .frame(height: 1)
                    .cornerRadius(10)
                
                
                Menu {
                    VStack {
                        Button(action: {
                            changeColorSheet.toggle()
                        }, label: {
                            Label("Edit Theme", systemImage: "paintpalette")
                        })
                        
                        Button(action: {
                            temporaryRenameSpace = space.spaceName ?? ""
                            temporaryRenameSpace = String(temporaryRenameSpace)
                            renameIsFocused = true
                        }, label: {
                            Label("Rename Space", systemImage: "rectangle.and.pencil.and.ellipsis.rtl")
                        })
                        
                        Button(action: {
                            presentIcons.toggle()
                        }, label: {
                            Label("Change Space Icon", systemImage: space.spaceIcon ?? "circle.fill")
                        })
                    }
                } label: {
                    ZStack {
                        Color.white.opacity(uiViewModel.hoveringID == "spaceActionsMenu" ? 0.25: 0.0)
                        
                        Image(systemName: "ellipsis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color(hex: space.textColor ?? "ffffff"))
                            .opacity(uiViewModel.hoveringID == "spaceActionsMenu" ? 1.0: 0.5)
                        
                    }.frame(width: 40, height: 40).cornerRadius(7)
                        .onHover { hover in
                            withAnimation {
                                if uiViewModel.hoveringID == "spaceActionsMenu" {
                                    uiViewModel.hoveringID = ""
                                }
                                else {
                                    uiViewModel.hoveringID = "spaceActionsMenu"
                                }
                            }
                        }
                }
            }
        }
        .padding(.vertical, 10)
        .popover(isPresented: $changeColorSheet, attachmentAnchor: .point(.trailing), arrowEdge: .leading) {
            VStack(spacing: 20) {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: backgroundGradientColors), startPoint: .bottomLeading, endPoint: .topTrailing)
                        .frame(width: 250, height: 200)
                        .ignoresSafeArea()
                        .offset(x: -10)
                }
                .frame(width: 200, height: 200)
                
                VStack(spacing: 12) {
                    if let selectedSpace = storageManager.selectedSpace {
                        let colorsBinding = Binding<[String]>(
                            get: { selectedSpace.spaceBackgroundColors },
                            set: { selectedSpace.spaceBackgroundColors = $0 }
                        )
                        
                        let adaptiveThemeBinding = Binding<Bool>(
                            get: {
                                storageManager.selectedSpace?.adaptiveTheme ?? false
                            },
                            set: { newValue in
                                if var space = storageManager.selectedSpace {
                                    space.adaptiveTheme = newValue
                                    storageManager.selectedSpace = space
                                }
                            }
                        )
                        
                        //Toggle("Adaptive Theme", isOn: adaptiveThemeBinding)
                        
                        ForEach(colorsBinding.wrappedValue.indices, id: \.self) { idx in
                            HStack {
                                ColorPicker(
                                    "Color \(idx + 1)",
                                    selection: Binding(
                                        get: { Color(hex: colorsBinding.wrappedValue[idx]) },
                                        set: { newColor in
                                            var updated = colorsBinding.wrappedValue
                                            updated[idx] = newColor.toHex()
                                            colorsBinding.wrappedValue = updated
                                        }
                                    ),
                                    supportsOpacity: false
                                )
                                if colorsBinding.wrappedValue.count > 1 {
                                    Button {
                                        var updated = colorsBinding.wrappedValue
                                        updated.remove(at: idx)
                                        colorsBinding.wrappedValue = updated
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Button {
                            if let lastHex = colorsBinding.wrappedValue.last {
                                var updated = colorsBinding.wrappedValue
                                updated.append(lastHex)
                                colorsBinding.wrappedValue = updated
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Color")
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .popover(isPresented: $presentIcons, attachmentAnchor: .point(.trailing), arrowEdge: .leading) {
            ZStack {
                LinearGradient(colors: backgroundGradientColors, startPoint: .bottomLeading, endPoint: .topTrailing).ignoresSafeArea()
                    .opacity(1.0)
                
                //IconsPicker(currentIcon: $changingIcon)
                IconsPicker(currentIcon: $changingIcon)
                    .onChange(of: changingIcon) {
                        //spaces[selectedSpaceIndex].spaceIcon = changingIcon
                        storageManager.selectedSpace?.spaceIcon = changingIcon
                        do {
                            try modelContext.save()
                        }
                        catch {
                            
                        }
                    }
                    .onDisappear() {
                        changingIcon = ""
                    }
            }
        }
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
