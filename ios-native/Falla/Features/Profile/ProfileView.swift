// ProfileView.swift
// Falla - iOS 26 Fortune Telling App
// Profile screen with glass settings cards and avatar

import SwiftUI

// MARK: - Profile View
/// User profile with glass settings, stats, and avatar
@available(iOS 26.0, *)
struct ProfileView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var showLogoutConfirmation = false
    @State private var showEditProfile = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with avatar
                profileHeader
                    .staggeredAnimation(index: 0)
                
                // Stats cards
                statsSection
                    .staggeredAnimation(index: 1)
                
                // Quick actions
                quickActionsSection
                    .staggeredAnimation(index: 2)
                
                // Settings sections
                accountSection
                    .staggeredAnimation(index: 3)
                
                preferencesSection
                    .staggeredAnimation(index: 4)
                
                supportSection
                    .staggeredAnimation(index: 5)
                
                // Logout button
                logoutButton
                    .staggeredAnimation(index: 6)
                
                // App version
                versionInfo
                
                // Bottom padding for nav bar
                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .confirmationDialog(
            "Çıkış yapmak istediğinizden emin misiniz?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Çıkış Yap", role: .destructive) {
                Task {
                    await authManager.signOut()
                }
            }
            Button("İptal", role: .cancel) {}
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar with glow ring
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FallaColors.champagneGold.opacity(0.3),
                                FallaColors.champagneGold.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                
                // Glass ring
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        FallaColors.champagneGold.opacity(0.8),
                                        FallaColors.champagneGold.opacity(0.4),
                                        FallaColors.champagneGold.opacity(0.8)
                                    ],
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                    }
                    .frame(width: 110, height: 110)
                
                // Avatar image or placeholder
                if let avatarURL = authManager.userProfile?.avatarURL,
                   let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }
            }
            .pulsingGlow(color: FallaColors.champagneGold, minOpacity: 0.1, maxOpacity: 0.25)
            
            // Name and info
            VStack(spacing: 6) {
                Text(authManager.userProfile?.name ?? "Kullanıcı")
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                if let zodiac = authManager.userProfile?.zodiacSign {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text(zodiac)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(FallaColors.champagneGold)
                }
                
                if userManager.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                        Text("Premium")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(FallaColors.champagneGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(FallaColors.champagneGold.opacity(0.2))
                    }
                }
            }
            
            // Edit profile button
            Button {
                showEditProfile = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Profili Düzenle")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.thin, in: Capsule())
                }
            }
            .buttonStyle(ElasticButtonStyle())
        }
        .padding(.top, 60)
    }
    
    private var avatarPlaceholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 40))
            .foregroundColor(.white.opacity(0.5))
            .frame(width: 100, height: 100)
            .background {
                Circle()
                    .fill(.white.opacity(0.1))
            }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(userManager.karma)",
                label: "Karma",
                icon: "sparkles",
                color: FallaColors.champagneGold
            )
            
            statCard(
                value: "\(authManager.userProfile?.totalFortunes ?? 0)",
                label: "Fal",
                icon: "eye.fill",
                color: FallaColors.tarotPurple
            )
            
            statCard(
                value: "\(authManager.userProfile?.totalTests ?? 0)",
                label: "Test",
                icon: "square.grid.2x2.fill",
                color: FallaColors.physicalBlue
            )
        }
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        GlassCard(cornerRadius: 16, padding: 12, tintColor: color) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            HStack(spacing: 0) {
                quickActionButton(icon: "crown.fill", label: "Premium", color: FallaColors.champagneGold) {
                    coordinator.presentSheet(.premiumUpgrade)
                }
                
                Divider()
                    .background(.white.opacity(0.1))
                    .frame(height: 50)
                
                quickActionButton(icon: "sparkles", label: "Karma", color: FallaColors.physicalBlue) {
                    coordinator.presentSheet(.karmaStore)
                }
                
                Divider()
                    .background(.white.opacity(0.1))
                    .frame(height: 50)
                
                quickActionButton(icon: "arrow.trianglehead.2.clockwise.rotate.90", label: "Çark", color: FallaColors.emotionalRed) {
                    coordinator.presentSheet(.spinWheel)
                }
            }
        }
    }
    
    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ElasticButtonStyle())
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Hesap")
            
            GlassCard(cornerRadius: 20, padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(icon: "person.fill", title: "Kişisel Bilgiler", color: .white) {
                        showEditProfile = true
                    }
                    
                    Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                    
                    settingsRow(icon: "lock.fill", title: "Şifre Değiştir", color: .white) {
                        // Show password change
                    }
                    
                    Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                    
                    settingsRow(icon: "bell.fill", title: "Bildirimler", color: .white) {
                        // Show notifications settings
                    }
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Tercihler")
            
            GlassCard(cornerRadius: 20, padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(icon: "globe", title: "Dil", value: "Türkçe", color: .white) {}
                    
                    Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                    
                    settingsRow(icon: "paintbrush.fill", title: "Tema", value: "Mistik", color: .white) {}
                    
                    Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                    
                    settingsRow(icon: "eye.slash.fill", title: "Sosyal Görünürlük", hasToggle: true, color: .white) {}
                }
            }
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Destek")
            
            GlassCard(cornerRadius: 20, padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(icon: "questionmark.circle.fill", title: "Yardım", color: .white) {}
                    
                    Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                    
                    settingsRow(icon: "star.fill", title: "Uygulamayı Değerlendir", color: FallaColors.astrologyYellow) {}
                    
                    Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                    
                    settingsRow(icon: "doc.text.fill", title: "Gizlilik Politikası", color: .white) {}
                    
                    Divider().background(.white.opacity(0.1)).padding(.leading, 56)
                    
                    settingsRow(icon: "doc.text.fill", title: "Kullanım Koşulları", color: .white) {}
                }
            }
        }
    }
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.5))
            .textCase(.uppercase)
            .padding(.leading, 4)
    }
    
    private func settingsRow(
        icon: String,
        title: String,
        value: String? = nil,
        hasToggle: Bool = false,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color.opacity(0.8))
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if hasToggle {
                    Toggle("", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: FallaColors.champagneGold))
                        .labelsHidden()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Çıkış Yap")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.red.opacity(0.1))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.red.opacity(0.3), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(ElasticButtonStyle())
    }
    
    // MARK: - Version Info
    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text("Falla")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Versiyon 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.top, 8)
    }
}

// MARK: - Edit Profile Sheet
@available(iOS 26.0, *)
struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var name: String = ""
    @State private var birthDate: Date = Date()
    @State private var selectedGender: String = "Belirtmek istemiyorum"
    @State private var isSaving = false
    
    private let genderOptions = ["Kadın", "Erkek", "Belirtmek istemiyorum"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(style: .mystical, enableParticles: false)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar section
                        avatarEditSection
                        
                        // Form fields
                        formSection
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Profili Düzenle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        saveProfile()
                    }
                    .foregroundColor(FallaColors.champagneGold)
                    .disabled(isSaving)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationBackground(.clear)
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private var avatarEditSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: Circle())
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.5))
                
                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(FallaColors.champagneGold)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 100, height: 100)
            }
            
            Text("Fotoğraf Değiştir")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FallaColors.champagneGold)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Name
            GlassCard(cornerRadius: 16, padding: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "person")
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 24)
                    
                    TextField("Adınız", text: $name)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            
            // Birth date
            GlassCard(cornerRadius: 16, padding: 0) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 24)
                    
                    DatePicker("Doğum Tarihi", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .foregroundColor(.white)
                        .colorScheme(.dark)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Gender
            GlassCard(cornerRadius: 16, padding: 0) {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 24)
                    
                    Picker("Cinsiyet", selection: $selectedGender) {
                        ForEach(genderOptions, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
    
    private func loadCurrentProfile() {
        name = authManager.userProfile?.name ?? ""
        birthDate = authManager.userProfile?.birthDate ?? Date()
        selectedGender = authManager.userProfile?.gender ?? "Belirtmek istemiyorum"
    }
    
    private func saveProfile() {
        isSaving = true
        
        Task {
            do {
                _ = try await authManager.updateProfile(displayName: name)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Profile View") {
    ZStack {
        AnimatedBackground(style: .mystical)
        ProfileView()
    }
    .environmentObject(AppCoordinator())
    .environmentObject(AuthManager.shared)
    .environmentObject(UserManager())
}
