// PalmFortuneView.swift
// Falla - iOS 26 Fortune Telling App
// Palm reading with image capture and AI analysis

import SwiftUI
import PhotosUI

// MARK: - Palm Fortune View
struct PalmFortuneView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var palmImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var question: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var fortuneResult: FortuneModel?
    @State private var showGuide = true
    
    // MARK: - Animation
    @State private var floatOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    
    private let karmaCost = 10
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        imageSection
                        
                        if palmImage != nil {
                            questionSection
                        }
                        
                        if showGuide {
                            guideSection
                        }
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                actionBar
            }
            
            if isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            startAnimations()
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(item: $fortuneResult) { fortune in
            FortuneResultView(fortuneId: fortune.id)
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
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    Text("El Falı")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Avucunuzdaki Sırlar")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            KarmaBadge(karmaCost, size: .medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        GlassCard(cornerRadius: 24, padding: 24) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .opacity(glowIntensity)
                    
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                        .offset(y: floatOffset * 0.3)
                }
                
                Text("Avucunuzdaki Çizgiler")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                
                Text("Elinizin fotoğrafını çekin, yapay zeka destekli el falı yorumunuzu alın.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("El Fotoğrafı")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                if let image = palmImage {
                    // Display selected image
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.5),
                                        lineWidth: 2
                                    )
                            }
                        
                        Button(action: { palmImage = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(8)
                    }
                    
                    // Retake button
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Başka Fotoğraf Seç")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    }
                    .onChange(of: photoPickerItem) { oldItem, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                palmImage = image
                                showGuide = false
                            }
                        }
                    }
                } else {
                    // Upload prompt
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                            }
                            
                            Text("Elinizin Fotoğrafını Yükleyin")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Sol elinizin avuç içi fotoğrafını net bir şekilde çekin")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.03))
                                .strokeBorder(
                                    Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: [8])
                                )
                        )
                    }
                    .onChange(of: photoPickerItem) { oldItem, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                palmImage = image
                                showGuide = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Question Section
    private var questionSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    
                    Text("Sorunuz (İsteğe Bağlı)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                TextField("Öğrenmek istediğiniz bir konu var mı?", text: $question, axis: .vertical)
                    .lineLimit(3...5)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Guide Section
    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nasıl Fotoğraf Çekilir?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(palmLines, id: \.name) { line in
                HStack(spacing: 12) {
                    Text(line.emoji)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(line.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(line.description)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var palmLines: [(emoji: String, name: String, description: String)] {
        [
            ("❤️", "Kalp Çizgisi", "Duygusal yaşam ve ilişkiler hakkında bilgi verir"),
            ("🧠", "Kafa Çizgisi", "Düşünce yapısı ve karar verme süreçlerini gösterir"),
            ("⏳", "Yaşam Çizgisi", "Canlılık ve önemli yaşam olaylarını temsil eder"),
            ("🌟", "Kader Çizgisi", "Kariyer ve hayat yolunuzu işaret eder")
        ]
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                if palmImage != nil {
                    Text("Fotoğraf hazır")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green.opacity(0.8))
                } else {
                    Text("Fotoğraf yükleyin")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button(action: generateFortune) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("El Falımı Gör")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        palmImage != nil
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
                    .clipShape(Capsule())
                }
                .disabled(palmImage == nil)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            MysticalLoading(message: "Avucunuz analiz ediliyor...")
        }
    }
    
    // MARK: - Methods
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatOffset = 10
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.6
        }
    }
    
    private func generateFortune() {
        guard palmImage != nil else { return }
        guard userManager.karma >= karmaCost else {
            errorMessage = "Yetersiz karma. Gerekli: \(karmaCost)"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                await userManager.updateKarma(-karmaCost)
                
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                let fortune = FortuneModel(
                    id: UUID().uuidString,
                    userId: AuthManager.shared.currentUser?.uid ?? "",
                    type: .palm,
                    status: .completed,
                    title: "El Falı",
                    interpretation: "AI palm reading interpretation...",
                    question: question.isEmpty ? nil : question,
                    karmaUsed: karmaCost
                )
                
                await MainActor.run {
                    isLoading = false
                    fortuneResult = fortune
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Hata: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PalmFortuneView()
        .environmentObject(UserManager())
}
