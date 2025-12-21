// HistoryView.swift
// Falla - iOS 26 Fortune Telling App
// Fortune history screen with filter chips and glass list rows

import SwiftUI

// MARK: - History View
/// Fortune history display with filtering and category color coding
@available(iOS 26.0, *)
struct HistoryView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var fortuneManager: FortuneManager
    
    // MARK: - State
    @State private var selectedFilter: HistoryFilter = .all
    @State private var sortOrder: SortOrder = .newest
    @State private var searchText = ""
    @State private var showOnlyFavorites = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Filter chips
                filterChipsSection
                
                // History list
                historyListSection
                
                // Bottom padding for nav bar
                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                await fortuneManager.loadFortunes()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fal Geçmişi")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text("\(filteredFortunes.count) kayıt")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Sort button
            Menu {
                Button {
                    withAnimation { sortOrder = .newest }
                } label: {
                    Label("En Yeni", systemImage: sortOrder == .newest ? "checkmark" : "")
                }
                
                Button {
                    withAnimation { sortOrder = .oldest }
                } label: {
                    Label("En Eski", systemImage: sortOrder == .oldest ? "checkmark" : "")
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(10)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .glassEffect(.thin, in: Circle())
                    }
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Filter Chips Section
    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All filter
                GlassFilterChip(
                    title: "Tümü",
                    icon: selectedFilter == .all ? "checkmark" : nil,
                    isSelected: selectedFilter == .all,
                    accentColor: FallaColors.champagneGold
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = .all
                    }
                }
                
                // Fortune type filters
                ForEach(HistoryFilter.fortuneFilters, id: \.self) { filter in
                    GlassFilterChip(
                        title: filter.title,
                        icon: selectedFilter == filter ? "checkmark" : nil,
                        isSelected: selectedFilter == filter,
                        accentColor: filter.accentColor
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
                
                // Divider
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 24)
                
                // Favorites filter
                GlassFilterChip(
                    title: "Favoriler",
                    icon: showOnlyFavorites ? "heart.fill" : "heart",
                    isSelected: showOnlyFavorites,
                    accentColor: FallaColors.emotionalRed
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showOnlyFavorites.toggle()
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - History List Section
    private var historyListSection: some View {
        LazyVStack(spacing: 12) {
            if filteredFortunes.isEmpty {
                emptyStateView
            } else {
                ForEach(Array(filteredFortunes.enumerated()), id: \.element.id) { index, fortune in
                    GlassHistoryRow(
                        icon: fortune.type.iconName,
                        title: fortune.type.displayName,
                        subtitle: fortune.title.isEmpty ? "Genel yorum" : fortune.title,
                        timestamp: formatTimestamp(fortune.createdAt),
                        accentColor: fortune.type.accentColor,
                        isFavorite: fortune.isFavorite
                    ) {
                        coordinator.presentSheet(.fortuneDetail(fortuneId: fortune.id))
                    }
                    .staggeredAnimation(index: index, baseDelay: 0.03)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: Circle())
                    .frame(width: 80, height: 80)
                
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text("Henüz fal geçmişiniz yok")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("İlk falınızı baktırın ve burada görün")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            Button {
                coordinator.switchTab(to: .home)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Fal Baktır")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: Capsule())
                        .overlay {
                            Capsule()
                                .fill(FallaColors.champagneGold.opacity(0.2))
                        }
                }
            }
            .buttonStyle(ElasticButtonStyle())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Computed Properties
    
    private var filteredFortunes: [FortuneModel] {
        var result = fortuneManager.fortunes
        
        // Apply type filter
        if selectedFilter != .all {
            result = result.filter { $0.type == selectedFilter.fortuneType }
        }
        
        // Apply favorites filter
        if showOnlyFavorites {
            result = result.filter { $0.isFavorite }
        }
        
        // Apply sort
        switch sortOrder {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt < $1.createdAt }
        }
        
        return result
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Bugün"
        } else if calendar.isDateInYesterday(date) {
            return "Dün"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            
            if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
                formatter.dateFormat = "EEEE"
            } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
                formatter.dateFormat = "d MMM"
            } else {
                formatter.dateFormat = "d MMM yyyy"
            }
            
            return formatter.string(from: date)
        }
    }
}

// MARK: - History Filter
@available(iOS 26.0, *)
enum HistoryFilter: Hashable {
    case all
    case coffee
    case tarot
    case palm
    case katina
    case dream
    case astrology
    
    var title: String {
        switch self {
        case .all: return "Tümü"
        case .coffee: return "Kahve Falı"
        case .tarot: return "Tarot"
        case .palm: return "El Falı"
        case .katina: return "Katina"
        case .dream: return "Rüya"
        case .astrology: return "Astroloji"
        }
    }
    
    var fortuneType: FortuneType? {
        switch self {
        case .all: return nil
        case .coffee: return .coffee
        case .tarot: return .tarot
        case .palm: return .palm
        case .katina: return .katina
        case .dream: return .dream
        case .astrology: return .astrology
        }
    }
    
    var accentColor: Color {
        switch self {
        case .all: return FallaColors.champagneGold
        case .coffee: return FallaColors.coffeeOrange
        case .tarot: return FallaColors.tarotPurple
        case .palm: return FallaColors.palmPink
        case .katina: return FallaColors.dreamBlue
        case .dream: return FallaColors.dreamBlue
        case .astrology: return FallaColors.astrologyYellow
        }
    }
    
    static var fortuneFilters: [HistoryFilter] {
        [.coffee, .tarot, .palm, .katina, .dream, .astrology]
    }
}

// MARK: - Sort Order
enum SortOrder {
    case newest
    case oldest
}

// MARK: - Fortune Type Extension
@available(iOS 26.0, *)
extension FortuneType {
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

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("History View") {
    ZStack {
        AnimatedBackground(style: .mystical)
        HistoryView()
    }
    .environmentObject(AppCoordinator())
    .environmentObject(FortuneManager())
}

// MARK: - Mock Data Preview
@available(iOS 26.0, *)
#Preview("History View with Data") {
    struct PreviewWrapper: View {
        @StateObject private var fortuneManager = FortuneManager()
        
        var body: some View {
            ZStack {
                AnimatedBackground(style: .mystical)
                HistoryView()
            }
            .environmentObject(AppCoordinator())
            .environmentObject(fortuneManager)
            .onAppear {
                // Add mock data
                // In real app, this would come from Firebase
            }
        }
    }
    
    return PreviewWrapper()
}
