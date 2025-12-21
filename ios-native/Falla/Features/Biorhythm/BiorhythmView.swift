// BiorhythmView.swift
// Falla - iOS 26 Fortune Telling App
// Biorhythm screen with real algorithm and Liquid Glass UI

import SwiftUI

// MARK: - Biorhythm View
/// Full biorhythm display with Physical, Emotional, and Mental cycles
/// Uses real biorhythm algorithm based on user's birth date
@available(iOS 26.0, *)
struct BiorhythmView: View {
    // MARK: - Environment
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var selectedDate: Date = Date()
    @State private var biorhythm: BiorhythmData?
    @State private var animatedPhysical: Double = 0
    @State private var animatedEmotional: Double = 0
    @State private var animatedMental: Double = 0
    @State private var showDatePicker = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                AnimatedBackground(style: .mystical, enableParticles: true)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with date selector
                        headerSection
                        
                        // Main circular progress display
                        mainProgressSection
                        
                        // Individual cycle cards
                        cycleCardsSection
                        
                        // Weekly forecast
                        weeklyForecastSection
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Biyoritm")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationBackground(.clear)
        .onAppear {
            calculateBiorhythm()
        }
        .onChange(of: selectedDate) { _, _ in
            calculateBiorhythm()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Date display and selector
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(FallaColors.champagneGold)
                    
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.thin, in: Capsule())
                }
            }
            .buttonStyle(ElasticButtonStyle())
            
            // Expandable date picker
            if showDatePicker {
                DatePicker(
                    "Tarih Seç",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .tint(FallaColors.champagneGold)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .padding(.top, 20)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Main Progress Section
    private var mainProgressSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            FallaColors.champagneGold.opacity(0.15),
                            .clear
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
            
            // Triple ring display
            ZStack {
                // Physical ring (outer)
                progressRing(
                    progress: animatedPhysical,
                    color: FallaColors.physicalBlue,
                    size: 240,
                    lineWidth: 16
                )
                
                // Emotional ring (middle)
                progressRing(
                    progress: animatedEmotional,
                    color: FallaColors.emotionalRed,
                    size: 190,
                    lineWidth: 14
                )
                
                // Mental ring (inner)
                progressRing(
                    progress: animatedMental,
                    color: FallaColors.mentalYellow,
                    size: 140,
                    lineWidth: 12
                )
                
                // Center average display
                centerDisplay
            }
        }
    }
    
    private func progressRing(progress: Double, color: Color, size: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            // Background ring with glass effect
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            color.opacity(0.5),
                            color,
                            color.opacity(0.8)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 0)
        }
        .frame(width: size, height: size)
    }
    
    private var centerDisplay: some View {
        ZStack {
            // Glass background
            Circle()
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: Circle())
                .frame(width: 100, height: 100)
            
            VStack(spacing: 4) {
                Text("\(Int(averageValue))")
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text("Ort")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private var averageValue: Double {
        guard let bio = biorhythm else { return 0 }
        return (bio.physical + bio.emotional + bio.mental) / 3
    }
    
    // MARK: - Cycle Cards Section
    private var cycleCardsSection: some View {
        VStack(spacing: 12) {
            cycleCard(
                title: "Fiziksel",
                value: biorhythm?.physical ?? 0,
                animatedValue: animatedPhysical,
                color: FallaColors.physicalBlue,
                icon: "figure.run",
                description: biorhythm?.physicalDescription ?? ""
            )
            
            cycleCard(
                title: "Duygusal",
                value: biorhythm?.emotional ?? 0,
                animatedValue: animatedEmotional,
                color: FallaColors.emotionalRed,
                icon: "heart.fill",
                description: biorhythm?.emotionalDescription ?? ""
            )
            
            cycleCard(
                title: "Zihinsel",
                value: biorhythm?.mental ?? 0,
                animatedValue: animatedMental,
                color: FallaColors.mentalYellow,
                icon: "brain.head.profile",
                description: biorhythm?.mentalDescription ?? ""
            )
        }
    }
    
    private func cycleCard(
        title: String,
        value: Double,
        animatedValue: Double,
        color: Color,
        icon: String,
        description: String
    ) -> some View {
        GlassCard(cornerRadius: 20, padding: 16, tintColor: color) {
            HStack(spacing: 16) {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(animatedValue * 100))%")
                            .font(.system(size: 20, weight: .light, design: .rounded))
                            .foregroundColor(color)
                            .contentTransition(.numericText())
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [color.opacity(0.7), color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * animatedValue)
                                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
                        }
                    }
                    .frame(height: 6)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
        }
    }
    
    // MARK: - Weekly Forecast Section
    private var weeklyForecastSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Haftalık Görünüm")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            GlassCard(cornerRadius: 20, padding: 16) {
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        weekDayColumn(dayOffset: dayOffset)
                        
                        if dayOffset < 6 {
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private func weekDayColumn(dayOffset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedDate) ?? Date()
        let isToday = dayOffset == 0
        
        let dayBio = BiorhythmCalculator.calculate(
            birthDate: authManager.userProfile?.birthDate ?? Date(),
            targetDate: date
        )
        
        let avgValue = (dayBio.physical + dayBio.emotional + dayBio.mental) / 3
        
        return VStack(spacing: 8) {
            Text(dayName(for: date))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isToday ? FallaColors.champagneGold : .white.opacity(0.5))
            
            ZStack {
                Circle()
                    .fill(isToday ? FallaColors.champagneGold.opacity(0.2) : Color.clear)
                    .frame(width: 36, height: 36)
                
                Text("\(Int(avgValue * 100))")
                    .font(.system(size: 12, weight: isToday ? .bold : .medium, design: .rounded))
                    .foregroundColor(isToday ? FallaColors.champagneGold : .white.opacity(0.7))
            }
            
            // Mini indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(colorForValue(avgValue))
                .frame(width: 20, height: 4)
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func colorForValue(_ value: Double) -> Color {
        if value >= 0.7 {
            return .green
        } else if value >= 0.4 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - Calculate Biorhythm
    private func calculateBiorhythm() {
        guard let birthDate = authManager.userProfile?.birthDate else {
            // Use a default birth date for demo
            let calendar = Calendar.current
            let defaultBirthDate = calendar.date(byAdding: .year, value: -25, to: Date()) ?? Date()
            
            let bio = BiorhythmCalculator.calculate(
                birthDate: defaultBirthDate,
                targetDate: selectedDate
            )
            
            animateBiorhythm(bio)
            return
        }
        
        let bio = BiorhythmCalculator.calculate(
            birthDate: birthDate,
            targetDate: selectedDate
        )
        
        animateBiorhythm(bio)
    }
    
    private func animateBiorhythm(_ bio: BiorhythmData) {
        biorhythm = bio
        
        // Animate to new values
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animatedPhysical = bio.physical
            animatedEmotional = bio.emotional
            animatedMental = bio.mental
        }
    }
}

// MARK: - Biorhythm Calculator
/// Real biorhythm algorithm using sine waves
/// Physical: 23-day cycle, Emotional: 28-day cycle, Mental: 33-day cycle
struct BiorhythmCalculator {
    static func calculate(birthDate: Date, targetDate: Date) -> BiorhythmData {
        let calendar = Calendar.current
        let daysSinceBirth = calendar.dateComponents([.day], from: birthDate, to: targetDate).day ?? 0
        
        // Physical cycle: 23 days
        let physicalCycle = 23.0
        let physicalAngle = (2 * Double.pi * Double(daysSinceBirth)) / physicalCycle
        let physicalValue = (sin(physicalAngle) + 1) / 2 // Normalize to 0-1
        
        // Emotional cycle: 28 days
        let emotionalCycle = 28.0
        let emotionalAngle = (2 * Double.pi * Double(daysSinceBirth)) / emotionalCycle
        let emotionalValue = (sin(emotionalAngle) + 1) / 2
        
        // Mental cycle: 33 days
        let mentalCycle = 33.0
        let mentalAngle = (2 * Double.pi * Double(daysSinceBirth)) / mentalCycle
        let mentalValue = (sin(mentalAngle) + 1) / 2
        
        return BiorhythmData(
            physical: physicalValue,
            emotional: emotionalValue,
            mental: mentalValue,
            daysSinceBirth: daysSinceBirth
        )
    }
}

// MARK: - Biorhythm Data
struct BiorhythmData {
    let physical: Double      // 0.0 to 1.0
    let emotional: Double     // 0.0 to 1.0
    let mental: Double        // 0.0 to 1.0
    let daysSinceBirth: Int
    
    var physicalDescription: String {
        if physical >= 0.7 {
            return "Enerjiniz yüksek, aktif olun!"
        } else if physical >= 0.4 {
            return "Normal enerji seviyesi"
        } else {
            return "Dinlenmeye ihtiyacınız var"
        }
    }
    
    var emotionalDescription: String {
        if emotional >= 0.7 {
            return "Duygusal dengeniz mükemmel"
        } else if emotional >= 0.4 {
            return "Dengeli bir gün"
        } else {
            return "Sakin kalmaya çalışın"
        }
    }
    
    var mentalDescription: String {
        if mental >= 0.7 {
            return "Zihinsel performansınız üst düzeyde"
        } else if mental >= 0.4 {
            return "Normal konsantrasyon"
        } else {
            return "Karmaşık işlerden kaçının"
        }
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Biorhythm View") {
    BiorhythmView()
        .environmentObject(AuthManager.shared)
}
