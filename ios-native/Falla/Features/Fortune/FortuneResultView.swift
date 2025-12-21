// FortuneResultView.swift
// Falla - iOS 26 Fortune Telling App
// Fortune result display with sharing and rating

import SwiftUI

// MARK: - Fortune Result View
struct FortuneResultMainView: View {
    let fortuneId: String
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var fortune: FortuneModel?
    @State private var isLoading = true
    @State private var isFavorite = false
    @State private var userRating: Int = 0
    @State private var showShareSheet = false
    @State private var animateContent = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                MysticalLoading(message: "Yükleniyor...")
            } else if let fortune = fortune {
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection(fortune)
                        
                        if !fortune.selectedCards.isEmpty {
                            cardsSection(fortune)
                        }
                        
                        interpretationSection(fortune)
                        ratingSection
                        actionsSection
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }
            } else {
                errorView
            }
        }
        .onAppear {
            loadFortune()
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
    
    // MARK: - Header Section
    private func headerSection(_ fortune: FortuneModel) -> some View {
        VStack(spacing: 16) {
            // Navigation bar
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
                
                Button(action: { isFavorite.toggle(); saveFavorite() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? .pink : .white.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 60)
            
            // Fortune type header
            GlassCard(cornerRadius: 24, padding: 24) {
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Text(fortune.type.emoji)
                            .font(.system(size: 40))
                    }
                    
                    Text(fortune.title ?? fortune.type.displayName)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    // Date
                    Text(formatDate(fortune.createdAt))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    // Karma used
                    KarmaBadge(fortune.karmaUsed ?? 0, size: .small)
                }
            }
        }
    }
    
    // MARK: - Cards Section (for Tarot)
    private func cardsSection(_ fortune: FortuneModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seçilen Kartlar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(fortune.selectedCards, id: \.self) { cardId in
                    VStack(spacing: 8) {
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
                            .frame(width: 70, height: 100)
                            .overlay {
                                Image(systemName: "sparkle")
                                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.5))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3), lineWidth: 1)
                            }
                        
                        Text(formatCardId(cardId))
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    
    private func formatCardId(_ id: String) -> String {
        id.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    // MARK: - Interpretation Section
    private func interpretationSection(_ fortune: FortuneModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yorum")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            GlassCard(cornerRadius: 20, padding: 20) {
                Text(fortune.interpretation)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
            }
            
            // Question if exists
            if let question = fortune.question, !question.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sorunuz")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(question)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Rating Section
    private var ratingSection: some View {
        GlassCard(cornerRadius: 16, padding: 16) {
            VStack(spacing: 12) {
                Text("Bu yorumu nasıl buldunuz?")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: { setRating(star) }) {
                            Image(systemName: star <= userRating ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundColor(star <= userRating ? .yellow : .white.opacity(0.3))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        HStack(spacing: 12) {
            // New fortune button
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Yeni Fal")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Home button
            Button(action: { dismiss() }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Fal bulunamadı")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Button("Geri Dön") { dismiss() }
                .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
        }
    }
    
    // MARK: - Methods
    private func loadFortune() {
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // In production, fetch from Firebase
            fortune = FortuneModel(
                id: fortuneId,
                userId: AuthManager.shared.currentUser?.uid ?? "",
                type: .tarot,
                status: .completed,
                title: "Tarot Falı",
                interpretation: """
                🔮 Genel Enerji
                
                Seçtiğiniz kartlar, hayatınızdaki önemli bir dönüşüm dönemine işaret ediyor. Evren size yeni kapılar açmak için hazırlanıyor.
                
                🌟 Geçmiş Etkiler
                
                Geçmişte yaşadığınız zorluklar, bugün kim olduğunuzun temelini oluşturdu. Bu deneyimler size değerli dersler öğretti.
                
                ⏰ Şimdiki Durum
                
                Şu an bir kavşak noktasındasınız. Önünüzde birden fazla yol var ve hangi yolu seçeceğiniz tamamen size bağlı.
                
                🌙 Gelecek Olasılıkları
                
                Yakın gelecekte beklenmedik bir fırsat kapınızı çalabilir. Açık fikirli olmak ve değişime hazır olmak önemli.
                
                💡 Tavsiye
                
                İçgüdülerinize güvenin. Kalbinizin sesini dinleyin ve cesaretli adımlar atmaktan korkmayın. Evren sizin yanınızda.
                """,
                selectedCards: ["the_fool", "lovers", "the_sun"],
                karmaUsed: 5
            )
            
            isLoading = false
            isFavorite = fortune?.isFavorite ?? false
            userRating = fortune?.rating ?? 0
            
            withAnimation(.easeOut(duration: 0.5)) {
                animateContent = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    private func saveFavorite() {
        // Save to Firebase
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func setRating(_ rating: Int) {
        withAnimation(.spring(response: 0.3)) {
            userRating = rating
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Save rating to Firebase
    }
}

// MARK: - Preview
#Preview {
    FortuneResultMainView(fortuneId: "test-fortune-id")
        .environmentObject(UserManager())
}
