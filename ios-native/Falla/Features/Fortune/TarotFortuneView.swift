// TarotFortuneView.swift
// Falla - iOS 26 Fortune Telling App
// Tarot card reading flow with Liquid Glass UI

import SwiftUI

// MARK: - Tarot Fortune View
/// Full tarot card reading experience with card selection and interpretation
@available(iOS 26.0, *)
struct TarotFortuneView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var currentStep: TarotStep = .intro
    @State private var selectedCards: [TarotCard] = []
    @State private var revealedCards: Set<Int> = []
    @State private var isInterpreting = false
    @State private var interpretation: TarotInterpretation?
    @State private var shuffleRotation: Double = 0
    @State private var cardOffsets: [CGFloat] = Array(repeating: 0, count: 78)
    
    private let requiredCardCount = 3
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground(style: .cosmic, enableParticles: true)
            
            // Content
            VStack(spacing: 0) {
                headerView
                stepContent
            }
            
            // Interpreting overlay
            if isInterpreting {
                interpretingOverlay
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button {
                if currentStep == .intro {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        goToPreviousStep()
                    }
                }
            } label: {
                Image(systemName: currentStep == .intro ? "xmark" : "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .glassEffect(.thin, in: Circle())
                    }
            }
            .buttonStyle(ElasticButtonStyle())
            
            Spacer()
            
            Text("Tarot Falı")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Card count
            if currentStep == .selection {
                HStack(spacing: 4) {
                    Text("\(selectedCards.count)/\(requiredCardCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FallaColors.tarotPurple)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(FallaColors.tarotPurple.opacity(0.2))
                }
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .intro:
            introStep
        case .shuffle:
            shuffleStep
        case .selection:
            selectionStep
        case .reveal:
            revealStep
        case .result:
            resultStep
        }
    }
    
    // MARK: - Intro Step
    private var introStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)
                
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    FallaColors.tarotPurple.opacity(0.4),
                                    FallaColors.tarotPurple.opacity(0.1),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: Circle())
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 50))
                        .foregroundColor(FallaColors.tarotPurple)
                }
                .pulsingGlow(color: FallaColors.tarotPurple)
                
                // Title
                VStack(spacing: 12) {
                    Text("Tarot Falı")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Kartların mesajını dinleyin")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Spread selection
                GlassCard(cornerRadius: 24, padding: 20) {
                    VStack(spacing: 16) {
                        Text("Açılım Türü")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            spreadOption(title: "3 Kartlık", subtitle: "Geçmiş, Şimdi, Gelecek", isSelected: true)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Karma cost
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("5 Karma")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FallaColors.champagneGold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(FallaColors.champagneGold.opacity(0.2))
                }
                
                // Start button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .shuffle
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Kartları Karıştır")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(FallaColors.tarotPurple)
                    }
                    .shadow(color: FallaColors.tarotPurple.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ElasticButtonStyle())
                .padding(.horizontal, 40)
                
                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private func spreadOption(title: String, subtitle: String, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? FallaColors.tarotPurple : .white)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? FallaColors.tarotPurple.opacity(0.2) : Color.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isSelected ? FallaColors.tarotPurple : Color.white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 1
                        )
                }
        }
    }
    
    // MARK: - Shuffle Step
    private var shuffleStep: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Shuffling cards animation
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    tarotCardBack
                        .rotationEffect(.degrees(shuffleRotation + Double(i * 15)))
                        .offset(y: CGFloat(i * -2))
                }
            }
            
            VStack(spacing: 12) {
                Text("Kartlar Karışıyor")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text("Bir niyetinizi düşünün...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Shuffle button
            Button {
                shuffleCards()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                    Text("Karıştır")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: Capsule())
                        .overlay {
                            Capsule()
                                .fill(FallaColors.tarotPurple.opacity(0.3))
                        }
                }
            }
            .buttonStyle(ElasticButtonStyle())
            
            Spacer()
        }
        .onAppear {
            autoShuffle()
        }
    }
    
    private var tarotCardBack: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        FallaColors.tarotPurple,
                        FallaColors.tarotPurple.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            }
            .overlay {
                Image(systemName: "sparkle")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(width: 80, height: 120)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func autoShuffle() {
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            shuffleRotation = 360
        }
        
        // Auto advance after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = .selection
            }
        }
    }
    
    private func shuffleCards() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            shuffleRotation += 180
        }
    }
    
    // MARK: - Selection Step
    private var selectionStep: some View {
        VStack(spacing: 24) {
            Text("3 Kart Seçin")
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Card fan
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -30) {
                    ForEach(TarotDeck.allCards.indices, id: \.self) { index in
                        selectableCard(at: index)
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(height: 200)
            
            // Selected cards preview
            if !selectedCards.isEmpty {
                HStack(spacing: 16) {
                    ForEach(0..<requiredCardCount, id: \.self) { index in
                        if index < selectedCards.count {
                            miniCardPreview(selectedCards[index])
                        } else {
                            emptyCardSlot
                        }
                    }
                }
            }
            
            Spacer()
            
            // Continue button
            if selectedCards.count == requiredCardCount {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .reveal
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Kartları Aç")
                        Image(systemName: "wand.and.stars")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(FallaColors.tarotPurple)
                    }
                    .shadow(color: FallaColors.tarotPurple.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ElasticButtonStyle())
                .padding(.horizontal, 40)
            }
            
            Spacer().frame(height: 40)
        }
    }
    
    private func selectableCard(at index: Int) -> some View {
        let card = TarotDeck.allCards[index]
        let isSelected = selectedCards.contains(where: { $0.id == card.id })
        
        return Button {
            toggleCardSelection(card)
        } label: {
            tarotCardBack
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .offset(y: isSelected ? -20 : 0)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(FallaColors.champagneGold, lineWidth: 2)
                    }
                }
        }
        .buttonStyle(ElasticButtonStyle())
        .disabled(selectedCards.count >= requiredCardCount && !isSelected)
        .opacity(selectedCards.count >= requiredCardCount && !isSelected ? 0.5 : 1)
    }
    
    private func miniCardPreview(_ card: TarotCard) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(FallaColors.tarotPurple)
                .overlay {
                    Image(systemName: "sparkle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(width: 50, height: 75)
            
            Text(card.name)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
    }
    
    private var emptyCardSlot: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundColor(.white.opacity(0.2))
                .frame(width: 50, height: 75)
            
            Text("?")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
        }
    }
    
    private func toggleCardSelection(_ card: TarotCard) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let index = selectedCards.firstIndex(where: { $0.id == card.id }) {
                selectedCards.remove(at: index)
            } else if selectedCards.count < requiredCardCount {
                selectedCards.append(card)
            }
        }
    }
    
    // MARK: - Reveal Step
    private var revealStep: some View {
        VStack(spacing: 24) {
            Text("Kartlarınız")
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Cards to reveal
            HStack(spacing: 16) {
                ForEach(Array(selectedCards.enumerated()), id: \.element.id) { index, card in
                    revealableCard(card: card, index: index)
                }
            }
            .padding(.horizontal, 20)
            
            // Labels
            HStack(spacing: 16) {
                ForEach(["Geçmiş", "Şimdi", "Gelecek"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            
            Text("Kartların üzerine dokunarak açın")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            // Interpret button
            if revealedCards.count == requiredCardCount {
                Button {
                    interpretCards()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Yorumla")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(FallaColors.tarotPurple)
                    }
                    .shadow(color: FallaColors.tarotPurple.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ElasticButtonStyle())
                .padding(.horizontal, 40)
            }
            
            Spacer().frame(height: 40)
        }
    }
    
    private func revealableCard(card: TarotCard, index: Int) -> some View {
        let isRevealed = revealedCards.contains(index)
        
        return Button {
            revealCard(at: index)
        } label: {
            ZStack {
                if isRevealed {
                    // Front of card
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.9, blue: 0.8),
                                    Color(red: 0.85, green: 0.8, blue: 0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: card.symbol)
                                    .font(.system(size: 40))
                                    .foregroundColor(FallaColors.tarotPurple)
                                
                                Text(card.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(FallaColors.champagneGold, lineWidth: 2)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .identity
                        ))
                } else {
                    // Back of card
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    FallaColors.tarotPurple,
                                    FallaColors.tarotPurple.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "sparkle")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ElasticButtonStyle())
        .disabled(isRevealed)
    }
    
    private func revealCard(at index: Int) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            revealedCards.insert(index)
        }
    }
    
    // MARK: - Result Step
    private var resultStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)
                
                Text("Yorumunuz")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                if let interp = interpretation {
                    ForEach(Array(zip(selectedCards.indices, selectedCards)), id: \.0) { index, card in
                        GlassCard(cornerRadius: 20, padding: 16, tintColor: FallaColors.tarotPurple) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: card.symbol)
                                        .font(.system(size: 24))
                                        .foregroundColor(FallaColors.tarotPurple)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(card.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text(index == 0 ? "Geçmiş" : index == 1 ? "Şimdi" : "Gelecek")
                                            .font(.system(size: 12))
                                            .foregroundColor(FallaColors.tarotPurple)
                                    }
                                }
                                
                                Divider().background(.white.opacity(0.1))
                                
                                Text(interp.cardMessages[index])
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Overall message
                    GlassCard(cornerRadius: 20, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(FallaColors.champagneGold)
                                Text("Genel Yorum")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(interp.overallMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Kaydet ve Kapat")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(FallaColors.tarotPurple)
                        }
                    }
                    .buttonStyle(ElasticButtonStyle())
                }
                .padding(.horizontal, 40)
                
                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Interpreting Overlay
    private var interpretingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(FallaColors.tarotPurple)
                
                VStack(spacing: 8) {
                    Text("Kartlar Yorumlanıyor")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Yapay zeka mesajınızı hazırlıyor...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Navigation
    private func goToPreviousStep() {
        switch currentStep {
        case .intro: break
        case .shuffle: currentStep = .intro
        case .selection: currentStep = .shuffle
        case .reveal: currentStep = .selection
        case .result: currentStep = .reveal
        }
    }
    
    // MARK: - Interpretation
    private func interpretCards() {
        isInterpreting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            interpretation = TarotInterpretation(
                cardMessages: [
                    "Bu kart geçmişte yaşadığınız zorlukların üstesinden geldiğinizi gösteriyor. Cesaretle ilerlemeyi başardınız.",
                    "Şuanki durumunuz değişim ve dönüşüm içeriyor. Bu süreçte sabırlı olmanız önemli.",
                    "Gelecekte parlak fırsatlar sizi bekliyor. Yeni başlangıçlara açık olun."
                ],
                overallMessage: "Kartlarınız genel olarak pozitif bir enerji taşıyor. Geçmişten aldığınız dersler sizi güçlendirdi ve şimdiki değişimler geleceğe hazırlıyor. Önünüzdeki dönemde cesur adımlar atmaktan çekinmeyin."
            )
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isInterpreting = false
                currentStep = .result
            }
        }
    }
}

// MARK: - Tarot Step
enum TarotStep {
    case intro
    case shuffle
    case selection
    case reveal
    case result
}

// MARK: - Tarot Card
struct TarotCard: Identifiable, Equatable {
    let id: String
    let name: String
    let symbol: String
}

// MARK: - Tarot Deck
enum TarotDeck {
    static let allCards: [TarotCard] = [
        TarotCard(id: "fool", name: "Deliler", symbol: "sun.max.fill"),
        TarotCard(id: "magician", name: "Büyücü", symbol: "wand.and.stars"),
        TarotCard(id: "priestess", name: "Rahibe", symbol: "moon.fill"),
        TarotCard(id: "empress", name: "İmparatoriçe", symbol: "crown.fill"),
        TarotCard(id: "emperor", name: "İmparator", symbol: "shield.fill"),
        TarotCard(id: "hierophant", name: "Aziz", symbol: "book.fill"),
        TarotCard(id: "lovers", name: "Aşıklar", symbol: "heart.fill"),
        TarotCard(id: "chariot", name: "Savaş Arabası", symbol: "car.fill"),
        TarotCard(id: "strength", name: "Güç", symbol: "figure.strengthtraining.traditional"),
        TarotCard(id: "hermit", name: "Münzevi", symbol: "flashlight.on.fill"),
        TarotCard(id: "wheel", name: "Kader Çarkı", symbol: "arrow.trianglehead.2.clockwise.rotate.90"),
        TarotCard(id: "justice", name: "Adalet", symbol: "scale.3d"),
        TarotCard(id: "hanged", name: "Asılan Adam", symbol: "person.fill.questionmark"),
        TarotCard(id: "death", name: "Ölüm", symbol: "leaf.fill"),
        TarotCard(id: "temperance", name: "Ölçülülük", symbol: "drop.fill"),
        TarotCard(id: "devil", name: "Şeytan", symbol: "flame.fill"),
        TarotCard(id: "tower", name: "Kule", symbol: "building.fill"),
        TarotCard(id: "star", name: "Yıldız", symbol: "star.fill"),
        TarotCard(id: "moon", name: "Ay", symbol: "moon.stars.fill"),
        TarotCard(id: "sun", name: "Güneş", symbol: "sun.max.fill"),
        TarotCard(id: "judgement", name: "Yargı", symbol: "horn.fill"),
        TarotCard(id: "world", name: "Dünya", symbol: "globe")
    ]
}

// MARK: - Tarot Interpretation
struct TarotInterpretation {
    let cardMessages: [String]
    let overallMessage: String
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Tarot Fortune") {
    TarotFortuneView()
        .environmentObject(AppCoordinator())
        .environmentObject(UserManager())
}
