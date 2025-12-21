// SpinWheelView.swift
// Falla - iOS 26 Fortune Telling App
// Karma spin wheel with rewards

import SwiftUI

// MARK: - Spin Wheel View
struct SpinWheelMainView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var canSpin = true
    @State private var showReward = false
    @State private var rewardAmount = 0
    @State private var animateGlow = false
    @State private var selectedSegmentIndex = 0
    
    // MARK: - Rewards
    private let rewards: [WheelReward] = [
        WheelReward(amount: 5, color: Color.red, probability: 0.25),
        WheelReward(amount: 10, color: Color.orange, probability: 0.20),
        WheelReward(amount: 15, color: Color.yellow, probability: 0.18),
        WheelReward(amount: 20, color: Color.green, probability: 0.15),
        WheelReward(amount: 25, color: Color.teal, probability: 0.10),
        WheelReward(amount: 50, color: Color.blue, probability: 0.07),
        WheelReward(amount: 75, color: Color.purple, probability: 0.03),
        WheelReward(amount: 100, color: Color.pink, probability: 0.02),
    ]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                headerView
                
                Spacer()
                
                wheelSection
                
                Spacer()
                
                spinButton
                
                infoText
            }
            .padding(20)
            
            // Reward popup
            if showReward {
                rewardPopup
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
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
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Karma Çarkı")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Günlük ücretsiz çevir!")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Current karma
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                
                Text("\(userManager.karma)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.top, 40)
    }
    
    // MARK: - Wheel Section
    private var wheelSection: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.82, green: 0.71, blue: 0.55).opacity(animateGlow ? 0.3 : 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 200
                    )
                )
                .frame(width: 350, height: 350)
            
            // Wheel
            ZStack {
                // Segments
                ForEach(Array(rewards.enumerated()), id: \.offset) { index, reward in
                    wheelSegment(index: index, reward: reward)
                }
            }
            .frame(width: 280, height: 280)
            .rotationEffect(.degrees(rotation))
            .overlay {
                // Border
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.82, green: 0.71, blue: 0.55),
                                Color(red: 0.6, green: 0.45, blue: 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 8
                    )
            }
            .shadow(color: Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3), radius: 20)
            
            // Center circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.82, green: 0.71, blue: 0.55),
                                Color(red: 0.6, green: 0.45, blue: 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Pointer
            VStack {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    .shadow(color: .black.opacity(0.3), radius: 4)
                
                Spacer()
            }
            .frame(height: 320)
        }
    }
    
    private func wheelSegment(index: Int, reward: WheelReward) -> some View {
        let segmentAngle = 360.0 / Double(rewards.count)
        let startAngle = Double(index) * segmentAngle - 90
        
        return ZStack {
            // Segment shape
            WheelSegmentShape(startAngle: startAngle, endAngle: startAngle + segmentAngle)
                .fill(reward.color.opacity(0.8))
            
            // Text
            Text("\(reward.amount)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(-rotation)) // Counter-rotate to keep text upright
                .offset(x: 80 * cos((startAngle + segmentAngle / 2) * .pi / 180),
                        y: 80 * sin((startAngle + segmentAngle / 2) * .pi / 180))
        }
    }
    
    // MARK: - Spin Button
    private var spinButton: some View {
        Button(action: spin) {
            HStack(spacing: 12) {
                if isSpinning {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                    Text(canSpin ? "ÇEVİR!" : "Yarın tekrar gel")
                }
            }
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                canSpin && !isSpinning
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
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .disabled(!canSpin || isSpinning)
    }
    
    private var infoText: some View {
        Text("Her gün bir ücretsiz çevirme hakkınız var.")
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.4))
            .multilineTextAlignment(.center)
    }
    
    // MARK: - Reward Popup
    private var rewardPopup: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    showReward = false
                }
            
            VStack(spacing: 24) {
                // Confetti effect (simplified)
                ZStack {
                    Circle()
                        .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                        .frame(width: 150, height: 150)
                    
                    Text("🎉")
                        .font(.system(size: 70))
                }
                
                Text("Tebrikler!")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    
                    Text("+\(rewardAmount) Karma")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                }
                
                Text("Kazandığınız karma hesabınıza eklendi!")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Button(action: {
                    showReward = false
                }) {
                    Text("Harika!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.82, green: 0.71, blue: 0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.1, green: 0.06, blue: 0.14))
                    .strokeBorder(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Spin Logic
    private func spin() {
        guard canSpin && !isSpinning else { return }
        
        isSpinning = true
        
        // Select reward by probability
        selectedSegmentIndex = selectRewardByProbability()
        let reward = rewards[selectedSegmentIndex]
        rewardAmount = reward.amount
        
        // Calculate final rotation
        let segmentAngle = 360.0 / Double(rewards.count)
        let targetSegmentCenter = Double(rewards.count - 1 - selectedSegmentIndex) * segmentAngle + segmentAngle / 2
        let fullSpins = 5 * 360.0 // 5 full rotations
        let finalRotation = fullSpins + targetSegmentCenter
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Animate
        withAnimation(.easeOut(duration: 4)) {
            rotation = finalRotation
        }
        
        // Show reward after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            isSpinning = false
            canSpin = false
            
            // Add karma to user
            Task {
                await userManager.updateKarma(rewardAmount)
            }
            
            // Show reward popup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showReward = true
            }
        }
    }
    
    private func selectRewardByProbability() -> Int {
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for (index, reward) in rewards.enumerated() {
            cumulative += reward.probability
            if random <= cumulative {
                return index
            }
        }
        
        return 0
    }
}

// MARK: - Wheel Segment Shape
struct WheelSegmentShape: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Wheel Reward
struct WheelReward {
    let amount: Int
    let color: Color
    let probability: Double
}

// MARK: - Preview
#Preview {
    SpinWheelMainView()
        .environmentObject(UserManager())
}
