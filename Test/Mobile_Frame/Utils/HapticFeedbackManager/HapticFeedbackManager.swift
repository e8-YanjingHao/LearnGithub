//
//  HapticFeedbackManager.swift
//  MobileFrame
//
//  Created by ERIC on 2022/1/20.
//

import Foundation

struct HapticFeedbackManager {
    
    @available(iOS 10.0, *)
    static func executeSuccessFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @available(iOS 10.0, *)
    static func executeWarningFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    @available(iOS 10.0, *)
    static func excuteErrorFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    @available(iOS 10.0, *)
    static func excuteLightFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    @available(iOS 10.0, *)
    static func excuteMediumFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    @available(iOS 10.0, *)
    static func excuteHeavyFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    @available(iOS 13.0, *)
    static func excuteSoftFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    @available(iOS 13.0, *)
    static func excuteRigidFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    @available(iOS 10.0, *)
    static func excuteSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
