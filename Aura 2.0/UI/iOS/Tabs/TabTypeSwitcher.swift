//
// Aura
// TabTypeSwitcher.swift
//
// Created by Reyna Myers on 4/11/24
//
// Copyright ©2024 DoorHinge Apps.
//


import SwiftUI

struct TabTypeSwitcherOld: View {
    @EnvironmentObject var mobileTabs: MobileTabsModel
    @EnvironmentObject var uiViewModel: UIViewModel
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack {
                Button(action: {
                    withAnimation {
                        uiViewModel.currentTabTypeMobile = .favorites
                    }
                }, label: {
                    Image(systemName: "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: uiViewModel.currentTabTypeMobile == .favorites ? 30: 20, height: uiViewModel.currentTabTypeMobile == .favorites ? 30: 20)
                        .opacity(uiViewModel.currentTabTypeMobile == .favorites ? 1.0: 0.4)
                        .foregroundStyle(Color(hex: "4D4D4D"))
                })
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            let dragHeight = value.translation.height
                            if dragHeight > 120 {
                                uiViewModel.currentTabTypeMobile = .primary
                            } else if dragHeight > 60 {
                                uiViewModel.currentTabTypeMobile = .pinned
                            }
                            else {
                                uiViewModel.currentTabTypeMobile = .favorites
                            }
                        }
                )
                .frame(height: 30)
                .padding(.vertical, 5)
                
                Button(action: {
                    withAnimation {
                        uiViewModel.currentTabTypeMobile = .pinned
                    }
                }, label: {
                    Image(systemName: "pin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: uiViewModel.currentTabTypeMobile == .pinned ? 30: 20, height: uiViewModel.currentTabTypeMobile == .pinned ? 30: 20)
                        .opacity(uiViewModel.currentTabTypeMobile == .pinned ? 1.0: 0.4)
                        .foregroundStyle(Color(hex: "4D4D4D"))
                })
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            let dragHeight = value.translation.height
                            if dragHeight > 60 {
                                uiViewModel.currentTabTypeMobile = .primary
                            } else if dragHeight < -60 {
                                uiViewModel.currentTabTypeMobile = .favorites
                            }
                            else {
                                uiViewModel.currentTabTypeMobile = .pinned
                            }
                        }
                )
                .frame(height: 30)
                .padding(.vertical, 5)
                
                Button(action: {
                    withAnimation {
                        uiViewModel.currentTabTypeMobile = .primary
                    }
                }, label: {
                    Image(systemName: "calendar.day.timeline.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: uiViewModel.currentTabTypeMobile == .primary ? 30: 20, height: uiViewModel.currentTabTypeMobile == .primary ? 30: 20)
                        .opacity(uiViewModel.currentTabTypeMobile == .primary ? 1.0: 0.4)
                        .foregroundStyle(Color(hex: "4D4D4D"))
                })
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            let dragHeight = value.translation.height
                            if dragHeight < -120 {
                                uiViewModel.currentTabTypeMobile = .favorites
                            } else if dragHeight < -60 {
                                uiViewModel.currentTabTypeMobile = .pinned
                            }
                            else {
                                uiViewModel.currentTabTypeMobile = .primary
                            }
                        }
                )
                .frame(height: 30)
                .padding(.vertical, 5)
            }
            .frame(width: 50, height: 150)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 0)
            )
            .padding(.trailing, 5)
        }.padding(2)
    }
}


