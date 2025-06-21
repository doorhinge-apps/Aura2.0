//
// Aura 2.0
// Settings.swift
//
// Created on 6/14/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit

struct Settings: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ).ignoresSafeArea()
            
            NavigationStack {
                List {
                    NavigationLink {
                        GeneralSettings()
                    } label: {
                        HStack {
                            Image("General Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .padding(2)
                                .background {
                                    ZStack {
                                        LinearGradient(
                                            colors: backgroundGradientColors,
                                            startPoint: .bottomLeading,
                                            endPoint: .topTrailing
                                        ).ignoresSafeArea()
                                        
                                        Color.black.opacity(0.25)
                                    }.cornerRadius(5)
                                }
                            Text("General")
                        }
                    }
                    
                    NavigationLink {
                        AppearanceSettings()
                    } label: {
                        HStack {
                            Image("Appearance Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .padding(2)
                                .background {
                                    ZStack {
                                        LinearGradient(
                                            colors: backgroundGradientColors,
                                            startPoint: .bottomLeading,
                                            endPoint: .topTrailing
                                        ).ignoresSafeArea()
                                        
                                        Color.black.opacity(0.25)
                                    }.cornerRadius(5)
                                }
                            Text("Appearance")
                        }
                    }
                    
                    NavigationLink {
                        SearchSettings()
                    } label: {
                        HStack {
                            Image("Search Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .padding(2)
                                .background {
                                    ZStack {
                                        LinearGradient(
                                            colors: backgroundGradientColors,
                                            startPoint: .bottomLeading,
                                            endPoint: .topTrailing
                                        ).ignoresSafeArea()
                                        
                                        Color.black.opacity(0.25)
                                    }.cornerRadius(5)
                                }
                            Text("Search Settings")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
                
//                 .background(Color.blue)
//                NavigationLink {
//                    GeneralSettings()
//                } label: {
//                    Text("General")
//                }
//                
//                NavigationLink {
//                    AppearanceSettings()
//                } label: {
//                    Text("Appearance")
//                }
            }
        }
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
