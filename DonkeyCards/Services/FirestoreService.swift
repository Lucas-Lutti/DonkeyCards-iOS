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
        
        print("🔥 Firestore inicializado com projeto: \(db.app.options.projectID ?? "Desconhecido")")
    }
    
    // MARK: - Operações com Cards
    
    func fetchCards(completion: @escaping ([Card]?, Error?) -> Void) {
        fetchCards(forceRefresh: false, completion: completion)
    }
    
    func fetchCards(forceRefresh: Bool, completion: @escaping ([Card]?, Error?) -> Void) {
        print("🔥 Iniciando busca de cards no Firestore...")
        
        // Verificar se a configuração está correta
        guard let projectID = db.app.options.projectID, !projectID.isEmpty else {
            print("🔥❌ ERRO: Configuração do Firebase inválida. ProjectID ausente.")
            completion(nil, NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Configuração do Firebase inválida"]))
            return
        }
        
        print("🔥 Tentando acessar a coleção 'cartoes' no projeto \(projectID)")
        
        // Configurar a consulta - usar getDocuments(source:) para forçar atualização se necessário
        let source: FirestoreSource = forceRefresh ? .server : .default
        
        // Tentar buscar documentos na coleção 'cartoes'
        db.collection("cartoes").getDocuments(source: source) { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("🔥❌ ERRO ao buscar cards: \(error.localizedDescription)")
                print("🔥 Detalhes do erro: \(String(describing: error))")
                
                // Tentar criar a coleção se ela não existir
                print("🔥 A coleção pode não existir, verificando outras alternativas...")
                completion([], error)
                return
            }
            
            guard let snapshot = snapshot else {
                print("🔥❌ ERRO: Snapshot é nil, mas nenhum erro foi reportado")
                completion([], nil)
                return
            }
            
            print("🔥 Conexão com Firestore bem-sucedida")
            print("🔥 Documentos encontrados no Firestore: \(snapshot.documents.count)")
            
            if snapshot.documents.isEmpty {
                print("🔥⚠️ Coleção 'cartoes' existe mas está vazia")
                completion([], nil)
                return
            }
            
            // Para fins de depuração, vamos mostrar os IDs dos documentos
            print("🔥 IDs dos documentos encontrados: \(snapshot.documents.map { $0.documentID }.joined(separator: ", "))")
            
            // Para fins de depuração, vamos mostrar os dados brutos do primeiro documento
            if let firstDoc = snapshot.documents.first {
                print("🔥 Amostra de dados do primeiro documento (\(firstDoc.documentID)):")
                print(firstDoc.data())
            }
            
            let cards = snapshot.documents.compactMap { document -> Card? in
                do {
                    // Usar o método de conversão manual em vez do data(as:)
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
                    
                    print("🔥 Card carregado com sucesso: \(card.palavra) (\(card.idioma) - \(card.tema))")
                    return card
                } catch {
                    print("🔥❌ ERRO ao converter documento \(document.documentID):")
                    print("🔥 Dados brutos: \(document.data())")
                    print("🔥 Erro: \(error)")
                    
                    // Vamos tentar uma conversão manual para debug
                    let data = document.data()
                    print("🔥 Tentando conversão manual:")
                    print("🔥 - palavra: \(data["palavra"] as? String ?? "ausente")")
                    print("🔥 - resposta: \(data["resposta"] as? String ?? "ausente")")
                    print("🔥 - idioma: \(data["idioma"] as? String ?? "ausente")")
                    print("🔥 - tema: \(data["tema"] as? String ?? "ausente")")
                    
                    return nil
                }
            }
            
            print("🔥 Total de cards carregados com sucesso: \(cards.count) de \(snapshot.documents.count) documentos")
            completion(cards, nil)
        }
    }
    
    // MARK: - Operações com Decks
    
    func getDecksFromFirestore(completion: @escaping ([Deck]?, Error?) -> Void) {
        getDecksFromFirestore(forceRefresh: false, completion: completion)
    }
    
    func getDecksFromFirestore(forceRefresh: Bool, completion: @escaping ([Deck]?, Error?) -> Void) {
        print("🔥 Iniciando busca de decks do Firestore...")
        
        fetchCards(forceRefresh: forceRefresh) { cards, error in
            if let error = error {
                print("🔥❌ ERRO ao buscar cards para criar decks: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let cards = cards, !cards.isEmpty else {
                print("🔥⚠️ Nenhum card encontrado para criar decks")
                completion([], nil)
                return
            }
            
            print("🔥 Criando decks a partir de \(cards.count) cards")
            
            let idiomas = Set(cards.map { $0.idioma })
            print("🔥 Idiomas encontrados: \(idiomas)")
            
            var decks: [Deck] = []
            
            for idioma in idiomas {
                let idiomaCards = cards.filter { $0.idioma == idioma }
                let temas = Set(idiomaCards.map { $0.tema })
                print("🔥 Temas para idioma \(idioma): \(temas)")
                
                for tema in temas {
                    let temaCards = idiomaCards.filter { $0.tema == tema }
                    let deckName = "\(tema) (\(idioma))"
                    let deck = Deck(nome: deckName, idioma: idioma, tema: tema, cards: temaCards)
                    print("🔥 Criado deck: \(deckName) com \(temaCards.count) cards")
                    decks.append(deck)
                }
                
                // Também adiciona um deck com todos os cards do idioma
                let allDeck = Deck(nome: "Todos (\(idioma))", idioma: idioma, tema: "Todos", cards: idiomaCards)
                print("🔥 Criado deck consolidado: Todos (\(idioma)) com \(idiomaCards.count) cards")
                decks.append(allDeck)
            }
            
            print("🔥 Total de \(decks.count) decks criados com sucesso")
            completion(decks, nil)
        }
    }
} 
