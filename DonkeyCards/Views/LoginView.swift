import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoAnimation = false
    
    var body: some View {
        ZStack {
            // Fundo com gradiente
            backgroundView
                .ignoresSafeArea()
            
            // Conteúdo principal
            ScrollView {
                VStack(spacing: 25) {
                    // Cabeçalho e logo
                    headerView
                        .padding(.top, 40)
                    
                    Spacer(minLength: 20)
                    
                    // Formulário
                    if viewModel.showForgotPassword {
                        forgotPasswordForm
                    } else if viewModel.isRegisterMode {
                        registerForm
                    } else {
                        loginForm
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 30)
            }
            .scrollDismissesKeyboard(.immediately)
            
            // Overlay de loading
            if viewModel.isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppTheme.accentColor)
                    
                    Text("Processando...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor)
                        .padding(.top, 15)
                }
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {
                if viewModel.resetEmailSent {
                    viewModel.showForgotPassword = false
                    viewModel.resetEmailSent = false
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: viewModel.isSuccess) { success in
            if success {
                dismiss()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        ZStack {
            // Gradient base que preenche toda a tela
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    Color(red: 0.03, green: 0.18, blue: 0.08) // Verde mais escuro
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Elementos decorativos
            Circle()
                .fill(AppTheme.accentColor.opacity(0.08))
                .frame(width: UIScreen.main.bounds.width * 0.75)
                .position(x: UIScreen.main.bounds.width * 0.85, y: UIScreen.main.bounds.height * 0.2)
                .blur(radius: 5)
            
            Circle()
                .fill(AppTheme.accentColor.opacity(0.1))
                .frame(width: UIScreen.main.bounds.width * 0.5)
                .position(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.28)
                .blur(radius: 4)
            
            Circle()
                .fill(AppTheme.accentColor.opacity(0.06))
                .frame(width: UIScreen.main.bounds.width * 0.6)
                .position(x: UIScreen.main.bounds.width * 0.1, y: UIScreen.main.bounds.height * 0.7)
                .blur(radius: 5)
            
            Circle()
                .fill(AppTheme.accentColor.opacity(0.09))
                .frame(width: UIScreen.main.bounds.width * 0.45)
                .position(x: UIScreen.main.bounds.width * 0.7, y: UIScreen.main.bounds.height * 0.75)
                .blur(radius: 4)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Logo
            Image("LOGO") // Substitua pelo nome real do logo
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .opacity(showLogoAnimation ? 1 : 0)
                .scaleEffect(showLogoAnimation ? 1 : 0.8)
                .shadow(color: AppTheme.accentColor.opacity(0.6), radius: 10, x: 0, y: 5)
                .onAppear {
                    withAnimation(.spring(dampingFraction: 0.7).delay(0.2)) {
                        showLogoAnimation = true
                    }
                }
            
            // Título
            Text(viewModel.showForgotPassword ? "Recuperar Senha" : (viewModel.isRegisterMode ? "Criar Conta" : "Login"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.accentColor)
                .padding(.bottom, 5)
            
            // Subtítulo
            Text(viewModel.showForgotPassword ? 
                "Enviaremos um link para você recuperar sua senha" : 
                (viewModel.isRegisterMode ? 
                    "Crie sua conta para salvar seu progresso" : 
                    "Entre para continuar seu aprendizado"))
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            // Campo de email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                TextField("", text: $viewModel.email)
                    .font(.system(size: 16))
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .foregroundColor(AppTheme.textColor)
                
                if let error = viewModel.emailErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            
            // Campo de senha
            VStack(alignment: .leading, spacing: 8) {
                Text("Senha")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                SecureField("", text: $viewModel.password)
                    .font(.system(size: 16))
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(AppTheme.textColor)
                
                if let error = viewModel.passwordErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            
            // Link para recuperar senha
            Button {
                viewModel.showForgotPassword = true
            } label: {
                Text("Esqueceu sua senha?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 5)
            
            // Botão de login
            Button {
                viewModel.login()
            } label: {
                Text("Entrar")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        viewModel.canSubmitLogin ?
                        AppTheme.gradientAccent :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: viewModel.canSubmitLogin ? AppTheme.accentColor.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
            }
            .disabled(!viewModel.canSubmitLogin)
            .padding(.top, 20)
            
            // Separador
            HStack {
                Rectangle()
                    .fill(AppTheme.textColor.opacity(0.3))
                    .frame(height: 1)
                
                Text("OU")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .padding(.horizontal, 10)
                
                Rectangle()
                    .fill(AppTheme.textColor.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 20)
            
            // Link para registro
            Button {
                viewModel.toggleRegisterMode()
            } label: {
                Text("Criar nova conta")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(12)
            }
        }
    }
    
    private var registerForm: some View {
        VStack(spacing: 20) {
            // Campo de nome de usuário
            VStack(alignment: .leading, spacing: 8) {
                Text("Nome de usuário")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                TextField("", text: $viewModel.username)
                    .font(.system(size: 16))
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(AppTheme.textColor)
                
                if let error = viewModel.usernameErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            
            // Campo de email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                TextField("", text: $viewModel.email)
                    .font(.system(size: 16))
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .foregroundColor(AppTheme.textColor)
                
                if let error = viewModel.emailErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            
            // Campo de senha
            VStack(alignment: .leading, spacing: 8) {
                Text("Senha")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                SecureField("", text: $viewModel.password)
                    .font(.system(size: 16))
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(AppTheme.textColor)
                
                if let error = viewModel.passwordErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            
            // Campo de confirmação de senha
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirmar senha")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                SecureField("", text: $viewModel.confirmPassword)
                    .font(.system(size: 16))
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(AppTheme.textColor)
                
                if let error = viewModel.confirmPasswordErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            
            // Botão de registro
            Button {
                viewModel.register()
            } label: {
                Text("Criar Conta")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        viewModel.canSubmitRegister ?
                        AppTheme.gradientAccent :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: viewModel.canSubmitRegister ? AppTheme.accentColor.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
            }
            .disabled(!viewModel.canSubmitRegister)
            .padding(.top, 20)
            
            // Link para voltar ao login
            Button {
                viewModel.toggleRegisterMode()
            } label: {
                Text("Já tem uma conta? Entrar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
    }
    
    private var forgotPasswordForm: some View {
        VStack(spacing: 25) {
            // Campo de email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                TextField("", text: $viewModel.email)
                    .font(.system(size: 16))
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .foregroundColor(AppTheme.textColor)
                
                if let error = viewModel.emailErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.errorColor)
                }
            }
            
            // Instruções
            Text("Enviaremos um email com instruções para redefinir sua senha.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
            
            // Botão de enviar
            Button {
                viewModel.resetPassword()
            } label: {
                Text("Enviar Email")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        viewModel.isEmailValid ?
                        AppTheme.gradientAccent :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: viewModel.isEmailValid ? AppTheme.accentColor.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
            }
            .disabled(!viewModel.isEmailValid)
            .padding(.top, 10)
            
            // Botão de voltar
            Button {
                viewModel.showForgotPassword = false
            } label: {
                Text("Voltar ao Login")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
    }
} 