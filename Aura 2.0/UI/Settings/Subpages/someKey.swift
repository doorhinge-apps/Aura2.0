//
// Aura 2.0
// someKey.swift
//
// Created on 6/21/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}
