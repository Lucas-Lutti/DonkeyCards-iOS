import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    // Referência ao serviço de autenticação
    private let authViewModel = AuthViewModel.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Estado do perfil
    @Published var isLoading = false
    @Published var shouldDismiss = false
    @Published var isInitialized = false
    
    // Callback para alertas
    var alertCallback: ((String, String, (() -> Void)?) -> Void)?
    
    // Estado do usuário
    @Published var user: UserModel?
    
    init() {
        // Inicialização imediata com o valor atual
        self.user = authViewModel.currentUser
        
        // Forçar uma verificação inicial do estado de autenticação
        authViewModel.checkAuthState()
        
        // Combinar os publishers de usuário e autenticação
        Publishers.CombineLatest(
            authViewModel.$currentUser,
            authViewModel.$isAuthenticated
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (user, isAuthenticated) in
            guard let self = self else { return }
            
            print("📱 [ProfileViewModel] State update - isAuthenticated: \(isAuthenticated), user: \(user?.username ?? "nil")")
            
            self.user = user
            
            // Marcar como inicializado após receber o primeiro update
            if !self.isInitialized {
                self.isInitialized = true
            } else if !isAuthenticated {
                print("📱 [ProfileViewModel] User logged out, dismissing")
                self.shouldDismiss = true
            }
        }
        .store(in: &cancellables)
    }
    
    // Acesso direto ao usuário atual
    var currentUser: UserModel? {
        return user
    }
    
    var isAuthenticated: Bool {
        return authViewModel.isAuthenticated
    }
    
    // MARK: - Ações
    
    func checkAuthenticationStatus() -> Bool {
        // Se ainda não estamos inicializados, esperar
        if !isInitialized {
            print("📱 [ProfileViewModel] Waiting for initialization...")
            return true // Retornar true para não fechar a view ainda
        }
        
        let isAuth = authViewModel.isAuthenticated
        let hasUser = authViewModel.currentUser != nil
        print("📱 [ProfileViewModel] checkAuthenticationStatus - isAuthenticated: \(isAuth), hasUser: \(hasUser)")
        return isAuth && hasUser
    }
    
    func refreshUserData() {
        isLoading = true
        authViewModel.refreshUserData { [weak self] success in
            guard let self = self else { return }
            self.isLoading = false
            
            if !success {
                self.showAlert(
                    title: "Erro",
                    message: "Não foi possível atualizar os dados. Tente novamente."
                )
            }
        }
    }
    
    // Atualiza os dados do usuário atual
    func updateUserData(username: String? = nil, profileImageURL: String? = nil, completion: @escaping (Bool) -> Void) {
        guard var updatedUser = self.user else {
            completion(false)
            return
        }
        
        isLoading = true
        
        // Atualiza apenas os campos fornecidos
        if let username = username {
            updatedUser.username = username
        }
        
        if let profileImageURL = profileImageURL {
            updatedUser.profileImageURL = profileImageURL.isEmpty ? nil : profileImageURL
        }
        
        // Usa o FirestoreService para atualizar os dados
        let firestoreService = FirestoreService.shared
        firestoreService.updateUser(user: updatedUser) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    // Atualiza o usuário no AuthViewModel
                    self.authViewModel.refreshUserData { success in
                        completion(success)
                    }
                case .failure(let error):
                    print("📱 [LOG] Erro ao atualizar usuário: \(error.localizedDescription)")
                    self.showAlert(
                        title: "Erro",
                        message: "Não foi possível atualizar os dados. \(error.localizedDescription)"
                    )
                    completion(false)
                }
            }
        }
    }
    
    func logout() {
        isLoading = true
        
        authViewModel.logout { [weak self] success in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if success {
                self.shouldDismiss = true
            } else {
                self.showAlert(
                    title: "Erro",
                    message: "Não foi possível fazer logout. Tente novamente."
                )
            }
        }
    }
    
    func deleteAccount() {
        isLoading = true
        
        authViewModel.deleteAccount { [weak self] success, errorMessage in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if success {
                self.shouldDismiss = true
            } else {
                self.showAlert(
                    title: "Erro",
                    message: errorMessage ?? "Erro ao excluir conta. Tente novamente."
                )
            }
        }
    }
    
    // Nova função que solicita reautenticação antes de excluir a conta
    func reauthenticateAndDeleteAccount(email: String, password: String) {
        isLoading = true
        
        authViewModel.reauthenticateAndDeleteAccount(email: email, password: password) { [weak self] success, errorMessage in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if success {
                self.shouldDismiss = true
            } else {
                self.showAlert(
                    title: "Erro",
                    message: errorMessage ?? "Erro ao excluir conta. Tente novamente."
                )
            }
        }
    }
    
    // Método centralizado para exibir alertas
    private func showAlert(title: String, message: String, action: (() -> Void)? = nil) {
        if Thread.isMainThread {
            self.alertCallback?(title, message, action)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.alertCallback?(title, message, action)
            }
        }
    }
    
    // Formata a data para exibição
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }
} 