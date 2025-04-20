import Foundation
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
    
    // MARK: - Operações com Idiomas
    
    func fetchIdiomas(completion: @escaping ([Idioma]?, Error?) -> Void) {
        fetchIdiomas(forceRefresh: false, completion: completion)
    }
    
    func fetchIdiomas(forceRefresh: Bool, completion: @escaping ([Idioma]?, Error?) -> Void) {
        print("📑 [LOG] Iniciando consulta de idiomas no Firestore...")
        
        // Verificar se a configuração está correta
        guard let projectID = db.app.options.projectID, !projectID.isEmpty else {
            print("❌ [LOG] Erro: Configuração do Firebase inválida")
            completion(nil, NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Configuração do Firebase inválida"]))
            return
        }
        
        // Configurar a consulta - usar getDocuments(source:) para forçar atualização se necessário
        let source: FirestoreSource = forceRefresh ? .server : .default
        print("🔍 [LOG] Consultando coleção 'idiomas' (forceRefresh: \(forceRefresh))")
        
        // Tentar buscar documentos na coleção 'idiomas'
        db.collection("idiomas").getDocuments(source: source) { snapshot, error in
            if let error = error {
                print("❌ [LOG] Erro ao buscar idiomas: \(error.localizedDescription)")
                completion([], error)
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ [LOG] Snapshot nulo recebido na consulta de idiomas")
                completion([], nil)
                return
            }
            
            if snapshot.documents.isEmpty {
                print("⚠️ [LOG] Coleção 'idiomas' vazia")
                completion([], nil)
                return
            }
            
            print("📊 [LOG] Documentos encontrados na coleção 'idiomas': \(snapshot.documents.count)")
            
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
                    
                    print("🔤 [LOG] Idioma encontrado: \(nome) (ativo: \(ativo))")
                    return idioma
                } catch {
                    print("❌ [LOG] Erro ao converter documento \(document.documentID): \(error)")
                    return nil
                }
            }
            
            print("✅ [LOG] Total de idiomas carregados: \(idiomas.count)")
            completion(idiomas, nil)
        }
    }
    
    // MARK: - Operações com Cards
    
    func fetchCards(completion: @escaping ([Card]?, Error?) -> Void) {
        fetchCards(forceRefresh: false, completion: completion)
    }
    
    func fetchCards(forceRefresh: Bool, completion: @escaping ([Card]?, Error?) -> Void) {
        // Verificar se a configuração está correta
        guard let projectID = db.app.options.projectID, !projectID.isEmpty else {
            print("Erro: Configuração do Firebase inválida")
            completion(nil, NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Configuração do Firebase inválida"]))
            return
        }
        
        // Configurar a consulta - usar getDocuments(source:) para forçar atualização se necessário
        let source: FirestoreSource = forceRefresh ? .server : .default
        
        // Tentar buscar documentos na coleção 'cartoes'
        db.collection("cartoes").getDocuments(source: source) { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Erro ao buscar cards: \(error.localizedDescription)")
                completion([], error)
                return
            }
            
            guard let snapshot = snapshot else {
                completion([], nil)
                return
            }
            
            if snapshot.documents.isEmpty {
                completion([], nil)
                return
            }
            
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
                    return nil
                }
            }
            
            completion(cards, nil)
        }
    }
    
    // MARK: - Operações com Decks
    
    func getDecksFromFirestore(completion: @escaping ([Deck]?, Error?) -> Void) {
        getDecksFromFirestore(forceRefresh: false, completion: completion)
    }
    
    func getDecksFromFirestore(forceRefresh: Bool, completion: @escaping ([Deck]?, Error?) -> Void) {
        fetchCards(forceRefresh: forceRefresh) { cards, error in
            if let error = error {
                print("Erro ao buscar cards para criar decks: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let cards = cards, !cards.isEmpty else {
                completion([], nil)
                return
            }
            
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
            
            completion(decks, nil)
        }
    }
} 
