import Foundation
import Combine

class LoginViewModel: ObservableObject {
    // Campos de formulário
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var confirmPassword = ""
    
    // Estado do formulário
    @Published var isRegisterMode = false
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = ""
    @Published var isSuccess = false
    
    @Published var showForgotPassword = false
    @Published var resetEmailSent = false
    
    // Referência ao serviço de autenticação
    private let authViewModel = AuthViewModel.shared
    
    // Validação de campos
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    var isUsernameValid: Bool {
        return username.count >= 3
    }
    
    var isConfirmPasswordValid: Bool {
        return password == confirmPassword
    }
    
    var canSubmitLogin: Bool {
        return isEmailValid && isPasswordValid
    }
    
    var canSubmitRegister: Bool {
        return isEmailValid && isPasswordValid && isUsernameValid && isConfirmPasswordValid
    }
    
    // Mensagens de erro para cada campo
    var emailErrorMessage: String? {
        if email.isEmpty { return nil }
        return isEmailValid ? nil : "Email inválido"
    }
    
    var passwordErrorMessage: String? {
        if password.isEmpty { return nil }
        return isPasswordValid ? nil : "Senha deve ter pelo menos 6 caracteres"
    }
    
    var usernameErrorMessage: String? {
        if username.isEmpty { return nil }
        return isUsernameValid ? nil : "Nome de usuário deve ter pelo menos 3 caracteres"
    }
    
    var confirmPasswordErrorMessage: String? {
        if confirmPassword.isEmpty { return nil }
        return isConfirmPasswordValid ? nil : "As senhas não coincidem"
    }
    
    // MARK: - Ações
    
    func login() {
        isLoading = true
        
        authViewModel.login(email: email, password: password) { [weak self] success, errorMessage in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if success {
                self.isSuccess = true
            } else {
                self.showAlert = true
                self.alertTitle = "Erro no Login"
                self.alertMessage = errorMessage ?? "Ocorreu um erro ao fazer login."
            }
        }
    }
    
    func register() {
        isLoading = true
        
        authViewModel.register(email: email, password: password, username: username) { [weak self] success, errorMessage in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if success {
                self.isSuccess = true
            } else {
                self.showAlert = true
                self.alertTitle = "Erro no Registro"
                self.alertMessage = errorMessage ?? "Ocorreu um erro ao criar sua conta."
            }
        }
    }
    
    func resetPassword() {
        isLoading = true
        
        authViewModel.resetPassword(email: email) { [weak self] success, errorMessage in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if success {
                self.resetEmailSent = true
                self.alertTitle = "Email Enviado"
                self.alertMessage = "Um email de redefinição de senha foi enviado para \(self.email)"
            } else {
                self.alertTitle = "Erro"
                self.alertMessage = errorMessage ?? "Ocorreu um erro ao enviar o email de redefinição."
            }
            
            self.showAlert = true
        }
    }
    
    func toggleRegisterMode() {
        isRegisterMode.toggle()
    }
    
    func resetForm() {
        email = ""
        password = ""
        username = ""
        confirmPassword = ""
        isRegisterMode = false
    }
} 