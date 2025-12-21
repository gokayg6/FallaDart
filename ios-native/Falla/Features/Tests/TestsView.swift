// TestsView.swift
// Falla - iOS 26 Fortune Telling App
// Personality and compatibility tests screen

import SwiftUI

// MARK: - Tests Main View
struct TestsMainView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - State
    @State private var selectedCategory: TestCategory = .personality
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                categoryPicker
                testsGrid
                
                Spacer()
                    .frame(height: 150)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Testler")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text("Kendini keşfet")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.top, 60)
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TestCategory.allCases, id: \.self) { category in
                    categoryButton(category)
                }
            }
        }
    }
    
    private func categoryButton(_ category: TestCategory) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 8) {
                Text(category.emoji)
                Text(category.title)
            }
            .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .medium))
            .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical: 10)
            .background(
                Capsule()
                    .fill(selectedCategory == category 
                        ? Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3)
                        : Color.white.opacity(0.05))
                    .strokeBorder(
                        selectedCategory == category 
                            ? Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.6)
                            : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - Tests Grid
    private var testsGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(testsForCategory(selectedCategory), id: \.id) { test in
                testCard(test)
            }
        }
    }
    
    private func testCard(_ test: TestItem) -> some View {
        Button(action: {
            coordinator.presentFullScreen(.testDetail(testId: test.id))
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(test.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(test.emoji)
                        .font(.system(size: 28))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(test.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if test.isNew {
                            Text("YENİ")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(test.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(test.questionCount) soru", systemImage: "list.bullet")
                        Label("\(test.duration) dk", systemImage: "clock")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Data
    private func testsForCategory(_ category: TestCategory) -> [TestItem] {
        switch category {
        case .personality:
            return [
                TestItem(id: "mbti", emoji: "🧠", title: "MBTI Kişilik Testi", description: "16 kişilik tipinden hangisisin?", questionCount: 20, duration: 10, color: .purple, isNew: false),
                TestItem(id: "big5", emoji: "⭐", title: "Big Five Kişilik Testi", description: "5 temel kişilik özelliğini keşfet", questionCount: 25, duration: 12, color: .blue, isNew: false),
                TestItem(id: "enneagram", emoji: "🔮", title: "Enneagram Testi", description: "9 tip arasından kendini bul", questionCount: 30, duration: 15, color: .indigo, isNew: true),
            ]
        case .love:
            return [
                TestItem(id: "love_language", emoji: "💕", title: "Aşk Dili Testi", description: "Nasıl sevilmek istiyorsun?", questionCount: 15, duration: 8, color: .pink, isNew: false),
                TestItem(id: "attachment", emoji: "💑", title: "Bağlanma Stili", description: "İlişkilerdeki bağlanma stilin", questionCount: 20, duration: 10, color: .red, isNew: false),
                TestItem(id: "ideal_partner", emoji: "💘", title: "İdeal Partner Testi", description: "Sana en uygun partner tipi", questionCount: 18, duration: 9, color: .orange, isNew: true),
            ]
        case .career:
            return [
                TestItem(id: "career_path", emoji: "💼", title: "Kariyer Yolu Testi", description: "Hangi kariyer sana uygun?", questionCount: 25, duration: 12, color: .green, isNew: false),
                TestItem(id: "leadership", emoji: "👑", title: "Liderlik Testi", description: "Liderlik potansiyelini keşfet", questionCount: 20, duration: 10, color: .yellow, isNew: false),
            ]
        case .zodiac:
            return [
                TestItem(id: "zodiac_match", emoji: "♈", title: "Burç Uyumu Testi", description: "Hangi burçlarla uyumlusun?", questionCount: 15, duration: 7, color: .cyan, isNew: false),
                TestItem(id: "rising_sign", emoji: "🌅", title: "Yükselen Burç Analizi", description: "Yükselen burcun ne anlatıyor?", questionCount: 12, duration: 6, color: .teal, isNew: true),
            ]
        }
    }
}

// MARK: - Test Category
enum TestCategory: CaseIterable {
    case personality
    case love
    case career
    case zodiac
    
    var title: String {
        switch self {
        case .personality: return "Kişilik"
        case .love: return "Aşk"
        case .career: return "Kariyer"
        case .zodiac: return "Burç"
        }
    }
    
    var emoji: String {
        switch self {
        case .personality: return "🧠"
        case .love: return "💕"
        case .career: return "💼"
        case .zodiac: return "⭐"
        }
    }
}

// MARK: - Test Item
struct TestItem: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let questionCount: Int
    let duration: Int
    let color: Color
    let isNew: Bool
}

// MARK: - Test Detail View
struct TestDetailView: View {
    let testId: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [String: String] = [:]
    @State private var isLoading = false
    @State private var showResult = false
    @State private var resultData: TestResult?
    
    private let questions: [TestQuestion] = [
        TestQuestion(id: "q1", text: "Sosyal ortamlarda kendinizi nasıl hissedersiniz?", options: [
            TestOption(id: "a", text: "Enerjik ve heyecanlı", value: "E"),
            TestOption(id: "b", text: "Rahat ama sessiz", value: "I"),
        ]),
        TestQuestion(id: "q2", text: "Karar alırken neye daha çok güvenirsiniz?", options: [
            TestOption(id: "a", text: "Mantık ve analiz", value: "T"),
            TestOption(id: "b", text: "Duygular ve değerler", value: "F"),
        ]),
        TestQuestion(id: "q3", text: "Planlarınız konusunda nasılsınız?", options: [
            TestOption(id: "a", text: "Her şeyi önceden planlararım", value: "J"),
            TestOption(id: "b", text: "Esnek ve anlık kararlar alırım", value: "P"),
        ]),
        TestQuestion(id: "q4", text: "Bilgiyi nasıl işlersiniz?", options: [
            TestOption(id: "a", text: "Somut detaylara odaklanırım", value: "S"),
            TestOption(id: "b", text: "Büyük resmi görürüm", value: "N"),
        ]),
        TestQuestion(id: "q5", text: "Stres altında nasıl tepki verirsiniz?", options: [
            TestOption(id: "a", text: "Hızlı hareket ederim", value: "E"),
            TestOption(id: "b", text: "Düşünüp analiz ederim", value: "I"),
        ]),
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.04, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if !showResult {
                    // Progress
                    progressView
                    
                    // Question content
                    questionContent
                    
                    // Navigation
                    navigationBar
                } else {
                    resultView
                }
            }
            
            if isLoading {
                MysticalLoading(message: "Sonuçlarınız hesaplanıyor...")
            }
        }
    }
    
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
            
            Text("Kişilik Testi")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for alignment
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Soru \(currentQuestionIndex + 1)/\(questions.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("%\(Int(Double(currentQuestionIndex + 1) / Double(questions.count) * 100))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.82, green: 0.71, blue: 0.55))
                        .frame(width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(questions.count))
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var questionContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                let question = questions[currentQuestionIndex]
                
                Text(question.text)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                
                VStack(spacing: 12) {
                    ForEach(question.options, id: \.id) { option in
                        optionButton(question: question, option: option)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func optionButton(question: TestQuestion, option: TestOption) -> some View {
        let isSelected = answers[question.id] == option.value
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                answers[question.id] = option.value
            }
        }) {
            HStack {
                Text(option.text)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2) : Color.white.opacity(0.05))
                    .strokeBorder(
                        isSelected ? Color(red: 0.82, green: 0.71, blue: 0.55) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
    
    private var navigationBar: some View {
        HStack(spacing: 16) {
            if currentQuestionIndex > 0 {
                Button(action: previousQuestion) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Geri")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            Button(action: nextQuestion) {
                HStack {
                    Text(currentQuestionIndex == questions.count - 1 ? "Bitir" : "İleri")
                    Image(systemName: currentQuestionIndex == questions.count - 1 ? "checkmark" : "arrow.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    answers[questions[currentQuestionIndex].id] != nil
                        ? Color(red: 0.82, green: 0.71, blue: 0.55)
                        : Color.gray.opacity(0.3)
                )
                .clipShape(Capsule())
            }
            .disabled(answers[questions[currentQuestionIndex].id] == nil)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Result header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Text("🎉")
                            .font(.system(size: 50))
                    }
                    
                    Text("Sonucunuz: \(resultData?.type ?? "INFJ")")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    
                    Text(resultData?.title ?? "Savunucu")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                // Description
                GlassCard(cornerRadius: 20, padding: 20) {
                    Text(resultData?.description ?? "Nadir bulunan bir kişilik tipine sahipsiniz. İdealist, prensiplerine bağlı ve güçlü bir vizyona sahipsiniz.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(6)
                }
                .padding(.horizontal, 20)
                
                // Traits
                GlassCard(cornerRadius: 20, padding: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Özellikleriniz")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        ForEach(["Empatik", "Yaratıcı", "İdealist", "Kararlı"], id: \.self) { trait in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(trait)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Share button
                Button(action: {}) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Sonucu Paylaş")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.82, green: 0.71, blue: 0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                
                // Done button
                Button(action: { dismiss() }) {
                    Text("Tamam")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func previousQuestion() {
        withAnimation(.spring(response: 0.3)) {
            currentQuestionIndex -= 1
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation(.spring(response: 0.3)) {
                currentQuestionIndex += 1
            }
        } else {
            submitTest()
        }
    }
    
    private func submitTest() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            resultData = TestResult(
                type: "INFJ",
                title: "Savunucu",
                description: "Nadir bulunan bir kişilik tipine sahipsiniz. İdealist, prensiplerine bağlı ve güçlü bir vizyona sahipsiniz. İnsanlara yardım etmek için güçlü bir motivasyonunuz var."
            )
            isLoading = false
            showResult = true
        }
    }
}

// MARK: - Supporting Types
struct TestQuestion: Identifiable {
    let id: String
    let text: String
    let options: [TestOption]
}

struct TestOption: Identifiable {
    let id: String
    let text: String
    let value: String
}

struct TestResult {
    let type: String
    let title: String
    let description: String
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(red: 0.08, green: 0.04, blue: 0.12)
            .ignoresSafeArea()
        
        TestsMainView()
    }
    .environmentObject(AppCoordinator())
    .environmentObject(UserManager())
}
