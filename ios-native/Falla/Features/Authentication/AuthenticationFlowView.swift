// AuthenticationFlowView.swift
// Falla - iOS 26 Fortune Telling App
// Authentication flow with Liquid Glass forms and coordinated transitions

import SwiftUI

// MARK: - Authentication Flow View
/// Main authentication container managing login and register views
@available(iOS 26.0, *)
struct AuthenticationFlowView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var authManager: AuthManager
    
    // MARK: - State
    @State private var showingLogin = true
    @State private var showForgotPassword = false
    
    // MARK: - Namespace
    @Namespace private var authNamespace
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground(style: .mystical, enableParticles: true)
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Logo and branding
                    brandingSection
                        .padding(.top, 60)
                    
                    // Auth form with glass effect
                    if showingLogin {
                        LoginFormView(
                            showingLogin: $showingLogin,
                            showForgotPassword: $showForgotPassword,
                            namespace: authNamespace
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    } else {
                        RegisterFormView(
                            showingLogin: $showingLogin,
                            namespace: authNamespace
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet()
        }
        .environment(\.glassNamespace, authNamespace)
    }
    
    // MARK: - Branding Section
    private var brandingSection: some View {
        VStack(spacing: 16) {
            // Animated logo with glass effect
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
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)
                
                // Glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: Circle())
                    .overlay {
                        Circle()
                            .fill(FallaColors.champagneGold.opacity(0.1))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        FallaColors.champagneGold.opacity(0.5),
                                        FallaColors.champagneGold.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .frame(width: 100, height: 100)
                
                // App icon/logo placeholder
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FallaColors.champagneGold)
            }
            .pulsingGlow(color: FallaColors.champagneGold, minOpacity: 0.15, maxOpacity: 0.35)
            
            // App name
            Text("Falla")
                .font(.system(size: 42, weight: .light, design: .serif))
                .foregroundColor(.white)
            
            // Tagline
            Text("Geleceğinizi keşfedin")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Login Form View
@available(iOS 26.0, *)
struct LoginFormView: View {
    // MARK: - Bindings
    @Binding var showingLogin: Bool
    @Binding var showForgotPassword: Bool
    let namespace: Namespace.ID
    
    // MARK: - Environment
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var coordinator: AppCoordinator
    
    // MARK: - State
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // MARK: - Focus
    @FocusState private var focusedField: AuthField?
    
    enum AuthField {
        case email, password
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            // Glass form card
            GlassCard(cornerRadius: 28, padding: 24, glassID: "auth.form") {
                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Hoş Geldiniz")
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Hesabınıza giriş yapın")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Email field
                    glassTextField(
                        icon: "envelope",
                        placeholder: "E-posta adresi",
                        text: $email,
                        keyboardType: .emailAddress,
                        isFocused: focusedField == .email
                    )
                    .focused($focusedField, equals: .email)
                    .textInputAutocapitalization(.never)
                    
                    // Password field
                    glassSecureField(
                        icon: "lock",
                        placeholder: "Şifre",
                        text: $password,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    
                    // Forgot password
                    HStack {
                        Spacer()
                        Button("Şifremi Unuttum") {
                            showForgotPassword = true
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FallaColors.champagneGold)
                    }
                    
                    // Login button
                    Button {
                        login()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            } else {
                                Text("Giriş Yap")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            FallaColors.champagneGold,
                                            FallaColors.champagneGold.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .shadow(color: FallaColors.champagneGold.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ElasticButtonStyle())
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                }
            }
            
            // Social login options
            socialLoginSection
            
            // Guest and register options
            bottomSection
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Bir hata oluştu")
        }
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            // Divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 1)
                
                Text("veya")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 1)
            }
            
            // Social buttons
            HStack(spacing: 16) {
                socialLoginButton(icon: "apple.logo", label: "Apple") {
                    // Apple Sign In
                }
                
                socialLoginButton(icon: "g.circle.fill", label: "Google") {
                    // Google Sign In
                }
            }
        }
    }
    
    private func socialLoginButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .buttonStyle(ElasticButtonStyle())
    }
    
    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Guest login
            Button {
                loginAsGuest()
            } label: {
                Text("Misafir olarak devam et")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Register link
            HStack(spacing: 4) {
                Text("Hesabınız yok mu?")
                    .foregroundColor(.white.opacity(0.6))
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingLogin = false
                    }
                } label: {
                    Text("Kayıt Ol")
                        .fontWeight(.semibold)
                        .foregroundColor(FallaColors.champagneGold)
                }
            }
            .font(.system(size: 14))
        }
        .padding(.top, 8)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func login() {
        focusedField = nil
        isLoading = true
        
        Task {
            do {
                _ = try await authManager.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    coordinator.handleLoginSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func loginAsGuest() {
        isLoading = true
        
        Task {
            do {
                _ = try await authManager.signInAnonymously()
                await MainActor.run {
                    isLoading = false
                    coordinator.handleLoginSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Text Field Helpers
    
    private func glassTextField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isFocused: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? FallaColors.champagneGold : .white.opacity(0.5))
                .frame(width: 24)
            
            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isFocused
                                ? FallaColors.champagneGold.opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: isFocused ? 1 : 0.5
                        )
                }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isFocused)
    }
    
    private func glassSecureField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isFocused: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? FallaColors.champagneGold : .white.opacity(0.5))
                .frame(width: 24)
            
            SecureField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isFocused
                                ? FallaColors.champagneGold.opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: isFocused ? 1 : 0.5
                        )
                }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - Register Form View
@available(iOS 26.0, *)
struct RegisterFormView: View {
    // MARK: - Bindings
    @Binding var showingLogin: Bool
    let namespace: Namespace.ID
    
    // MARK: - Environment
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var coordinator: AppCoordinator
    
    // MARK: - State
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showDatePicker = false
    
    // MARK: - Focus
    @FocusState private var focusedField: RegisterField?
    
    enum RegisterField {
        case name, email, password, confirmPassword
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            // Glass form card
            GlassCard(cornerRadius: 28, padding: 24, glassID: "auth.form") {
                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Hesap Oluştur")
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Yolculuğunuza başlayın")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Name field
                    glassTextField(
                        icon: "person",
                        placeholder: "Adınız",
                        text: $name,
                        isFocused: focusedField == .name
                    )
                    .focused($focusedField, equals: .name)
                    
                    // Email field
                    glassTextField(
                        icon: "envelope",
                        placeholder: "E-posta adresi",
                        text: $email,
                        keyboardType: .emailAddress,
                        isFocused: focusedField == .email
                    )
                    .focused($focusedField, equals: .email)
                    .textInputAutocapitalization(.never)
                    
                    // Birth date field
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDatePicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 24)
                            
                            Text(formattedBirthDate)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    
                    if showDatePicker {
                        DatePicker(
                            "Doğum Tarihi",
                            selection: $birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .colorScheme(.dark)
                        .labelsHidden()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Password field
                    glassSecureField(
                        icon: "lock",
                        placeholder: "Şifre",
                        text: $password,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    
                    // Confirm password field
                    glassSecureField(
                        icon: "lock.fill",
                        placeholder: "Şifre Tekrar",
                        text: $confirmPassword,
                        isFocused: focusedField == .confirmPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    
                    // Password mismatch warning
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle")
                            Text("Şifreler eşleşmiyor")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.8))
                    }
                    
                    // Register button
                    Button {
                        register()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            } else {
                                Text("Kayıt Ol")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            FallaColors.champagneGold,
                                            FallaColors.champagneGold.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .shadow(color: FallaColors.champagneGold.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ElasticButtonStyle())
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid ? 1 : 0.6)
                }
            }
            
            // Login link
            HStack(spacing: 4) {
                Text("Zaten hesabınız var mı?")
                    .foregroundColor(.white.opacity(0.6))
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingLogin = true
                    }
                } label: {
                    Text("Giriş Yap")
                        .fontWeight(.semibold)
                        .foregroundColor(FallaColors.champagneGold)
                }
            }
            .font(.system(size: 14))
            .padding(.bottom, 40)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Bir hata oluştu")
        }
    }
    
    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: birthDate)
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func register() {
        focusedField = nil
        isLoading = true
        
        Task {
            do {
                _ = try await authManager.register(
                    email: email,
                    password: password,
                    displayName: name,
                    birthDate: birthDate
                )
                await MainActor.run {
                    isLoading = false
                    coordinator.handleLoginSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Text Field Helpers
    
    private func glassTextField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isFocused: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? FallaColors.champagneGold : .white.opacity(0.5))
                .frame(width: 24)
            
            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isFocused
                                ? FallaColors.champagneGold.opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: isFocused ? 1 : 0.5
                        )
                }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isFocused)
    }
    
    private func glassSecureField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isFocused: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? FallaColors.champagneGold : .white.opacity(0.5))
                .frame(width: 24)
            
            SecureField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isFocused
                                ? FallaColors.champagneGold.opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: isFocused ? 1 : 0.5
                        )
                }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - Forgot Password Sheet
@available(iOS 26.0, *)
struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(style: .mystical, enableParticles: false)
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .glassEffect(.regular, in: Circle())
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: showSuccess ? "checkmark" : "key.fill")
                            .font(.system(size: 32))
                            .foregroundColor(showSuccess ? .green : FallaColors.champagneGold)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    
                    VStack(spacing: 8) {
                        Text(showSuccess ? "E-posta Gönderildi" : "Şifre Sıfırlama")
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundColor(.white)
                        
                        Text(showSuccess
                             ? "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi"
                             : "E-posta adresinizi girin, şifre sıfırlama bağlantısı göndereceğiz")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    if !showSuccess {
                        // Email field
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .font(.system(size: 18))
                                .foregroundColor(isFocused ? FallaColors.champagneGold : .white.opacity(0.5))
                                .frame(width: 24)
                            
                            TextField("E-posta adresi", text: $email)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .focused($isFocused)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(
                                            isFocused
                                                ? FallaColors.champagneGold.opacity(0.5)
                                                : Color.white.opacity(0.1),
                                            lineWidth: isFocused ? 1 : 0.5
                                        )
                                }
                        }
                        
                        // Send button
                        Button {
                            sendResetEmail()
                        } label: {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.9)
                                } else {
                                    Text("Gönder")
                                    Image(systemName: "paperplane.fill")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(FallaColors.champagneGold)
                            }
                        }
                        .buttonStyle(ElasticButtonStyle())
                        .disabled(email.isEmpty || isLoading)
                        .opacity(email.isEmpty ? 0.6 : 1)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Text("Giriş Ekranına Dön")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(FallaColors.champagneGold)
                                }
                        }
                        .buttonStyle(ElasticButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationBackground(.clear)
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Bir hata oluştu")
        }
    }
    
    private func sendResetEmail() {
        isFocused = false
        isLoading = true
        
        Task {
            do {
                try await authManager.sendPasswordReset(email: email)
                await MainActor.run {
                    isLoading = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Authentication Flow") {
    AuthenticationFlowView()
        .environmentObject(AppCoordinator())
        .environmentObject(AuthManager.shared)
}
