import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    // Singleton para acesso global
    static let shared = AuthService()
    
    // Referências do Firebase
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    // Estado de autenticação atual
    @Published var currentUser: UserModel?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
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
                self.getUserData(userId: user.uid)
            } else {
                // Usuário não está autenticado
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false
            }
        }
    }
    
    // Busca os dados do usuário no Firestore
    private func getUserData(userId: String) {
        firestore.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = "Erro ao carregar dados: \(error.localizedDescription)"
                self.isAuthenticated = false
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                // Converter manualmente o documento para UserModel
                let username = data["username"] as? String ?? "Usuário"
                let profileImageURL = data["profileImageURL"] as? String
                let gold = data["gold"] as? Int ?? 0
                let isFull = data["isFull"] as? Bool ?? false
                let settings = data["settings"] as? [String: Bool] ?? [:]
                
                var userData = UserModel(
                    id: userId,
                    username: username,
                    profileImageURL: profileImageURL,
                    gold: gold,
                    isFull: isFull
                )
                userData.settings = settings
                
                self.currentUser = userData
                self.isAuthenticated = true
            } else {
                // Se não encontrou dados no Firestore, pode ser um usuário novo
                if let user = auth.currentUser {
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
                
                // Cria o objeto de usuário
                let user = UserModel(
                    id: authResult.user.uid,
                    username: username,
                    profileImageURL: nil,
                    gold: 0,
                    isFull: false
                )
                
                // Salva os dados extras no Firestore
                self.saveUserData(user: user) { success in
                    self.isLoading = false
                    if success {
                        self.currentUser = user
                        self.isAuthenticated = true
                        completion(true, nil)
                    } else {
                        self.error = "Erro ao salvar dados de usuário"
                        completion(false, self.error)
                    }
                }
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
            try auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            completion(true)
        } catch {
            self.error = "Erro ao fazer logout: \(error.localizedDescription)"
            completion(false)
        }
    }
    
    // Salva os dados do usuário no Firestore
    private func saveUserData(user: UserModel, completion: ((Bool) -> Void)? = nil) {
        guard let id = user.id else {
            completion?(false)
            return
        }
        
        // Convertendo o objeto UserModel para um dicionário
        let userData: [String: Any] = [
            "username": user.username,
            "profileImageURL": user.profileImageURL as Any,
            "gold": user.gold,
            "isFull": user.isFull,
            "settings": user.settings
        ]
        
        // Salvando no Firestore
        firestore.collection("users").document(id).setData(userData) { error in
            if let error = error {
                self.error = "Erro ao salvar dados: \(error.localizedDescription)"
                completion?(false)
                return
            }
            
            self.currentUser = user
            self.isAuthenticated = true
            completion?(true)
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
        
        // Primeiro exclui o documento do Firestore
        firestore.collection("users").document(userId).delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = "Erro ao excluir dados: \(error.localizedDescription)"
                completion(false, self.error)
                return
            }
            
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
        }
    }
} 