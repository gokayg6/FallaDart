// DiscoverView.swift
// Falla - iOS 26 Fortune Telling App
// Discover screen with fortune categories and featured content

import SwiftUI

// MARK: - Discover View
struct DiscoverMainView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var searchText = ""
    @State private var animateGlow = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Search bar
                searchBar
                
                // Featured fortune
                featuredSection
                
                // Fortune categories
                categoriesSection
                
                // Daily horoscope
                dailyHoroscopeSection
                
                // Tests section
                testsSection
                
                Spacer()
                    .frame(height: 150)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Keşfet")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text("Gizemli dünyayı keşfet")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Karma display
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                
                Text("\(userManager.karma)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.top, 60)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
            
            TextField("Fal ara...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        GlassCard(cornerRadius: 20, padding: 0) {
            ZStack(alignment: .bottomLeading) {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.4),
                        Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 180)
                
                // Glow effect
                Circle()
                    .fill(Color.purple.opacity(animateGlow ? 0.3 : 0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: 100, y: -50)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("⭐ ÖNE ÇIKAN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    
                    Text("Tarot Falı")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Kartların size ne söylemek istediğini keşfedin")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button(action: {
                        coordinator.presentSheet(.tarotFortuneInput)
                    }) {
                        Text("Başla")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.82, green: 0.71, blue: 0.55))
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fal Türleri")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(fortuneCategories, id: \.title) { category in
                    categoryCard(category)
                }
            }
        }
    }
    
    private func categoryCard(_ category: FortuneCategory) -> some View {
        Button(action: category.action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(category.emoji)
                        .font(.system(size: 28))
                    
                    Spacer()
                    
                    if category.isNew {
                        Text("YENİ")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }
                
                Text(category.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(category.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                
                HStack {
                    KarmaBadge(category.karma, size: .small)
                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private var fortuneCategories: [FortuneCategory] {
        [
            FortuneCategory(emoji: "☕", title: "Kahve Falı", subtitle: "Fincanınızın sırları", karma: 8, isNew: false) {
                coordinator.presentSheet(.coffeeFortuneInput)
            },
            FortuneCategory(emoji: "🃏", title: "Tarot Falı", subtitle: "Kartların bilgeliği", karma: 5, isNew: false) {
                coordinator.presentSheet(.tarotFortuneInput)
            },
            FortuneCategory(emoji: "✋", title: "El Falı", subtitle: "Avucunuzdaki çizgiler", karma: 10, isNew: true) {
                coordinator.presentSheet(.palmFortuneInput)
            },
            FortuneCategory(emoji: "🌙", title: "Rüya Yorumu", subtitle: "Bilinçaltınızın mesajları", karma: 6, isNew: false) {
                coordinator.presentSheet(.dreamFortuneInput)
            }
        ]
    }
    
    // MARK: - Daily Horoscope Section
    private var dailyHoroscopeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Günlük Burç Yorumu")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Ücretsiz")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(zodiacSigns, id: \.name) { sign in
                        zodiacCard(sign)
                    }
                }
            }
        }
    }
    
    private func zodiacCard(_ sign: ZodiacSign) -> some View {
        Button(action: {
            // Show daily horoscope for this sign
        }) {
            VStack(spacing: 8) {
                Text(sign.emoji)
                    .font(.system(size: 32))
                
                Text(sign.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private var zodiacSigns: [ZodiacSign] {
        [
            ZodiacSign(name: "Koç", emoji: "♈"),
            ZodiacSign(name: "Boğa", emoji: "♉"),
            ZodiacSign(name: "İkizler", emoji: "♊"),
            ZodiacSign(name: "Yengeç", emoji: "♋"),
            ZodiacSign(name: "Aslan", emoji: "♌"),
            ZodiacSign(name: "Başak", emoji: "♍"),
            ZodiacSign(name: "Terazi", emoji: "♎"),
            ZodiacSign(name: "Akrep", emoji: "♏"),
            ZodiacSign(name: "Yay", emoji: "♐"),
            ZodiacSign(name: "Oğlak", emoji: "♑"),
            ZodiacSign(name: "Kova", emoji: "♒"),
            ZodiacSign(name: "Balık", emoji: "♓")
        ]
    }
    
    // MARK: - Tests Section
    private var testsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kişilik Testleri")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(personalityTests, id: \.title) { test in
                    testRow(test)
                }
            }
        }
    }
    
    private func testRow(_ test: PersonalityTest) -> some View {
        Button(action: test.action) {
            HStack(spacing: 14) {
                Text(test.emoji)
                    .font(.system(size: 28))
                    .frame(width: 50, height: 50)
                    .background(test.color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(test.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(test.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    private var personalityTests: [PersonalityTest] {
        [
            PersonalityTest(emoji: "🧠", title: "Kişilik Testi", subtitle: "Karakterini keşfet", color: .purple) {},
            PersonalityTest(emoji: "💕", title: "Aşk Testi", subtitle: "İlişki stilini öğren", color: .pink) {},
            PersonalityTest(emoji: "💼", title: "Kariyer Testi", subtitle: "İdeal mesleğini bul", color: .blue) {}
        ]
    }
}

// MARK: - Supporting Types
struct FortuneCategory {
    let emoji: String
    let title: String
    let subtitle: String
    let karma: Int
    let isNew: Bool
    let action: () -> Void
}

struct ZodiacSign {
    let name: String
    let emoji: String
}

struct PersonalityTest {
    let emoji: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(red: 0.08, green: 0.04, blue: 0.12)
            .ignoresSafeArea()
        
        DiscoverMainView()
    }
    .environmentObject(AppCoordinator())
    .environmentObject(UserManager())
}
