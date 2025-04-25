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
    
    // Flag para controlar o dismiss
    private var isDismissing = false
    
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
            } else if !isAuthenticated && !self.isDismissing {
                print("📱 [ProfileViewModel] User logged out, dismissing")
                self.isDismissing = true
                self.shouldDismiss = true
            }
        }
        .store(in: &cancellables)
    }
    
    // ... resto do código existente ...
} 