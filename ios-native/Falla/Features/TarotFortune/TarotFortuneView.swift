// TarotFortuneView.swift
// Falla - iOS 26 Fortune Telling App
// Tarot fortune reading with card selection and flip animations

import SwiftUI

// MARK: - Tarot Fortune View
struct TarotFortuneView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var currentStep = 0 // 0: Card Selection, 1: Info Form
    @State private var selectedCardIndices: [Int] = []
    @State private var revealedCards: [Int: Bool] = [:]
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var fortuneResult: FortuneModel?
    @State private var formData: [String: String] = [:]
    
    // MARK: - Animation State
    @State private var floatOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    @Namespace private var cardNamespace
    
    // MARK: - Constants
    private let karmaCost = 5
    private let requiredCards = 3
    
    // MARK: - Tarot Deck
    private let tarotDeck: [TarotCardData] = [
        TarotCardData(id: "the_fool", name: "Deli", emoji: "🃏"),
        TarotCardData(id: "magician", name: "Büyücü", emoji: "🎩"),
        TarotCardData(id: "high_priestess", name: "Başrahibe", emoji: "🌙"),
        TarotCardData(id: "empress", name: "İmparatoriçe", emoji: "👑"),
        TarotCardData(id: "emperor", name: "İmparator", emoji: "🦁"),
        TarotCardData(id: "hierophant", name: "Aziz", emoji: "⛪"),
        TarotCardData(id: "lovers", name: "Aşıklar", emoji: "💕"),
        TarotCardData(id: "chariot", name: "Savaş Arabası", emoji: "🏇"),
        TarotCardData(id: "strength", name: "Güç", emoji: "💪"),
        TarotCardData(id: "hermit", name: "Ermiş", emoji: "🏔️"),
        TarotCardData(id: "wheel_of_fortune", name: "Kader Çarkı", emoji: "🎡"),
        TarotCardData(id: "justice", name: "Adalet", emoji: "⚖️"),
        TarotCardData(id: "the_hanged_man", name: "Asılan Adam", emoji: "🙃"),
        TarotCardData(id: "death", name: "Ölüm", emoji: "💀"),
        TarotCardData(id: "temperance", name: "Denge", emoji: "☯️"),
        TarotCardData(id: "devil", name: "Şeytan", emoji: "😈"),
        TarotCardData(id: "the_tower", name: "Kule", emoji: "🗼"),
        TarotCardData(id: "the_star", name: "Yıldız", emoji: "⭐"),
        TarotCardData(id: "the_moon", name: "Ay", emoji: "🌛"),
        TarotCardData(id: "the_sun", name: "Güneş", emoji: "☀️"),
        TarotCardData(id: "judgement", name: "Mahkeme", emoji: "📯"),
        TarotCardData(id: "the_world", name: "Dünya", emoji: "🌍"),
    ]
    
    @State private var shuffledDeck: [TarotCardData] = []
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            floatingParticles
            
            VStack(spacing: 0) {
                headerView
                
                if currentStep == 0 {
                    cardSelectionStep
                } else {
                    infoFormStep
                }
                
                actionBar
            }
            
            if isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            shuffleDeck()
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
                Color(red: 0.08, green: 0.04, blue: 0.12),
                Color(red: 0.12, green: 0.06, blue: 0.18),
                Color(red: 0.06, green: 0.02, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var floatingParticles: some View {
        GeometryReader { geometry in
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                    .frame(width: CGFloat.random(in: 2...5))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .offset(y: floatOffset * CGFloat(index % 3 + 1) * 0.3)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                if currentStep > 0 {
                    withAnimation(.spring(response: 0.3)) {
                        currentStep -= 1
                    }
                } else {
                    dismiss()
                }
            }) {
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
                    Image(systemName: "suit.spade.fill")
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    Text("Tarot Falı")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Kartların Bilgeliği")
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
    
    // MARK: - Card Selection Step
    private var cardSelectionStep: some View {
        VStack(spacing: 16) {
            // Hero section
            heroSection
            
            // Selected cards slots
            selectedCardsSlots
            
            // Card grid
            ScrollView {
                cardGrid
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
    }
    
    private var heroSection: some View {
        Padding(horizontal: 16) {
            GlassCard(cornerRadius: 20, padding: 20) {
                HStack(spacing: 16) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                            .offset(y: floatOffset * 0.2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kartlarını Seç")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                        
                        Text("3 kart seç, sezgilerine güven. Kartlar seninle konuşacak.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .lineSpacing(2)
                    }
                }
            }
        }
    }
    
    private var selectedCardsSlots: some View {
        VStack(spacing: 8) {
            Text(selectedCardIndices.count == requiredCards ? "Kartlar Seçildi" : "\(requiredCards - selectedCardIndices.count) Kart Seçin")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
            
            HStack(spacing: 12) {
                ForEach(0..<requiredCards, id: \.self) { slotIndex in
                    cardSlot(at: slotIndex)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.2))
    }
    
    private func cardSlot(at index: Int) -> some View {
        let cardIndex = index < selectedCardIndices.count ? selectedCardIndices[index] : nil
        let width: CGFloat = 80
        let height: CGFloat = 120
        
        return ZStack {
            if let cardIndex = cardIndex {
                // Selected card
                selectedCardView(shuffledDeck[cardIndex], width: width, height: height)
                    .onTapGesture {
                        removeCard(at: index)
                    }
            } else {
                // Empty slot
                emptySlotView(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedCardIndices)
    }
    
    private func selectedCardView(_ card: TarotCardData, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.2),
                            Color(red: 0.1, green: 0.05, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 4) {
                Text(card.emoji)
                    .font(.system(size: 32))
                
                Text(card.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.5),
                    lineWidth: 2
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
    
    private func emptySlotView(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
                Color.white.opacity(0.3 * glowIntensity),
                style: StrokeStyle(lineWidth: 1, dash: [5])
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.3))
            }
    }
    
    private var cardGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
            spacing: 10
        ) {
            ForEach(Array(shuffledDeck.enumerated()), id: \.element.id) { index, card in
                cardGridItem(card, at: index)
            }
        }
    }
    
    private func cardGridItem(_ card: TarotCardData, at index: Int) -> some View {
        let isSelected = selectedCardIndices.contains(index)
        
        return Button(action: {
            selectCard(at: index)
        }) {
            ZStack {
                // Card back
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.1, blue: 0.3),
                                Color(red: 0.1, green: 0.05, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Pattern
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3))
            }
            .frame(height: 80)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        Color(red: 0.82, green: 0.71, blue: 0.55).opacity(isSelected ? 0 : 0.3),
                        lineWidth: 1
                    )
            }
            .opacity(isSelected ? 0.3 : 1.0)
            .scaleEffect(isSelected ? 0.95 : 1.0)
        }
        .disabled(isSelected || selectedCardIndices.count >= requiredCards)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    // MARK: - Info Form Step
    private var infoFormStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Selected cards display
                HStack(spacing: 12) {
                    ForEach(selectedCardIndices, id: \.self) { index in
                        selectedCardView(shuffledDeck[index], width: 60, height: 90)
                    }
                }
                .padding(.vertical, 16)
                
                // Form fields
                GlassCard(cornerRadius: 20, padding: 20) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Ek Bilgiler (İsteğe Bağlı)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        formField(title: "Adınız", key: "name", placeholder: "İsminizi girin")
                        formField(title: "İlişki Durumu", key: "relationshipStatus", placeholder: "Örn: Bekar, Evli...")
                        formField(title: "Meslek", key: "jobStatus", placeholder: "Mesleğiniz nedir?")
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    private func formField(title: String, key: String, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            TextField(placeholder, text: Binding(
                get: { formData[key] ?? "" },
                set: { formData[key] = $0 }
            ))
            .textFieldStyle(.plain)
            .foregroundColor(.white)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                if currentStep == 0 {
                    Text("\(selectedCardIndices.count)/\(requiredCards) kart seçildi")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("Hazırsanız falınızı oluşturun")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if currentStep == 0 {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            currentStep = 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Devam Et")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            selectedCardIndices.count == requiredCards
                                ? LinearGradient(
                                    colors: [
                                        Color(red: 0.82, green: 0.71, blue: 0.55),
                                        Color(red: 0.7, green: 0.55, blue: 0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                    }
                    .disabled(selectedCardIndices.count != requiredCards)
                } else {
                    Button(action: generateFortune) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Falımı Gör")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.82, green: 0.71, blue: 0.55),
                                    Color(red: 0.7, green: 0.55, blue: 0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                }
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
            
            MysticalLoading(message: "Kartlar yorumlanıyor...")
        }
    }
    
    // MARK: - Methods
    private func shuffleDeck() {
        shuffledDeck = tarotDeck.shuffled()
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            floatOffset = 10
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.8
        }
    }
    
    private func selectCard(at index: Int) {
        guard selectedCardIndices.count < requiredCards else { return }
        guard !selectedCardIndices.contains(index) else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedCardIndices.append(index)
        }
    }
    
    private func removeCard(at slotIndex: Int) {
        guard slotIndex < selectedCardIndices.count else { return }
        
        withAnimation(.spring(response: 0.3)) {
            selectedCardIndices.remove(at: slotIndex)
        }
    }
    
    private func generateFortune() {
        guard selectedCardIndices.count == requiredCards else { return }
        guard userManager.karma >= karmaCost else {
            errorMessage = "Yetersiz karma. Gerekli: \(karmaCost)"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                await userManager.updateKarma(-karmaCost)
                
                // Get selected card IDs
                let selectedCards = selectedCardIndices.map { shuffledDeck[$0] }
                let cardIds = selectedCards.map { $0.id }
                let cardNames = selectedCards.map { $0.name }
                
                // Simulate API call
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                let fortune = FortuneModel(
                    id: UUID().uuidString,
                    userId: AuthManager.shared.currentUser?.uid ?? "",
                    type: .tarot,
                    status: .completed,
                    title: "Tarot Falı",
                    interpretation: "AI interpretation for cards: \(cardNames.joined(separator: ", "))",
                    selectedCards: cardIds,
                    karmaUsed: karmaCost
                )
                
                await MainActor.run {
                    isLoading = false
                    fortuneResult = fortune
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Fal oluşturulurken hata: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Tarot Card Data
private struct TarotCardData: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
}

// MARK: - Padding Helper
private struct Padding<Content: View>: View {
    let horizontal: CGFloat
    let content: Content
    
    init(horizontal: CGFloat, @ViewBuilder content: () -> Content) {
        self.horizontal = horizontal
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, horizontal)
    }
}

// MARK: - Preview
#Preview {
    TarotFortuneView()
        .environmentObject(AppCoordinator())
        .environmentObject(UserManager())
}
