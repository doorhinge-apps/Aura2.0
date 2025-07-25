//
// Aura 2.0
// AppearanceSettings.swift
//
// Created on 6/18/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import Combine

struct AppearanceSettings: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    let fastTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    @State private var gradientStartPoint: UnitPoint = .bottomLeading
    @State private var gradientEndPoint: UnitPoint = .topTrailing
    
#if !os(macOS)
    @StateObject var motionManager = MotionManager()
    #endif
    private let maxDegrees: Double = 30
    private let rotationScale: Double = 0.5
    
    @State var typingString = ""
    
    @State var showFakeCommandBar = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ).ignoresSafeArea()
            
            ScrollView {
                VStack {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Image(settingsManager.commandBarOnLaunch ? "iOS Settings Image Keyboard": "iOS Settings Image")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .frame(width: 150)
#if !os(visionOS)
                            .rotation3DEffect(
                                max(min(Angle.radians(motionManager.magnitude * rotationScale), Angle.degrees(maxDegrees)), Angle.degrees(-maxDegrees)),
                                axis: (x: CGFloat(UIDevice.current.orientation == .portrait ? motionManager.x: -motionManager.y), y: CGFloat(UIDevice.current.orientation == .portrait ? -motionManager.y: -motionManager.x), z: 0.0)
                            )
#endif
                    }
                    else {
                        ZStack {
#if !os(visionOS)
                            LinearGradient(colors: backgroundGradientColors, startPoint: gradientStartPoint, endPoint: gradientEndPoint)
                                .ignoresSafeArea()
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 0)
                                .animation(.easeInOut(duration: 1), value: gradientStartPoint)
                                .animation(.easeInOut(duration: 1), value: gradientEndPoint)
#endif
                            
                            LinearGradient(colors: [settingsManager.prefferedColorScheme != "dark" ? Color.clear: Color.black.opacity(0.5), settingsManager.prefferedColorScheme != "dark" ? Color.clear: Color.black.opacity(0.5), settingsManager.prefferedColorScheme == "light" ? Color.clear: Color.black.opacity(0.5), settingsManager.prefferedColorScheme == "light" ? Color.clear: Color.black.opacity(0.5)], startPoint: .topLeading, endPoint: .bottom)
                                .ignoresSafeArea()
                                .animation(.easeInOut(duration: 1))
                            
                            HStack {
                                if settingsManager.tabsPosition == "right" {
                                    Image("Arc Website")
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(5)
                                        .padding([.top, .bottom, .leading], settingsManager.showBorder ? 5: 0)
                                    
                                    Spacer()
                                }
                                
                                ScrollView(showsIndicators: false) {
                                    VStack {
                                        Spacer()
                                            .frame(height: 10)
                                        HStack {
                                            ForEach(0...1, id:\.self) { thing in
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.white.opacity(0.5))
                                                    
                                                    HStack {
                                                        Text("\(randomString(length: 3))")
                                                        
                                                    }.font(.system(size: 7, weight: .regular, design: .rounded))
                                                        .padding(.horizontal, 5)
                                                }.frame(width: 29, height: 15)
                                            }
                                        }
                                        ForEach(0..<6, id:\.self) { fakeTab in
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white.opacity(0.5))
                                                
                                                HStack {
                                                    Text("\(randomString(length: 10))")
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "xmark")
                                                    
                                                }.font(.system(size: 7, weight: .regular, design: .rounded))
                                                    .padding(.horizontal, 5)
                                            }.frame(width: 65, height: 15)
                                        }
                                    }.padding(settingsManager.tabsPosition == "left" ? .leading: .trailing, 10)
                                }
                                
                                if settingsManager.tabsPosition == "left" {
                                    Spacer()
                                    
                                    Image("Arc Website")
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(5)
                                        .padding([.top, .bottom, .trailing], settingsManager.showBorder ? 5: 0)
                                }
                            }
                            
                            if !showFakeCommandBar && settingsManager.commandBarOnLaunch {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.regularMaterial)
                                    
                                    VStack {
                                        ZStack {
                                            HStack {
                                                Text("\(typingString)")
                                                
                                                Spacer()
                                                
                                            }.font(.system(size: 7, weight: .regular, design: .rounded))
                                                .padding(.horizontal, 5)
                                        }.frame(height: 10)
                                        
                                        ForEach(0..<3, id:\.self) { fakeTab in
                                            ZStack {
                                                HStack {
                                                    Text("\(randomString(length: 15))")
                                                    
                                                    Spacer()
                                                    
                                                }.font(.system(size: 7, weight: .regular, design: .rounded))
                                                    .padding(.horizontal, 5)
                                            }.frame(height: 10)
                                        }
                                    }
                                }
                                .frame(width: 150, height: 75)
                            }
                            
                        }.frame(width: 300, height: 200)
                            .clipped()
                            .onReceive(timer, perform: { thing in
                                showFakeCommandBar.toggle()
                                typingString = ""
                            })
                            .onReceive(fastTimer, perform: { thing in
                                if typingString.count == 0 {
                                    typingString = "a"
                                }
                                else if typingString.count == 1 {
                                    typingString = "au"
                                }
                                else if typingString.count == 2 {
                                    typingString = "aur"
                                }
                                else if typingString.count == 3 {
                                    typingString = "aura"
                                }
                                else {
                                    typingString = ""
                                }
                            })
                            .cornerRadius(8)
                            .foregroundStyle(Color.black)
#if !os(visionOS) && !os(macOS)
                            .rotation3DEffect(
                                max(min(Angle.radians(motionManager.magnitude * rotationScale), Angle.degrees(maxDegrees)), Angle.degrees(-maxDegrees)),
                                axis: (x: CGFloat(UIDevice.current.orientation == .portrait ? motionManager.x: -motionManager.y), y: CGFloat(UIDevice.current.orientation == .portrait ? -motionManager.y: -motionManager.x), z: 0.0)
                            )
#elseif os(macOS)
                        
#else
                            .hoverEffect(.lift)
#endif
                    }
                    
                    if #available(iOS 26, *) {
                        Group {
                            Toggle(isOn: $settingsManager.liquidGlassCommandBar) {
                                Text("Liquid Glass Command Bar")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                            }.tint(backgroundGradientColors.first?.opacity(0.5))
                            HStack {
                                Text("Use the liquid glass UI style for the command bar.")
                                    .font(.system(.body, design: .rounded, weight: .bold))
                                
                                Spacer()
                            }
                        }
                        
                        Divider()
                    }
                    
                    Group {
                        Toggle(isOn: $settingsManager.showBorder) {
                            Text("Show Borders")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }.tint(backgroundGradientColors.first?.opacity(0.5))
                        HStack {
                            Text("Show borders around the screen and websites.")
                                .font(.system(.body, design: .rounded, weight: .bold))
                            
                            Spacer()
                        }
                    }
                    
                    Divider()
                    
                    Group {
                        Toggle(isOn: $settingsManager.useUnifiedToolbar) {
                            Text("Unified Toolbar")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }.tint(backgroundGradientColors.first?.opacity(0.5))
                        HStack {
                            Text("Put the searchbar and other toolbar items in the same row.")
                                .font(.system(.body, design: .rounded, weight: .bold))
                            
                            Spacer()
                        }
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Favorites Display Mode")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        
                        Picker(selection: $settingsManager.favoritesDisplayMode) {
                            Text("Title").tag("title")
                            Text("Icon").tag("icon")
                            Text("Title & Icon").tag("title+icon")
                        } label: {
                        }.pickerStyle(.segmented)
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Color Settings")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        
                        Picker(selection: $settingsManager.prefferedColorScheme) {
                            Text("Automatic").tag("automatic")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        } label: {
//                            Label("Automatic", systemImage: "circle.lefthalf.striped.horizontal.inverse")
//                            Label("Light", systemImage: "sun.max.fill")
//                            Label("Dark", systemImage: "moon.stars.fill")
                        }.pickerStyle(.segmented)
                        Text("Force Dark Mode On Websites")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        
                        Picker(selection: $settingsManager.forceDarkMode) {
                            Text("None").tag("none")
                            Text("Basic").tag("basic")
                            Text("Advanced").tag("advanced")
                        } label: {
                        }.pickerStyle(.segmented)
                        
                        Picker(selection: $settingsManager.forceDarkModeTime) {
                            Text("Automatic").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        } label: {
                        }.pickerStyle(.segmented)
                    }
                    
                }.foregroundStyle(Color.white)
                    .padding(15)
            }
        }
    }
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
