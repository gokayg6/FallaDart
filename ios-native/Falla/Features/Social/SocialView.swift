// SocialView.swift
// Falla - iOS 26 Fortune Telling App
// Social matching and chat screen with Liquid Glass

import SwiftUI

// MARK: - Social View
/// Social screen for aura matching and chat
@available(iOS 26.0, *)
struct SocialView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var selectedTab: SocialTab = .matches
    @State private var matches: [AuraMatch] = []
    @State private var isLoading = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                    .staggeredAnimation(index: 0)
                
                // Tab selector
                tabSelector
                    .staggeredAnimation(index: 1)
                
                // Content based on selected tab
                switch selectedTab {
                case .matches:
                    matchesSection
                case .chats:
                    chatsSection
                case .discover:
                    discoverSection
                }
                
                // Bottom padding for nav bar
                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            loadMatches()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sosyal")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(.white)
            
            Text("Aura eşleşmeleri ve sohbetler")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 60)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SocialTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                        }
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                        
                        // Indicator
                        Rectangle()
                            .fill(selectedTab == tab ? FallaColors.champagneGold : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Matches Section
    private var matchesSection: some View {
        VStack(spacing: 16) {
            // Free matches remaining
            freeMatchesCard
                .staggeredAnimation(index: 2)
            
            // Find match button
            findMatchButton
                .staggeredAnimation(index: 3)
            
            // Recent matches
            if !matches.isEmpty {
                recentMatchesSection
            } else {
                emptyMatchesView
                    .staggeredAnimation(index: 4)
            }
        }
    }
    
    private var freeMatchesCard: some View {
        GlassCard(cornerRadius: 20, padding: 16, tintColor: FallaColors.champagneGold) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Haftalık Ücretsiz Eşleşme")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(userManager.currentUser?.freeAuraMatches ?? 3)")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .foregroundColor(FallaColors.champagneGold)
                        
                        Text("/ 3 kaldı")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Rings indicator
                ZStack {
                    Circle()
                        .stroke(FallaColors.champagneGold.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(userManager.currentUser?.freeAuraMatches ?? 3) / 3.0)
                        .stroke(FallaColors.champagneGold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(FallaColors.champagneGold)
                }
            }
        }
    }
    
    private var findMatchButton: some View {
        Button {
            coordinator.presentFullScreen(.soulmateAnalysis)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    FallaColors.emotionalRed.opacity(0.5),
                                    FallaColors.emotionalRed.opacity(0.2),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(FallaColors.emotionalRed)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aura Eşleşmesi Bul")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Ruh eşinizi keşfedin")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(FallaColors.emotionalRed.opacity(0.1))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        FallaColors.emotionalRed.opacity(0.4),
                                        FallaColors.emotionalRed.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(ElasticButtonStyle(scale: 0.98))
    }
    
    private var recentMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son Eşleşmeler")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                matchRow(match: match)
                    .staggeredAnimation(index: 5 + index, baseDelay: 0.03)
            }
        }
    }
    
    private func matchRow(match: AuraMatch) -> some View {
        Button {
            coordinator.presentSheet(.chatDetail(matchId: match.id))
        } label: {
            HStack(spacing: 14) {
                // Avatar with compatibility ring
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    FallaColors.emotionalRed,
                                    FallaColors.champagneGold,
                                    FallaColors.emotionalRed
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.thin, in: Circle())
                        .frame(width: 50, height: 50)
                    
                    Text(String(match.name.prefix(1)))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(match.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        if match.isOnline {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(FallaColors.emotionalRed)
                        
                        Text("%\(match.compatibilityScore) uyum")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text(match.zodiac)
                            .font(.system(size: 12))
                            .foregroundColor(FallaColors.champagneGold)
                    }
                }
                
                Spacer()
                
                // Last message time
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.lastMessageTime)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    
                    if match.unreadCount > 0 {
                        Text("\(match.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FallaColors.emotionalRed)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .buttonStyle(ElasticButtonStyle())
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: Circle())
                    .frame(width: 80, height: 80)
                
                Image(systemName: "heart.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text("Henüz eşleşme yok")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Aura eşleşmesi yaparak yeni insanlarla tanışın")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Chats Section
    private var chatsSection: some View {
        VStack(spacing: 16) {
            if matches.filter({ $0.hasChat }).isEmpty {
                emptyChatView
            } else {
                ForEach(matches.filter { $0.hasChat }) { match in
                    chatRow(match: match)
                }
            }
        }
    }
    
    private func chatRow(match: AuraMatch) -> some View {
        Button {
            coordinator.presentSheet(.chatDetail(matchId: match.id))
        } label: {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.thin, in: Circle())
                        .frame(width: 50, height: 50)
                    
                    Text(String(match.name.prefix(1)))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    if match.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .strokeBorder(.black.opacity(0.2), lineWidth: 2)
                            }
                            .offset(x: 18, y: 18)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(match.lastMessage ?? "Sohbete başlayın")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.lastMessageTime)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    
                    if match.unreadCount > 0 {
                        Text("\(match.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FallaColors.emotionalRed)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .buttonStyle(ElasticButtonStyle())
    }
    
    private var emptyChatView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: Circle())
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text("Sohbet yok")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Eşleşmelerinizle sohbete başlayın")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Discover Section
    private var discoverSection: some View {
        VStack(spacing: 16) {
            Text("Keşfet özelliği yakında!")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
        }
    }
    
    // MARK: - Data Loading
    private func loadMatches() {
        isLoading = true
        
        // Simulated data - in production this would come from Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            matches = [
                AuraMatch(
                    id: "1",
                    name: "Ayşe",
                    zodiac: "Terazi",
                    compatibilityScore: 87,
                    isOnline: true,
                    lastMessage: "Merhaba! Nasılsın?",
                    lastMessageTime: "14:32",
                    unreadCount: 2,
                    hasChat: true
                ),
                AuraMatch(
                    id: "2",
                    name: "Mehmet",
                    zodiac: "Aslan",
                    compatibilityScore: 72,
                    isOnline: false,
                    lastMessage: nil,
                    lastMessageTime: "Dün",
                    unreadCount: 0,
                    hasChat: false
                )
            ]
            isLoading = false
        }
    }
}

// MARK: - Social Tab
enum SocialTab: String, CaseIterable {
    case matches
    case chats
    case discover
    
    var title: String {
        switch self {
        case .matches: return "Eşleşmeler"
        case .chats: return "Sohbetler"
        case .discover: return "Keşfet"
        }
    }
    
    var icon: String {
        switch self {
        case .matches: return "heart.circle"
        case .chats: return "bubble.left.and.bubble.right"
        case .discover: return "sparkle.magnifyingglass"
        }
    }
}

// MARK: - Aura Match Model
struct AuraMatch: Identifiable {
    let id: String
    let name: String
    let zodiac: String
    let compatibilityScore: Int
    let isOnline: Bool
    let lastMessage: String?
    let lastMessageTime: String
    let unreadCount: Int
    let hasChat: Bool
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Social View") {
    ZStack {
        AnimatedBackground(style: .mystical)
        SocialView()
    }
    .environmentObject(AppCoordinator())
    .environmentObject(UserManager())
}
