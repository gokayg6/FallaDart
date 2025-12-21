// HomeView.swift
// Falla - iOS 26 Fortune Telling App
// Home screen with fortune type grid and daily fortune using Liquid Glass

import SwiftUI

// MARK: - Home View
/// Main home screen with fortune selection grid and karma display
@available(iOS 26.0, *)
struct HomeView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var showDailyFortune = false
    @State private var contentAppeared = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with greeting
                headerView
                    .staggeredAnimation(index: 0)
                
                // Karma card
                karmaCard
                    .staggeredAnimation(index: 1)
                
                // Daily Fortune Card
                dailyFortuneCard
                    .staggeredAnimation(index: 2)
                
                // Biorhythm Quick View
                biorhythmQuickView
                    .staggeredAnimation(index: 3)
                
                // Fortune Types Section
                fortuneTypesSection
                
                // Bottom padding for nav bar
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            contentAppeared = true
            Task {
                await userManager.refreshUser()
            }
        }
        .sheet(isPresented: $showDailyFortune) {
            DailyFortuneSheet()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(authManager.userProfile?.name ?? "Kullanıcı")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Profile avatar button
            Button {
                coordinator.switchTab(to: .profile)
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: Circle())
                        .frame(width: 48, height: 48)
                    
                    if let avatarURL = authManager.userProfile?.avatarURL,
                       let url = URL(string: avatarURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .buttonStyle(ElasticButtonStyle())
        }
        .padding(.top, 60)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın"
        case 12..<18: return "İyi günler"
        case 18..<22: return "İyi akşamlar"
        default: return "İyi geceler"
        }
    }
    
    // MARK: - Karma Card
    private var karmaCard: some View {
        GlassCard(cornerRadius: 20, padding: 16, tintColor: FallaColors.champagneGold) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Karma Puanınız")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(userManager.karma)")
                            .font(.system(size: 36, weight: .light, design: .rounded))
                            .foregroundColor(FallaColors.champagneGold)
                            .contentTransition(.numericText())
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(FallaColors.champagneGold)
                    }
                }
                
                Spacer()
                
                // Spin wheel button
                Button {
                    coordinator.presentSheet(.spinWheel)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        Text("Çark")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .glassEffect(.thin, in: Capsule())
                            .overlay {
                                Capsule()
                                    .fill(FallaColors.champagneGold.opacity(0.2))
                            }
                    }
                }
                .buttonStyle(ElasticButtonStyle())
            }
        }
    }
    
    // MARK: - Daily Fortune Card
    private var dailyFortuneCard: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showDailyFortune = true
        } label: {
            GlassCard(cornerRadius: 24, padding: 20, tintColor: FallaColors.champagneGold) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Günlük Burç Yorumu")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if let zodiac = authManager.userProfile?.zodiacSign {
                                Text(zodiac)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(FallaColors.champagneGold)
                            }
                        }
                        
                        Spacer()
                        
                        // Zodiac symbol with glow
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            FallaColors.champagneGold.opacity(0.3),
                                            FallaColors.champagneGold.opacity(0.1),
                                            .clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 40
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .fill(.ultraThinMaterial)
                                .glassEffect(.regular, in: Circle())
                                .overlay {
                                    Circle()
                                        .fill(FallaColors.champagneGold.opacity(0.15))
                                }
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 26))
                                .foregroundColor(FallaColors.champagneGold)
                        }
                        .pulsingGlow(color: FallaColors.champagneGold, minOpacity: 0.1, maxOpacity: 0.3)
                    }
                    
                    // Call to action
                    HStack {
                        Text("Bugünkü mesajınızı görüntüleyin")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            // Champagne gold accent border
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                FallaColors.champagneGold.opacity(0.5),
                                FallaColors.champagneGold.opacity(0.2),
                                FallaColors.champagneGold.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(ElasticButtonStyle(scale: 0.98))
    }
    
    // MARK: - Biorhythm Quick View
    private var biorhythmQuickView: some View {
        Button {
            coordinator.presentSheet(.biorhythm)
        } label: {
            GlassCard(cornerRadius: 20, padding: 16) {
                HStack(spacing: 16) {
                    // Mini progress rings
                    HStack(spacing: 12) {
                        miniProgressRing(value: 0.72, color: FallaColors.physicalBlue, label: "F")
                        miniProgressRing(value: 0.45, color: FallaColors.emotionalRed, label: "D")
                        miniProgressRing(value: 0.88, color: FallaColors.mentalYellow, label: "Z")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biyoritm")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Günlük enerji durumunuz")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .buttonStyle(ElasticButtonStyle(scale: 0.98))
    }
    
    private func miniProgressRing(value: Double, color: Color, label: String) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: 32, height: 32)
    }
    
    // MARK: - Fortune Types Section
    private var fortuneTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fal Türleri")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(FortuneType.allCases.filter { $0 != .daily }.enumerated()), id: \.element) { index, type in
                    GlassGridItem(
                        icon: type.iconName,
                        title: type.displayName,
                        subtitle: nil,
                        accentColor: type.accentColor,
                        karmaCost: type.karmaCost
                    ) {
                        openFortune(type)
                    }
                    .staggeredAnimation(index: 4 + index, baseDelay: 0.03)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func openFortune(_ type: FortuneType) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        switch type {
        case .coffee:
            coordinator.presentFullScreen(.coffeeFortune)
        case .tarot:
            coordinator.presentFullScreen(.tarotFortune)
        case .palm:
            coordinator.presentFullScreen(.palmFortune)
        case .katina:
            coordinator.presentFullScreen(.katinaFortune)
        case .face:
            coordinator.presentFullScreen(.faceFortune)
        case .astrology:
            coordinator.presentFullScreen(.astrologyFortune)
        case .dream:
            coordinator.presentFullScreen(.dreamInterpretation)
        case .daily:
            showDailyFortune = true
        }
    }
}

// MARK: - Fortune Type Extension
@available(iOS 26.0, *)
extension FortuneType {
    /// Accent color for each fortune type
    var accentColor: Color {
        switch self {
        case .coffee: return FallaColors.coffeeOrange
        case .tarot: return FallaColors.tarotPurple
        case .palm: return FallaColors.palmPink
        case .katina: return FallaColors.dreamBlue
        case .face: return FallaColors.faceGreen
        case .astrology: return FallaColors.astrologyYellow
        case .dream: return FallaColors.dreamBlue
        case .daily: return FallaColors.champagneGold
        }
    }
    
    /// SF Symbol name for each fortune type
    var iconName: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .tarot: return "rectangle.stack.fill"
        case .palm: return "hand.raised.fill"
        case .katina: return "sparkle.magnifyingglass"
        case .face: return "face.smiling"
        case .astrology: return "moon.stars.fill"
        case .dream: return "moon.zzz.fill"
        case .daily: return "sun.max.fill"
        }
    }
}

// MARK: - Daily Fortune Sheet
@available(iOS 26.0, *)
struct DailyFortuneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var fortuneText: String = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(style: .mystical, enableParticles: false)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Zodiac header
                        zodiacHeader
                        
                        // Fortune content
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                                .padding(.vertical, 40)
                        } else {
                            fortuneContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(FallaColors.champagneGold)
                }
            }
        }
        .presentationBackground(.clear)
        .onAppear {
            loadDailyFortune()
        }
    }
    
    private var zodiacHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FallaColors.champagneGold.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: Circle())
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 36))
                    .foregroundColor(FallaColors.champagneGold)
            }
            .pulsingGlow(color: FallaColors.champagneGold)
            
            VStack(spacing: 4) {
                Text(authManager.userProfile?.zodiacSign ?? "Burç")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text(formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private var fortuneContent: some View {
        GlassCard(cornerRadius: 24, padding: 20) {
            Text(fortuneText)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private func loadDailyFortune() {
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                fortuneText = """
                Bugün yıldızlar sizin için parlıyor! Yaratıcı enerjiniz yüksek ve yeni fırsatlar kapınızı çalabilir. İş hayatınızda beklenmedik gelişmeler sizi mutlu edebilir.
                
                Aşk hayatınızda romantik sürprizlere açık olun. Sevdiklerinizle geçireceğiniz zaman size huzur verecek.
                
                Sağlığınıza dikkat etmeniz gereken bir gün. Bol su için ve dinlenmeye zaman ayırın.
                
                Şanslı sayınız: 7
                Şanslı renginiz: Mor
                """
                isLoading = false
            }
        }
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Home View") {
    ZStack {
        AnimatedBackground(style: .mystical)
        HomeView()
    }
    .environmentObject(AppCoordinator())
    .environmentObject(AuthManager.shared)
    .environmentObject(UserManager())
}
