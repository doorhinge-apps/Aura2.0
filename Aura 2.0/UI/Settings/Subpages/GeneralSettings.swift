//
// Aura 2.0
// GeneralSettings.swift
//
// Created on 6/18/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import Combine

struct GeneralSettings: View {
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
                    
                    
                    Toggle(isOn: $settingsManager.commandBarOnLaunch) {
                        Text("Command Bar on Launch")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }.tint(backgroundGradientColors.first?.opacity(0.5))
                    
                    Divider()
                    
                    // WebView Selection (iOS 26+ only)
                    if #available(iOS 26.0, *) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $settingsManager.useDeclarativeWebView) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use Modern WebView")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                    Text("Toggle between the new declarative WebView and traditional WKWebView")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }.tint(backgroundGradientColors.first?.opacity(0.5))
                        }
                        
                        Divider()
                    }
                    
                    Group {
                        Text("Loaded Websites in Background")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        HStack {
                            Text(String(Int(settingsManager.preloadingWebsites-2)))
                                .font(.system(.body, design: .rounded, weight: .bold))
                            
                            Slider(value: $settingsManager.preloadingWebsites, in: 4...30, step: 1)
                                .tint(backgroundGradientColors.first?.opacity(0.5))
                        }
                    }
                    
                    Group {
                        Text("Close Tabs After")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        
                        Picker(selection: $settingsManager.closePrimaryTabsAfter) {
                            Text("Never").tag(26297460.0)
                            Text("12 Hours").tag(720.0)
                            Text("1 Day").tag(1440.0)
                            Text("2 Days").tag(2880.0)
                            Text("3 Days").tag(4320.0)
                            Text("4 Days").tag(5760.0)
                            Text("5 Days").tag(7200.0)
                            Text("6 Days").tag(8640.0)
                            Text("7 Days").tag(10080.0)
                            Text("14 Days").tag(20160.0)
                            Text("30 Days").tag(43200.0)
                            Text("60 Days").tag(86400.0)
                        } label: {
                            HStack {
                                Text("Auto-Close Tabs After")
                                Spacer()
                                Text(displayLabel(for: settingsManager.closePrimaryTabsAfter))
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .pickerStyle(.menu)
                    }
                }.foregroundStyle(Color.white)
                    .padding(15)
            }
        }
    }
    
    func displayLabel(for minutes: Double) -> String {
        switch minutes {
        case 26297460.0: return "Never"
        case 720.0: return "12 Hours"
        case 1440.0: return "1 Day"
        case 2880.0: return "2 Days"
        case 4320.0: return "3 Days"
        case 5760.0: return "4 Days"
        case 7200.0: return "5 Days"
        case 8640.0: return "6 Days"
        case 10080.0: return "7 Days"
        case 20160.0: return "14 Days"
        case 43200.0: return "30 Days"
        case 86400.0: return "60 Days"
        default: return "\(Int(minutes)) min"
        }
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}

func randomString(length: Int) -> String {
  let letters = "abcd efghijkl mnopqrstuvwxyz ABCDEFGHIJK LMNOPQRSTUVWXYZ "
  return String((0..<length).map{ _ in letters.randomElement()! })
}
