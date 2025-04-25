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
    
    // Singleton para acesso global
    static let shared = AuthViewModel()
    
    private init() {
        // Verificar estado inicial da autenticação
        checkAuthState()
    }
    
    // MARK: - Métodos de autenticação
    
    // Verifica o estado atual de autenticação
    func checkAuthState() {
        isLoading = true
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                // Usuário está autenticado
                let userId = user.uid
                
                // Tentar carregar do cache primeiro
                if let cachedUser = self.loadUserFromCache(userId: userId) {
                    print("📱 [LOG] Usuário carregado do cache local")
                    self.currentUser = cachedUser
                    self.isAuthenticated = true
                    self.isLoading = false
                    
                    // Atualizar em segundo plano para manter dados frescos
                    self.refreshUserDataInBackground(userId: userId)
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
            }
        }
    }
    
    // Carrega dados do usuário do cache local
    private func loadUserFromCache(userId: String) -> UserModel? {
        let defaults = UserDefaults.standard
        
        // Verificar se existe a data do cache e se ainda é válida
        guard let cacheDate = defaults.object(forKey: userCacheDateKey) as? Date else {
            return nil
        }
        
        // Verificar se o cache ainda é válido (menos de 24 horas)
        let cacheAge = Date().timeIntervalSince(cacheDate)
        if cacheAge > maxCacheAge {
            print("📱 [LOG] Cache expirado (idade: \(Int(cacheAge/60)) minutos)")
            return nil
        }
        
        // Obter os dados arquivados
        guard let cachedData = defaults.data(forKey: userCacheKey) else {
            return nil
        }
        
        do {
            // Desempacotar os dados arquivados
            guard let userData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cachedData) as? [String: Any],
                  let cachedUserId = userData["id"] as? String,
                  cachedUserId == userId else {
                return nil
            }
            
            // Converter o dicionário para UserModel
            let username = userData["username"] as? String ?? ""
            let profileImageURL = userData["profileImageURL"] as? String
            let gold = userData["gold"] as? Int ?? 0
            let isFull = userData["isFull"] as? Bool ?? false
            let settings = userData["settings"] as? [String: Bool] ?? [:]
            
            var user = UserModel(
                id: userId,
                username: username,
                profileImageURL: profileImageURL?.isEmpty == true ? nil : profileImageURL,
                gold: gold,
                isFull: isFull
            )
            user.settings = settings
            
            return user
        } catch {
            print("📱 [LOG] Erro ao carregar cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Salva os dados do usuário no cache local
    private func saveUserToCache(user: UserModel) {
        guard let userId = user.id else { return }
        
        // Converter valores nil para String vazia para garantir compatibilidade com Property List
        let profileImageURLString = user.profileImageURL ?? ""
        
        var userData: [String: Any] = [
            "id": userId,
            "username": user.username,
            "profileImageURL": profileImageURLString,
            "gold": user.gold,
            "isFull": user.isFull
        ]
        
        // Garantir que o dicionário de configurações seja válido
        if !user.settings.isEmpty {
            userData["settings"] = user.settings
        } else {
            userData["settings"] = [String: Bool]()
        }
        
        // Usar valores serializáveis
        let defaults = UserDefaults.standard
        
        do {
            // Verificar se os dados são serializáveis
            let data = try NSKeyedArchiver.archivedData(withRootObject: userData, requiringSecureCoding: false)
            defaults.set(data, forKey: userCacheKey)
            defaults.set(Date(), forKey: userCacheDateKey)
            print("📱 [LOG] Dados do usuário salvos no cache local")
        } catch {
            print("📱 [LOG] Erro ao salvar cache: \(error.localizedDescription)")
        }
    }
    
    // Limpa o cache do usuário
    private func clearUserCache() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: userCacheKey)
        defaults.removeObject(forKey: userCacheDateKey)
        
        print("📱 [LOG] Cache do usuário limpo")
    }
    
    // Atualiza os dados do usuário em segundo plano para manter o cache fresco
    private func refreshUserDataInBackground(userId: String) {
        firestoreService.getUser(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let userModel):
                if let user = userModel {
                    print("📱 [LOG] Dados do usuário atualizados em segundo plano")
                    self.currentUser = user
                    
                    // Tentar salvar no cache, mas não interromper a operação se falhar
                    do {
                        self.saveUserToCache(user: user)
                    } catch {
                        print("📱 [LOG] Erro ao salvar no cache durante refreshUserDataInBackground: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("📱 [LOG] Erro ao atualizar dados em segundo plano: \(error.localizedDescription)")
                // Não atualizamos o estado de isAuthenticated ou isLoading porque esta é uma atualização em segundo plano
            }
        }
    }
    
    // Busca os dados do usuário no Firestore usando o FirestoreService
    private func getUserData(userId: String) {
        firestoreService.getUser(userId: userId) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let userModel):
                if let user = userModel {
                    self.currentUser = user
                    self.isAuthenticated = true
                    
                    // Tentar salvar no cache local para futuras consultas
                    // Se ocorrer erro, apenas logamos mas continuamos a operação
                    do {
                        self.saveUserToCache(user: user)
                    } catch {
                        print("📱 [LOG] Erro ao salvar no cache durante getUserData: \(error.localizedDescription)")
                    }
                } else {
                    // Se não encontrou dados no Firestore, pode ser um usuário novo
                    if let user = self.auth.currentUser {
                        // Cria objeto de usuário básico
                        let newUser = UserModel(
                            id: user.uid,
                            username: user.displayName ?? "Usuário",
                            profileImageURL: nil,
                            gold: 0,
                            isFull: false
                        )
                        self.saveUserData(user: newUser)
                    } else {
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                }
            case .failure(let error):
                // Se o Firestore estiver inacessível mas o usuário estiver logado no Firebase Auth,
                // criamos um objeto básico de usuário para permitir uma experiência mínima
                if let user = self.auth.currentUser {
                    print("📱 [LOG] Erro ao carregar dados do Firestore, usando dados básicos do Auth: \(error.localizedDescription)")
                    
                    // Cria um objeto de usuário básico com os dados disponíveis no Firebase Auth
                    let basicUser = UserModel(
                        id: user.uid,
                        username: user.displayName ?? "Usuário",
                        profileImageURL: nil,
                        gold: 0,
                        isFull: false
                    )
                    
                    self.currentUser = basicUser
                    self.isAuthenticated = true
                    
                    // Não salvamos no cache para forçar nova tentativa na próxima vez
                    
                    // Tentamos novamente em segundo plano após alguns segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.refreshUserDataInBackground(userId: user.uid)
                    }
                } else {
                    self.error = "Erro ao carregar dados: \(error.localizedDescription)"
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    // Registra um novo usuário
    func register(email: String, password: String, username: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // Cria o usuário no Firebase Auth
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = "Erro no registro: \(error.localizedDescription)"
                completion(false, self.error)
                return
            }
            
            guard let authResult = result else {
                self.isLoading = false
                self.error = "Erro desconhecido no registro"
                completion(false, self.error)
                return
            }
            
            // Atualiza o displayName do usuário
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = username
            changeRequest.commitChanges { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Erro ao atualizar displayName: \(error.localizedDescription)")
                }
                
                // Cria o objeto de usuário (usando o modelo atualizado sem email)
                let user = UserModel(
                    id: authResult.user.uid,
                    username: username,
                    profileImageURL: nil,
                    gold: 0,
                    isFull: false
                )
                
                // Salva os dados extras no Firestore usando o FirestoreService
                self.saveUserData(user: user, completion: completion)
            }
        }
    }
    
    // Faz login de um usuário existente
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = "Erro no login: \(error.localizedDescription)"
                completion(false, self.error)
                return
            }
            
            guard let user = result?.user else {
                self.isLoading = false
                self.error = "Usuário não encontrado"
                completion(false, self.error)
                return
            }
            
            // Busca dados adicionais do usuário no Firestore
            self.getUserData(userId: user.uid)
            completion(true, nil)
        }
    }
    
    // Realiza logout
    func logout(completion: @escaping (Bool) -> Void) {
        do {
            // Limpar cache antes de fazer logout
            self.clearUserCache()
            
            try auth.signOut()
            
            // Atualizar estado após logout bem-sucedido
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                completion(true)
            }
        } catch {
            self.error = "Erro ao fazer logout: \(error.localizedDescription)"
            completion(false)
        }
    }
    
    // Salva os dados do usuário no Firestore usando o FirestoreService
    private func saveUserData(user: UserModel, completion: ((Bool, String?) -> Void)? = nil) {
        firestoreService.createUser(user: user) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success:
                self.currentUser = user
                self.isAuthenticated = true
                
                // Tentar salvar no cache local após salvar no Firestore
                // Não falhar a operação se o cache falhar
                do {
                    self.saveUserToCache(user: user)
                } catch {
                    print("📱 [LOG] Erro ao salvar no cache durante saveUserData: \(error.localizedDescription)")
                }
                
                completion?(true, nil)
            case .failure(let error):
                self.error = "Erro ao salvar dados: \(error.localizedDescription)"
                completion?(false, self.error)
            }
        }
    }
    
    // Envia email para redefinição de senha
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, "Erro ao enviar email: \(error.localizedDescription)")
            } else {
                completion(true, nil)
            }
        }
    }
    
    // Exclui a conta do usuário
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let user = auth.currentUser, let userId = user.uid as String? else {
            completion(false, "Usuário não está autenticado")
            return
        }
        
        // Primeiro exclui o documento do Firestore usando o FirestoreService
        firestoreService.deleteUser(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Depois exclui a conta do Auth
                user.delete { error in
                    if let error = error {
                        self.error = "Erro ao excluir conta: \(error.localizedDescription)"
                        completion(false, self.error)
                    } else {
                        self.currentUser = nil
                        self.isAuthenticated = false
                        completion(true, nil)
                    }
                }
            case .failure(let error):
                self.error = "Erro ao excluir dados: \(error.localizedDescription)"
                completion(false, self.error)
            }
        }
    }
    
    // Função para reautenticar e depois deletar a conta
    func reauthenticateAndDeleteAccount(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = auth.currentUser else {
            completion(false, "Usuário não está autenticado")
            return
        }
        
        isLoading = true
        
        // Criar credenciais para reautenticação
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        // Reautenticar o usuário
        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = "Erro na reautenticação: \(error.localizedDescription)"
                completion(false, self.error)
                return
            }
            
            // Agora que o usuário está reautenticado, prossegue com a exclusão
            self.deleteAccount(completion: completion)
        }
    }
    
    // Método para forçar atualização dos dados do usuário
    func refreshUserData(completion: ((Bool) -> Void)? = nil) {
        guard let userId = currentUser?.id else {
            completion?(false)
            return
        }
        
        isLoading = true
        
        firestoreService.getUser(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let userModel):
                    if let user = userModel {
                        self.currentUser = user
                        
                        // Tentar salvar no cache sem afetar o fluxo principal
                        do {
                            self.saveUserToCache(user: user)
                        } catch {
                            print("📱 [LOG] Erro ao salvar no cache durante refreshUserData: \(error.localizedDescription)")
                            // Mesmo com erro no cache, a operação é considerada bem-sucedida
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