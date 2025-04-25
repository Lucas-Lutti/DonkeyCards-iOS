import Foundation
import Combine
import FirebaseAuth

class AuthViewModel: ObservableObject {
    // Estado de autenticação
    @Published var currentUser: UserModel?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // Referência aos serviços
    private let auth = Auth.auth()
    private let firestoreService = FirestoreService.shared
    
    // Chaves para UserDefaults
    private let userCacheKey = "cachedUserData"
    private let userCacheDateKey = "cachedUserDate"
    // Tempo máximo de validade do cache em segundos (24 horas)
    private let maxCacheAge: TimeInterval = 86400
    
    // Controle de estado
    private var isRefreshing = false
    private var hasInitialCheck = false
    
    // Singleton para acesso global
    static let shared = AuthViewModel()
    
    private init() {
        // Verificar estado inicial da autenticação
        checkAuthState()
    }
    
    // MARK: - Métodos de autenticação
    
    // Verifica o estado atual de autenticação
    func checkAuthState() {
        // Evitar múltiplas chamadas simultâneas
        guard !isLoading else { return }
        
        isLoading = true
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                // Usuário está autenticado
                let userId = user.uid
                
                // Se já tiver feito a verificação inicial, não buscar dados novamente
                if self.hasInitialCheck && self.currentUser?.id == userId {
                    self.isLoading = false
                    return
                }
                
                // Tentar carregar do cache primeiro
                if let cachedUser = self.loadUserFromCache(userId: userId) {
                    print("📱 [LOG] Usuário carregado do cache local")
                    self.currentUser = cachedUser
                    self.isAuthenticated = true
                    self.isLoading = false
                    self.hasInitialCheck = true
                    
                    // Atualizar em segundo plano apenas se não estiver já atualizando
                    if !self.isRefreshing {
                        self.refreshUserDataInBackground(userId: userId)
                    }
                } else {
                    // Se não tiver no cache, buscar do Firestore
                    print("📱 [LOG] Cache não encontrado, buscando do Firestore")
                    self.getUserData(userId: userId)
                }
            } else {
                // Usuário não está autenticado
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false
                self.clearUserCache() // Limpar cache ao fazer logout
                self.hasInitialCheck = true
            }
        }
    }
    
    // ... resto do código existente ...
    
    // Atualiza os dados do usuário em segundo plano para manter o cache fresco
    private func refreshUserDataInBackground(userId: String) {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        firestoreService.getUser(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            self.isRefreshing = false
            
            switch result {
            case .success(let userModel):
                if let user = userModel {
                    print("📱 [LOG] Dados do usuário atualizados em segundo plano")
                    DispatchQueue.main.async {
                        self.currentUser = user
                        // Tentar salvar no cache, mas não interromper a operação se falhar
                        do {
                            self.saveUserToCache(user: user)
                        } catch {
                            print("📱 [LOG] Erro ao salvar no cache durante refreshUserDataInBackground: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print("📱 [LOG] Erro ao atualizar dados em segundo plano: \(error.localizedDescription)")
            }
        }
    }
    
    // Método para forçar atualização dos dados do usuário
    func refreshUserData(completion: ((Bool) -> Void)? = nil) {
        guard let userId = currentUser?.id, !isRefreshing else {
            completion?(false)
            return
        }
        
        isLoading = true
        isRefreshing = true
        
        firestoreService.getUser(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isRefreshing = false
                
                switch result {
                case .success(let userModel):
                    if let user = userModel {
                        self.currentUser = user
                        
                        // Tentar salvar no cache sem afetar o fluxo principal
                        do {
                            self.saveUserToCache(user: user)
                        } catch {
                            print("📱 [LOG] Erro ao salvar no cache durante refreshUserData: \(error.localizedDescription)")
                        }
                        
                        completion?(true)
                    } else {
                        completion?(false)
                    }
                case .failure(let error):
                    print("📱 [LOG] Erro ao atualizar dados: \(error.localizedDescription)")
                    completion?(false)
                }
            }
        }
    }
} 