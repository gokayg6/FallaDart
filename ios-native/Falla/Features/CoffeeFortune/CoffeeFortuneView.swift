// CoffeeFortuneView.swift
// Falla - iOS 26 Fortune Telling App
// Coffee fortune reading flow with image upload

import SwiftUI
import PhotosUI

// MARK: - Coffee Fortune View
struct CoffeeFortuneView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var selectedImages: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var question: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var fortuneResult: FortuneModel?
    
    // MARK: - Animation State
    @State private var floatOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    
    // MARK: - Constants
    private let karmaCost = 8
    private let maxImages = 4
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            // Floating particles
            floatingParticles
            
            // Main content
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        imageUploadSection
                        questionSection
                        instructionsSection
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Action bar
                actionBar
            }
            
            // Loading overlay
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
    
    // MARK: - Floating Particles
    private var floatingParticles: some View {
        GeometryReader { geometry in
            ForEach(0..<15, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.15))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .offset(y: floatOffset * CGFloat(index % 3 + 1) * 0.5)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Title
            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text("☕")
                        .font(.system(size: 22))
                    Text("Kahve Falı")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Fincanınızın sırları")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Karma badge
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
                // Animated coffee cup
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
                    
                    Text("☕")
                        .font(.system(size: 50))
                        .offset(y: floatOffset * 0.3)
                }
                
                Text("Fincanınızın Gizli Mesajları")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    .multilineTextAlignment(.center)
                
                Text("Kahve fincanınızın fotoğraflarını yükleyin ve yapay zeka destekli mistik yorumlarınızı keşfedin.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.71, blue: 0.55).opacity(glowIntensity),
                            Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Image Upload Section
    private var imageUploadSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Fincan Fotoğrafları")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(selectedImages.count)/\(maxImages)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Upload buttons
                HStack(spacing: 12) {
                    PhotosPicker(
                        selection: $photoPickerItems,
                        maxSelectionCount: maxImages - selectedImages.count,
                        matching: .images
                    ) {
                        uploadButton(icon: "photo.on.rectangle", title: "Galeri")
                    }
                    .onChange(of: photoPickerItems) { oldItems, newItems in
                        Task {
                            await loadImages(from: newItems)
                        }
                    }
                    
                    // Camera button (simplified - would need camera access)
                    uploadButton(icon: "camera", title: "Kamera")
                }
                
                // Selected images or placeholder
                if selectedImages.isEmpty {
                    emptyImagePlaceholder
                } else {
                    selectedImagesGrid
                }
            }
        }
    }
    
    private func uploadButton(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.15))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.4),
                            lineWidth: 1
                        )
                }
        )
    }
    
    private var emptyImagePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Henüz fotoğraf seçilmedi")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var selectedImagesGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3),
                                    lineWidth: 2
                                )
                        }
                    
                    // Remove button
                    Button(action: { removeImage(at: index) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .offset(x: 6, y: -6)
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
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Sorunuz (İsteğe Bağlı)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                TextField("Falınızda öğrenmek istediğiniz bir konu var mı?", text: $question, axis: .vertical)
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
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nasıl Yapılır?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(instructions, id: \.title) { instruction in
                HStack(alignment: .top, spacing: 12) {
                    Text(instruction.icon)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(instruction.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(instruction.description)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var instructions: [(icon: String, title: String, description: String)] {
        [
            ("☕", "Fincanı Çevirin", "Kahveyi içtikten sonra fincanı tabağın üzerine kapatın"),
            ("⏳", "Bekleyin", "Telvesinin kuruyup şekillenmesi için birkaç dakika bekleyin"),
            ("📸", "Fotoğraf Çekin", "Fincanın içini farklı açılardan net bir şekilde çekin")
        ]
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 16) {
                // Info text
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedImages.count) fotoğraf seçildi")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    if userManager.karma < karmaCost {
                        Text("Yetersiz karma (\(userManager.karma)/\(karmaCost))")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Generate button
                Button(action: generateFortune) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Falımı Gör")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
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
                    .clipShape(Capsule())
                }
                .disabled(selectedImages.isEmpty || userManager.karma < karmaCost)
                .opacity(selectedImages.isEmpty || userManager.karma < karmaCost ? 0.5 : 1.0)
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
            
            MysticalLoading(message: "Falınız hazırlanıyor...")
        }
    }
    
    // MARK: - Methods
    private func startAnimations() {
        // Float animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatOffset = 10
        }
        
        // Glow animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.6
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    if selectedImages.count < maxImages {
                        selectedImages.append(image)
                    }
                }
            }
        }
        photoPickerItems.removeAll()
    }
    
    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    private func generateFortune() {
        guard !selectedImages.isEmpty else {
            errorMessage = "Lütfen en az bir fotoğraf seçin"
            showError = true
            return
        }
        
        guard userManager.karma >= karmaCost else {
            errorMessage = "Yetersiz karma. Gerekli: \(karmaCost)"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Deduct karma
                await userManager.updateKarma(-karmaCost)
                
                // Upload images and generate fortune
                // Note: This would call AIService and FirebaseService in production
                
                // Simulate delay for demo
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                // Create fortune result
                let fortune = FortuneModel(
                    id: UUID().uuidString,
                    userId: AuthManager.shared.currentUser?.uid ?? "",
                    type: .coffee,
                    status: .completed,
                    title: "Kahve Falı",
                    interpretation: "AI generated interpretation would appear here...",
                    imageUrls: [],
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
                    errorMessage = "Fal oluşturulurken hata: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CoffeeFortuneView()
        .environmentObject(AppCoordinator())
        .environmentObject(UserManager())
}
