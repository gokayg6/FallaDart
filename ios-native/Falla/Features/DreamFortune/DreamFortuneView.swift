// DreamFortuneView.swift
// Falla - iOS 26 Fortune Telling App
// Dream interpretation with text input and AI analysis

import SwiftUI

// MARK: - Dream Fortune View
struct DreamFortuneView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var dreamDescription: String = ""
    @State private var selectedMood: DreamMood = .neutral
    @State private var selectedSymbols: Set<String> = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var fortuneResult: FortuneModel?
    
    // MARK: - Animation
    @State private var floatOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    @State private var starOpacity: Double = 0.5
    
    private let karmaCost = 6
    private let maxCharacters = 500
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            starsOverlay
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        dreamInputSection
                        moodSection
                        symbolsSection
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                actionBar
            }
            
            if isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            startAnimations()
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(item: $fortuneResult) { fortune in
            FortuneResultView(fortuneId: fortune.id)
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.02, blue: 0.12),
                Color(red: 0.08, green: 0.04, blue: 0.18),
                Color(red: 0.04, green: 0.02, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var starsOverlay: some View {
        GeometryReader { geometry in
            ForEach(0..<25, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(starOpacity * Double.random(in: 0.3...1.0)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text("🌙")
                        .font(.system(size: 22))
                    Text("Rüya Yorumu")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Bilinçaltınızın Mesajları")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            KarmaBadge(karmaCost, size: .medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        GlassCard(cornerRadius: 24, padding: 24) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                        .opacity(glowIntensity)
                    
                    Text("🌙")
                        .font(.system(size: 50))
                        .offset(y: floatOffset * 0.3)
                }
                
                Text("Rüyanızı Anlatın")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color.purple.opacity(0.9))
                
                Text("Gördüğünüz rüyayı detaylı şekilde yazın. Yapay zeka destekli rüya yorumunuzu alın.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Dream Input Section
    private var dreamInputSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundColor(Color.purple.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Rüyanız")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(dreamDescription.count)/\(maxCharacters)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                TextEditor(text: $dreamDescription)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .onChange(of: dreamDescription) { oldValue, newValue in
                        if newValue.count > maxCharacters {
                            dreamDescription = String(newValue.prefix(maxCharacters))
                        }
                    }
                
                Text("En az 20 karakter yazın")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
    
    // MARK: - Mood Section
    private var moodSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rüyadaki Ruh Haliniz")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(DreamMood.allCases, id: \.self) { mood in
                        moodButton(mood)
                    }
                }
            }
        }
    }
    
    private func moodButton(_ mood: DreamMood) -> some View {
        let isSelected = selectedMood == mood
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedMood = mood
            }
        }) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                
                Text(mood.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.05))
                    .strokeBorder(
                        isSelected ? Color.purple.opacity(0.6) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
    
    // MARK: - Symbols Section
    private var symbolsSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rüyada Gördüğünüz Semboller (İsteğe Bağlı)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                FlowLayout(spacing: 8) {
                    ForEach(dreamSymbols, id: \.self) { symbol in
                        symbolChip(symbol)
                    }
                }
            }
        }
    }
    
    private func symbolChip(_ symbol: String) -> some View {
        let isSelected = selectedSymbols.contains(symbol)
        
        return Button(action: {
            withAnimation(.spring(response: 0.2)) {
                if isSelected {
                    selectedSymbols.remove(symbol)
                } else {
                    selectedSymbols.insert(symbol)
                }
            }
        }) {
            Text(symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple.opacity(0.4) : Color.white.opacity(0.08))
                        .strokeBorder(
                            isSelected ? Color.purple.opacity(0.6) : Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        }
    }
    
    private var dreamSymbols: [String] {
        ["Su", "Uçmak", "Düşmek", "Koşmak", "Yılan", "Ev", "Araba", "Ölüm", "Evlilik", "Para", "Bebek", "Hayvan", "Yangın", "Deniz", "Dağ", "Orman"]
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if dreamDescription.count < 20 {
                        Text("\(20 - dreamDescription.count) karakter daha yazın")
                            .font(.system(size: 13))
                            .foregroundColor(.orange.opacity(0.8))
                    } else {
                        Text("Rüyanız hazır")
                            .font(.system(size: 13))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Button(action: generateFortune) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Yorumla")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        dreamDescription.count >= 20
                            ? LinearGradient(
                                colors: [Color.purple.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                }
                .disabled(dreamDescription.count < 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            MysticalLoading(message: "Rüyanız yorumlanıyor...")
        }
    }
    
    // MARK: - Methods
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatOffset = 10
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.6
        }
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            starOpacity = 0.8
        }
    }
    
    private func generateFortune() {
        guard dreamDescription.count >= 20 else { return }
        guard userManager.karma >= karmaCost else {
            errorMessage = "Yetersiz karma. Gerekli: \(karmaCost)"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                await userManager.updateKarma(-karmaCost)
                
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                let fortune = FortuneModel(
                    id: UUID().uuidString,
                    userId: AuthManager.shared.currentUser?.uid ?? "",
                    type: .dream,
                    status: .completed,
                    title: "Rüya Yorumu",
                    interpretation: "AI dream interpretation...",
                    question: dreamDescription,
                    karmaUsed: karmaCost,
                    metadata: [
                        "mood": selectedMood.rawValue,
                        "symbols": Array(selectedSymbols)
                    ]
                )
                
                await MainActor.run {
                    isLoading = false
                    fortuneResult = fortune
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Hata: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Dream Mood
enum DreamMood: String, CaseIterable {
    case happy = "happy"
    case scared = "scared"
    case sad = "sad"
    case confused = "confused"
    case neutral = "neutral"
    case excited = "excited"
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .scared: return "😨"
        case .sad: return "😢"
        case .confused: return "😕"
        case .neutral: return "😐"
        case .excited: return "🤩"
        }
    }
    
    var title: String {
        switch self {
        case .happy: return "Mutlu"
        case .scared: return "Korkmuş"
        case .sad: return "Üzgün"
        case .confused: return "Karışık"
        case .neutral: return "Nötr"
        case .excited: return "Heyecanlı"
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Preview
#Preview {
    DreamFortuneView()
        .environmentObject(UserManager())
}
