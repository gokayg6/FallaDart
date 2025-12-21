// FortuneResultView.swift
// Falla - Wrapper for the main fortune result view

import SwiftUI

/// Wrapper that presents FortuneResultMainView with a fortune ID
struct FortuneResultView: View {
    let fortuneId: String
    
    var body: some View {
        FortuneResultMainView(fortuneId: fortuneId)
    }
}
