import Foundation
import FirebaseFirestore

class DataService {
    static let shared = DataService()
    private let defaults = UserDefaults.standard
    private let lastUpdateKey = "lastFirestoreUpdate"
    private let cachedIdiomasKey = "cachedIdiomas"
    private let updateInterval: TimeInterval = 6 * 3600 // 6 horas em segundos
    
    // Controle de atualização de dados
    private var lastUpdateTimestamp: Date?
    private let minUpdateInterval: TimeInterval = 60 * 10 // 10 minutos
    
    // Armazenamento local dos dados
    private var cachedDecks: [Deck] = []
    private var cachedIdiomas: [Idioma] = []
    
    // Chaves para armazenamento de cards por idioma
    private func cardsCacheKey(forLanguage language: String) -> String {
        return "cached_cards_\(language)"
    }
    
    private init() {
        // Carrega dados do UserDefaults ao inicializar
        loadCachedDataFromDefaults()
    }
    
    private func loadCachedDataFromDefaults() {
        // Carrega idiomas salvos
        if let idiomasData = defaults.data(forKey: cachedIdiomasKey) {
            do {
                let decoder = JSONDecoder()
                let idiomas = try decoder.decode([Idioma].self, from: idiomasData)
                self.cachedIdiomas = idiomas
                print("📱 [LOG] Idiomas carregados do cache local: \(idiomas.count)")
            } catch {
                print("❌ [LOG] Erro ao decodificar idiomas do cache: \(error)")
            }
        }
        
        // Carrega o timestamp da última atualização
        if let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date {
            self.lastUpdateTimestamp = lastUpdate
            print("📱 [LOG] Última atualização: \(lastUpdate)")
        }
    }
    
    // Verifica se é necessário atualizar os dados
    private func shouldUpdate() -> Bool {
        if let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            return timeSinceLastUpdate >= updateInterval
        }
        return true // Se nunca atualizou, deve atualizar
    }
    
    // Salva os idiomas no cache local
    private func saveIdiomasToCache(_ idiomas: [Idioma]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(idiomas)
            defaults.set(data, forKey: cachedIdiomasKey)
            defaults.set(Date(), forKey: lastUpdateKey)
            print("📱 [LOG] Idiomas salvos no cache local: \(idiomas.count)")
        } catch {
            print("❌ [LOG] Erro ao salvar idiomas no cache: \(error)")
        }
    }
    
    // Salva os cards por idioma no cache local
    private func saveCardsToCache(cards: [Card], forLanguage language: String) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cards)
            let key = cardsCacheKey(forLanguage: language)
            defaults.set(data, forKey: key)
            defaults.set(Date(), forKey: lastUpdateKey)
            print("📱 [LOG] Cards do idioma \(language) salvos no cache local: \(cards.count)")
        } catch {
            print("❌ [LOG] Erro ao salvar cards no cache: \(error)")
        }
    }
    
    // Carrega os cards de um idioma específico do cache local
    private func loadCardsFromCache(forLanguage language: String) -> [Card]? {
        let key = cardsCacheKey(forLanguage: language)
        guard let data = defaults.data(forKey: key) else { 
            print("📱 [LOG] Nenhum dado de cards para idioma \(language) encontrado no cache")
            return nil 
        }
        
        do {
            let decoder = JSONDecoder()
            let cards = try decoder.decode([Card].self, from: data)
            print("📱 [LOG] Cards carregados do cache local para idioma \(language): \(cards.count)")
            return cards
        } catch {
            print("❌ [LOG] Erro ao carregar cards do cache: \(error)")
            return nil
        }
    }
    
    // MARK: - Controle de Atualização
    
    private func canUpdateNow() -> Bool {
        guard let lastUpdate = lastUpdateTimestamp else {
            return true // Se nunca atualizou, pode atualizar
        }
        
        let elapsed = Date().timeIntervalSince(lastUpdate)
        return elapsed >= minUpdateInterval
    }
    
    func timeUntilNextUpdate() -> TimeInterval? {
        guard let lastUpdate = lastUpdateTimestamp else {
            return 0 // Pode atualizar imediatamente
        }
        
        let elapsed = Date().timeIntervalSince(lastUpdate)
        let remaining = minUpdateInterval - elapsed
        
        return remaining > 0 ? remaining : 0
    }
    
    // MARK: - Gerenciamento de Idiomas
    
    func getIdiomas(completion: @escaping ([Idioma]) -> Void) {
        getIdiomas(forceRefresh: false, completion: completion)
    }
    
    func getIdiomas(forceRefresh: Bool, completion: @escaping ([Idioma]) -> Void) {
        // Se já tivermos dados em cache e não estamos forçando atualização, retorne-os
        if !cachedIdiomas.isEmpty && !forceRefresh {
            print("🔄 [LOG] Usando idiomas em cache: \(cachedIdiomas.count) idiomas")
            completion(cachedIdiomas)
            return
        }
        
        // Verifica se já atualizou recentemente
        if !canUpdateNow() && !forceRefresh {
            // Se temos cache, use-o
            if !cachedIdiomas.isEmpty {
                print("🔄 [LOG] Usando idiomas em cache (atualização recente): \(cachedIdiomas.count) idiomas")
                completion(cachedIdiomas)
                return
            }
        }
        
        print("🔍 [LOG] Consultando idiomas no Firebase...")
        
        // Busca novos dados do Firestore
        FirestoreService.shared.fetchIdiomas(forceRefresh: forceRefresh) { [weak self] idiomas, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [LOG] Erro ao buscar idiomas: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let idiomas = idiomas {
                // Armazena no cache
                self.cachedIdiomas = idiomas
                // Salva no UserDefaults
                self.saveIdiomasToCache(idiomas)
                // Atualiza o timestamp
                self.lastUpdateTimestamp = Date()
                defaults.set(Date(), forKey: self.lastUpdateKey)
                
                // Filtra apenas idiomas ativos
                let idiomasAtivos = idiomas.filter { $0.ativo }
                print("✅ [LOG] Idiomas carregados do Firebase: \(idiomasAtivos.count) ativos de \(idiomas.count) total")
                
                completion(idiomasAtivos)
            } else {
                print("⚠️ [LOG] Nenhum idioma recebido do Firestore")
                completion([])
            }
        }
    }
    
    // MARK: - Gerenciamento de Decks
    
    func getDecks(completion: @escaping ([Deck]) -> Void) {
        getDecks(forceRefresh: false, completion: completion)
    }
    
    func getDecks(forceRefresh: Bool, completion: @escaping ([Deck]) -> Void) {
        // Se já tivermos dados em cache e não estamos forçando atualização, retorne-os
        if !cachedDecks.isEmpty && !forceRefresh {
            completion(cachedDecks)
            return
        }
        
        // Verifica se já atualizou recentemente
        if !canUpdateNow() && !forceRefresh {
            // Se temos cache, use-o
            if !cachedDecks.isEmpty {
                completion(cachedDecks)
                return
            }
        }
        
        // Busca novos dados do Firestore
        FirestoreService.shared.getDecksFromFirestore(forceRefresh: forceRefresh) { [weak self] decks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("⚠️ Erro ao buscar decks: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let decks = decks {
                // Armazena no cache
                self.cachedDecks = decks
                // Atualiza o timestamp
                self.lastUpdateTimestamp = Date()
                
                completion(decks)
            } else {
                print("⚠️ Nenhum deck recebido do Firestore")
                completion([])
            }
        }
    }
    
    // MARK: - Obtenção de Decks por Idioma
    
    func getDecksForLanguage(_ language: String, completion: @escaping ([Deck]) -> Void) {
        // Verifica se já temos os decks deste idioma no cache de memória
        let cachedLanguageDecks = cachedDecks.filter { $0.idioma == language }
        if !cachedLanguageDecks.isEmpty {
            print("🔄 [LOG] Usando decks em cache de memória para idioma \(language): \(cachedLanguageDecks.count) decks")
            completion(cachedLanguageDecks)
            return
        }
        
        // Tenta carregar do cache local (UserDefaults)
        if let cachedCards = loadCardsFromCache(forLanguage: language) {
            // Cria decks a partir dos cards em cache
            let decks = createDecksFromCards(cachedCards)
            
            // Atualiza o cache de memória
            let existingDecks = self.cachedDecks.filter { $0.idioma != language }
            self.cachedDecks = existingDecks + decks
            
            print("🔄 [LOG] Usando cards do cache local para idioma \(language): \(decks.count) decks")
            completion(decks)
            
            // Se não precisamos atualizar agora, usa apenas o cache
            if !shouldUpdate() && !cachedCards.isEmpty {
                return
            }
            
            // Se chegou aqui, vamos fazer uma atualização em segundo plano
            print("🔄 [LOG] Atualizando cards em segundo plano para idioma \(language)")
            fetchCardsFromFirebase(forLanguage: language) { _ in 
                // Atualização silenciosa concluída
            }
            
            return
        }
        
        // Se não temos cache, buscamos do Firebase
        fetchCardsFromFirebase(forLanguage: language, completion: completion)
    }
    
    private func fetchCardsFromFirebase(forLanguage language: String, completion: @escaping ([Deck]) -> Void) {
        print("🔍 [LOG] Consultando cards para idioma \(language) no Firebase...")
        
        // Consulta Firebase apenas para cards do idioma específico
        let db = Firestore.firestore()
        db.collection("cartoes")
            .whereField("idioma", isEqualTo: language)
            .getDocuments { [weak self] snapshot, error in
                
            guard let self = self else { return }
                
            if let error = error {
                print("❌ [LOG] Erro ao buscar cards: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ [LOG] Snapshot vazio ao buscar cards para idioma \(language)")
                completion([])
                return
            }
            
            print("📋 [LOG] Cards encontrados para idioma \(language): \(snapshot.documents.count)")
            
            let cards = snapshot.documents.compactMap { document -> Card? in
                do {
                    // Usar o método de conversão manual
                    let data = document.data()
                    guard let palavra = data["palavra"] as? String,
                          let resposta = data["resposta"] as? String,
                          let idioma = data["idioma"] as? String,
                          let tema = data["tema"] as? String else {
                        return nil
                    }
                    
                    let card = Card(id: document.documentID, 
                                    palavra: palavra, 
                                    resposta: resposta, 
                                    idioma: idioma, 
                                    tema: tema)
                    
                    return card
                } catch {
                    print("❌ [LOG] Erro ao converter documento: \(error)")
                    return nil
                }
            }
            
            print("🃏 [LOG] Cards convertidos com sucesso: \(cards.count) de \(snapshot.documents.count)")
            
            // Salva os cards no cache local
            self.saveCardsToCache(cards: cards, forLanguage: language)
            
            // Cria os decks a partir dos cards
            let decks = self.createDecksFromCards(cards)
            
            // Atualiza o cache apenas para os decks deste idioma
            // Primeiro remove os decks existentes deste idioma
            self.cachedDecks.removeAll(where: { $0.idioma == language })
            // Depois adiciona os novos
            self.cachedDecks.append(contentsOf: decks)
            
            print("✅ [LOG] Decks criados para idioma \(language): \(decks.count) decks")
            completion(decks)
        }
    }
    
    // Método auxiliar para criar decks a partir de cards
    private func createDecksFromCards(_ cards: [Card]) -> [Deck] {
        let idiomas = Set(cards.map { $0.idioma })
        var decks: [Deck] = []
        
        for idioma in idiomas {
            let idiomaCards = cards.filter { $0.idioma == idioma }
            let temas = Set(idiomaCards.map { $0.tema })
            
            for tema in temas {
                let temaCards = idiomaCards.filter { $0.tema == tema }
                let deck = Deck(nome: "\(tema) (\(idioma))", idioma: idioma, tema: tema, cards: temaCards)
                decks.append(deck)
            }
            
            // Também adiciona um deck com todos os cards do idioma
            let allDeck = Deck(nome: "Todos (\(idioma))", idioma: idioma, tema: "Todos", cards: idiomaCards)
            decks.append(allDeck)
        }
        
        return decks
    }
} 