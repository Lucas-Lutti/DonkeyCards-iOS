import Foundation
import Firebase
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {
        // Configurações para melhorar a performance e diagnóstico
        let settings = db.settings
        // Garantir cache adequado e persistência
        settings.isPersistenceEnabled = true
        // Usar o valor máximo para cache - 100MB
        settings.cacheSizeBytes = 104857600
        db.settings = settings
    }
    
    // MARK: - User Management
    
    func createUser(user: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = user.id else {
            completion(.failure(NSError(domain: "FirestoreService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID do usuário não encontrado"])))
            return
        }
        
        // Convertendo manualmente o UserModel para um dicionário
        let userData: [String: Any] = [
            "username": user.username,
            "profileImageURL": user.profileImageURL as Any,
            "gold": user.gold,
            "isFull": user.isFull,
            "settings": user.settings
        ]
        
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getUser(userId: String, completion: @escaping (Result<UserModel?, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.success(nil))
                return
            }
            
            // Convertendo manualmente o documento para UserModel
            let data = document.data() ?? [:]
            let username = data["username"] as? String ?? ""
            let profileImageURL = data["profileImageURL"] as? String
            let gold = data["gold"] as? Int ?? 0
            let isFull = data["isFull"] as? Bool ?? false
            let settings = data["settings"] as? [String: Bool] ?? [:]
            
            let user = UserModel(
                id: userId,
                username: username,
                profileImageURL: profileImageURL,
                gold: gold,
                isFull: isFull
            )
            
            // Adicionar settings manualmente
            var userWithSettings = user
            userWithSettings.settings = settings
            
            completion(.success(userWithSettings))
        }
    }
    
    func updateUser(user: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = user.id else {
            completion(.failure(NSError(domain: "FirestoreService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID do usuário não encontrado"])))
            return
        }
        
        // Convertendo manualmente o UserModel para um dicionário
        let userData: [String: Any] = [
            "username": user.username,
            "profileImageURL": user.profileImageURL as Any,
            "gold": user.gold,
            "isFull": user.isFull,
            "settings": user.settings
        ]
        
        db.collection("users").document(userId).setData(userData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteUser(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Deck Management
    
    func saveDeck(userId: String, deck: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        let deckRef = db.collection("users").document(userId).collection("decks").document()
        
        var deckData = deck
        deckData["id"] = deckRef.documentID
        deckData["createdAt"] = FieldValue.serverTimestamp()
        
        deckRef.setData(deckData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(deckRef.documentID))
            }
        }
    }
    
    func getDecks(userId: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("users").document(userId).collection("decks")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let decks = documents.compactMap { document -> [String: Any]? in
                    var deck = document.data()
                    deck["id"] = document.documentID
                    return deck
                }
                
                completion(.success(decks))
            }
    }
    
    func deleteDeck(userId: String, deckId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("decks").document(deckId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Card Management
    
    func getCards(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("cards").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let cards = documents.compactMap { document -> [String: Any]? in
                var card = document.data()
                card["id"] = document.documentID
                return card
            }
            
            completion(.success(cards))
        }
    }
    
    // MARK: - Operações com Idiomas
    
    func fetchIdiomas(completion: @escaping ([Idioma]?, Error?) -> Void) {
        fetchIdiomas(forceRefresh: false, completion: completion)
    }
    
    func fetchIdiomas(forceRefresh: Bool, completion: @escaping ([Idioma]?, Error?) -> Void) {
        print("🔥 [FIREBASE] Iniciando consulta de idiomas no Firestore...")
        
        // Verificar se a configuração está correta
        guard let projectID = db.app.options.projectID, !projectID.isEmpty else {
            print("❌ [FIREBASE] Erro: Configuração do Firebase inválida")
            completion(nil, NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Configuração do Firebase inválida"]))
            return
        }
        
        // Configurar a consulta - usar getDocuments(source:) para forçar atualização se necessário
        let source: FirestoreSource = forceRefresh ? .server : .default
        print("🔥 [FIREBASE] Consultando coleção 'idiomas' (forceRefresh: \(forceRefresh))")
        
        // Tentar buscar documentos na coleção 'idiomas'
        db.collection("idiomas").getDocuments(source: source) { snapshot, error in
            if let error = error {
                print("❌ [FIREBASE] Erro ao buscar idiomas: \(error.localizedDescription)")
                completion([], error)
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ [FIREBASE] Snapshot nulo recebido na consulta de idiomas")
                completion([], nil)
                return
            }
            
            if snapshot.documents.isEmpty {
                print("⚠️ [FIREBASE] Coleção 'idiomas' vazia")
                completion([], nil)
                return
            }
            
            print("🔥 [FIREBASE] Documentos encontrados na coleção 'idiomas': \(snapshot.documents.count)")
            
            let idiomas = snapshot.documents.compactMap { document -> Idioma? in
                do {
                    // Usar o método de conversão manual
                    let data = document.data()
                    guard let nome = data["nome"] as? String,
                          let ativo = data["ativo"] as? Bool else {
                        throw NSError(domain: "FirestoreService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dados inválidos ou incompletos"])
                    }
                    
                    var dataCriacao: Date = Date()
                    if let timestamp = data["dataCriacao"] as? Timestamp {
                        dataCriacao = timestamp.dateValue()
                    }
                    
                    let idioma = Idioma(id: document.documentID, 
                                      nome: nome, 
                                      ativo: ativo, 
                                      dataCriacao: dataCriacao)
                    
                    print("🔥 [FIREBASE] Idioma encontrado: \(nome) (ativo: \(ativo))")
                    return idioma
                } catch {
                    print("❌ [FIREBASE] Erro ao converter documento \(document.documentID): \(error)")
                    return nil
                }
            }
            
            print("✅ [FIREBASE] Total de idiomas carregados: \(idiomas.count)")
            completion(idiomas, nil)
        }
    }
    
    // MARK: - Operações com Cards
    
    func fetchCards(completion: @escaping ([Card]?, Error?) -> Void) {
        fetchCards(forceRefresh: false, completion: completion)
    }
    
    func fetchCards(forceRefresh: Bool, completion: @escaping ([Card]?, Error?) -> Void) {
        print("🔥 [FIREBASE] Iniciando busca de cards...")
        
        let source: FirestoreSource = forceRefresh ? .server : .default
        db.collection("cartoes").getDocuments(source: source) { snapshot, error in
            if let error = error {
                print("❌ [FIREBASE] Erro ao buscar cards: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ [FIREBASE] Snapshot nulo recebido na consulta de cards")
                completion(nil, nil)
                return
            }
            
            print("🔥 [FIREBASE] Processando \(snapshot.documents.count) cards do Firestore")
            
            let cards = snapshot.documents.compactMap { document -> Card? in
                do {
                    // Usar o método de conversão manual
                    let data = document.data()
                    guard let palavra = data["palavra"] as? String,
                          let resposta = data["resposta"] as? String,
                          let idioma = data["idioma"] as? String,
                          let tema = data["tema"] as? String else {
                        throw NSError(domain: "FirestoreService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dados inválidos ou incompletos"])
                    }
                    
                    let card = Card(id: document.documentID, 
                                    palavra: palavra, 
                                    resposta: resposta, 
                                    idioma: idioma, 
                                    tema: tema)
                    
                    return card
                } catch {
                    print("❌ [FIREBASE] Erro ao converter card: \(error)")
                    return nil
                }
            }
            
            print("✅ [FIREBASE] Total de cards carregados: \(cards.count)")
            completion(cards, nil)
        }
    }
    
    // MARK: - Operações com Decks
    
    func getDecksFromFirestore(completion: @escaping ([Deck]?, Error?) -> Void) {
        getDecksFromFirestore(forceRefresh: false, completion: completion)
    }
    
    func getDecksFromFirestore(forceRefresh: Bool, completion: @escaping ([Deck]?, Error?) -> Void) {
        print("🔥 [FIREBASE] Iniciando busca de decks...")
        fetchCards(forceRefresh: forceRefresh) { cards, error in
            if let error = error {
                print("❌ [FIREBASE] Erro ao buscar cards para criar decks: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let cards = cards, !cards.isEmpty else {
                print("⚠️ [FIREBASE] Nenhum card encontrado para criar decks")
                completion([], nil)
                return
            }
            
            print("🔥 [FIREBASE] Criando decks a partir de \(cards.count) cards")
            
            let idiomas = Set(cards.map { $0.idioma })
            var decks: [Deck] = []
            
            for idioma in idiomas {
                let idiomaCards = cards.filter { $0.idioma == idioma }
                let temas = Set(idiomaCards.map { $0.tema })
                
                for tema in temas {
                    let temaCards = idiomaCards.filter { $0.tema == tema }
                    let deckName = "\(tema) (\(idioma))"
                    let deck = Deck(nome: deckName, idioma: idioma, tema: tema, cards: temaCards)
                    decks.append(deck)
                }
                
                // Também adiciona um deck com todos os cards do idioma
                let allDeck = Deck(nome: "Todos (\(idioma))", idioma: idioma, tema: "Todos", cards: idiomaCards)
                decks.append(allDeck)
            }
            
            print("✅ [FIREBASE] Total de decks criados: \(decks.count)")
            completion(decks, nil)
        }
    }
} 
