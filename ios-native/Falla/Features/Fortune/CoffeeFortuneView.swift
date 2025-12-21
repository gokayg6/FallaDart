// CoffeeFortuneView.swift
// Falla - iOS 26 Fortune Telling App
// Coffee fortune reading flow with Liquid Glass UI

import SwiftUI
import PhotosUI

// MARK: - Coffee Fortune View
/// Full coffee fortune reading experience with image upload and AI interpretation
@available(iOS 26.0, *)
struct CoffeeFortuneView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var currentStep: CoffeeFortuneStep = .intro
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var fortuneResult: FortuneResult?
    @State private var animationProgress: CGFloat = 0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground(style: .warm, enableParticles: true)
            
            // Content
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Step content
                stepContent
            }
            
            // Loading overlay
            if isAnalyzing {
                analysisOverlay
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
            
            // Progress indicator
            if currentStep != .result {
                progressIndicator
            }
            
            Spacer()
            
            // Placeholder for alignment
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep.rawValue 
                          ? FallaColors.coffeeOrange 
                          : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentStep.rawValue ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .intro:
            introStep
        case .upload:
            uploadStep
        case .preview:
            previewStep
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
                                    FallaColors.coffeeOrange.opacity(0.4),
                                    FallaColors.coffeeOrange.opacity(0.1),
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
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 50))
                        .foregroundColor(FallaColors.coffeeOrange)
                }
                .pulsingGlow(color: FallaColors.coffeeOrange)
                
                // Title
                VStack(spacing: 12) {
                    Text("Kahve Falı")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Fincanınızın sırlarını keşfedin")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Instructions
                GlassCard(cornerRadius: 24, padding: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nasıl Çalışır?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        instructionRow(number: 1, text: "Türk kahvenizi için ve telvesini bekletin")
                        instructionRow(number: 2, text: "Fincanı tabağa ters çevirin ve soğumasını bekleyin")
                        instructionRow(number: 3, text: "Fincanın iç kısmının fotoğraflarını çekin")
                        instructionRow(number: 4, text: "Yapay zeka yorumunuzu hazırlasın")
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
                        currentStep = .upload
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Başla")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(FallaColors.coffeeOrange)
                    }
                    .shadow(color: FallaColors.coffeeOrange.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ElasticButtonStyle())
                .padding(.horizontal, 40)
                
                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(FallaColors.coffeeOrange)
                .frame(width: 24, height: 24)
                .background {
                    Circle()
                        .fill(FallaColors.coffeeOrange.opacity(0.2))
                }
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Upload Step
    private var uploadStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                
                Text("Fotoğraf Yükleyin")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text("Fincanınızın en az 1 fotoğrafını yükleyin")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                // Photo picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .glassEffect(.regular, in: Circle())
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundColor(FallaColors.coffeeOrange)
                        }
                        
                        Text("Fotoğraf Seç")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                                    )
                                    .foregroundColor(.white.opacity(0.2))
                            }
                    }
                }
                .padding(.horizontal, 20)
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep = .preview
                            }
                        }
                    }
                }
                
                // Tips
                GlassCard(cornerRadius: 20, padding: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("İpuçları")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("• İyi aydınlatma kullanın\n• Fincanın tamamını kadrajlayın\n• Farklı açılardan birden fazla fotoğraf çekin")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .scrollIndicators(.hidden)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Preview Step
    private var previewStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)
                
                Text("Fotoğrafınız")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                // Image preview
                if let image = selectedImages.first {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                FallaColors.coffeeOrange.opacity(0.6),
                                                FallaColors.coffeeOrange.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            }
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        // Remove button
                        Button {
                            withAnimation {
                                selectedImages.removeAll()
                                currentStep = .upload
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background {
                                    Circle()
                                        .fill(.black.opacity(0.6))
                                }
                        }
                        .offset(x: 8, y: -8)
                    }
                }
                
                Text("Bu fotoğrafı kullanmak istiyor musunuz?")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        withAnimation {
                            selectedImages.removeAll()
                            currentStep = .upload
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Tekrar Seç")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .buttonStyle(ElasticButtonStyle())
                    
                    Button {
                        analyzeFortune()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Fal Baktır")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(FallaColors.coffeeOrange)
                        }
                        .shadow(color: FallaColors.coffeeOrange.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ElasticButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .scrollIndicators(.hidden)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Result Step
    private var resultStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)
                
                // Success indicator
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    FallaColors.coffeeOrange.opacity(0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: Circle())
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(FallaColors.coffeeOrange)
                }
                
                Text("Falınız Hazır!")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                // Fortune content
                if let result = fortuneResult {
                    GlassCard(cornerRadius: 24, padding: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Categories
                            ForEach(result.sections, id: \.title) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: section.icon)
                                            .foregroundColor(FallaColors.coffeeOrange)
                                        Text(section.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(section.content)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineSpacing(4)
                                }
                                
                                if section != result.sections.last {
                                    Divider()
                                        .background(.white.opacity(0.1))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        // Save to history
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
                                .fill(FallaColors.coffeeOrange)
                        }
                    }
                    .buttonStyle(ElasticButtonStyle())
                    
                    Button {
                        // Share
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Paylaş")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    // MARK: - Analysis Overlay
    private var analysisOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated rings
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(FallaColors.coffeeOrange.opacity(0.3), lineWidth: 2)
                            .frame(width: 80 + CGFloat(i * 40), height: 80 + CGFloat(i * 40))
                            .rotationEffect(.degrees(animationProgress * 360 * (i % 2 == 0 ? 1 : -1)))
                    }
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: Circle())
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 28))
                        .foregroundColor(FallaColors.coffeeOrange)
                }
                
                VStack(spacing: 8) {
                    Text("Fincanınız Yorumlanıyor")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Yapay zeka kahve telvenizi analiz ediyor...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animationProgress = 1
            }
        }
    }
    
    // MARK: - Navigation
    private func goToPreviousStep() {
        switch currentStep {
        case .intro:
            break
        case .upload:
            currentStep = .intro
        case .preview:
            currentStep = .upload
        case .result:
            currentStep = .preview
        }
    }
    
    // MARK: - Analysis
    private func analyzeFortune() {
        isAnalyzing = true
        
        // Simulate AI analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            fortuneResult = FortuneResult(
                sections: [
                    FortuneSection(
                        icon: "heart.fill",
                        title: "Aşk Hayatı",
                        content: "Fincanınızda bir kalp şekli görülüyor. Yakın zamanda duygusal hayatınızda güzel gelişmeler olacak gibi görünüyor. Bir kişi hayatınıza gelebilir veya mevcut ilişkiniz derinleşebilir."
                    ),
                    FortuneSection(
                        icon: "briefcase.fill",
                        title: "Kariyer",
                        content: "İş hayatınızda yeni fırsatlar kapınızı çalacak. Fincanın kenarındaki çizgiler yükselişi simgeliyor. Bu dönemde kendinizi geliştirmeye odaklanın."
                    ),
                    FortuneSection(
                        icon: "star.fill",
                        title: "Genel Yorum",
                        content: "Önünüzdeki haftalarda şansınız yaver gidecek. Fincanınızdaki açık renk bölgeler pozitif enerjiyi temsil ediyor. Cesur kararlar almaktan çekinmeyin."
                    )
                ]
            )
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnalyzing = false
                currentStep = .result
            }
        }
    }
}

// MARK: - Coffee Fortune Step
enum CoffeeFortuneStep: Int {
    case intro = 0
    case upload = 1
    case preview = 2
    case result = 3
}

// MARK: - Fortune Result
struct FortuneResult {
    let sections: [FortuneSection]
}

struct FortuneSection: Equatable {
    let icon: String
    let title: String
    let content: String
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Coffee Fortune") {
    CoffeeFortuneView()
        .environmentObject(AppCoordinator())
        .environmentObject(UserManager())
}
