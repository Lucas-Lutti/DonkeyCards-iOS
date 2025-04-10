import Foundation

class DataService {
    static let shared = DataService()
    private let defaults = UserDefaults.standard
    private let lastUpdateKey = "lastFirestoreUpdate"
    private let cachedDecksKey = "cachedDecks"
    private let updateInterval: TimeInterval = 6 * 3600 // 6 horas em segundos
    
    private init() {}
    
    // Verifica se é necessário atualizar os dados
    private func shouldUpdate() -> Bool {
        if let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            return timeSinceLastUpdate >= updateInterval
        }
        return true // Se nunca atualizou, deve atualizar
    }
    
    // Salva os decks no cache local
    private func saveDecksToCache(_ decks: [Deck]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(decks)
            defaults.set(data, forKey: cachedDecksKey)
            defaults.set(Date(), forKey: lastUpdateKey)
        } catch {
            print("Erro ao salvar decks no cache: \(error)")
        }
    }
    
    // Carrega os decks do cache local
    private func loadDecksFromCache() -> [Deck]? {
        guard let data = defaults.data(forKey: cachedDecksKey) else { return nil }
        do {
            let decoder = JSONDecoder()
            let decks = try decoder.decode([Deck].self, from: data)
            return decks
        } catch {
            print("Erro ao carregar decks do cache: \(error)")
            return nil
        }
    }
    
    // Retorna o tempo restante até a próxima atualização permitida
    func timeUntilNextUpdate() -> TimeInterval? {
        guard let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date else {
            return nil
        }
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        let remainingTime = updateInterval - timeSinceLastUpdate
        return remainingTime > 0 ? remainingTime : 0
    }
    
    // Método legado que carrega os cards do arquivo JSON local
    // Mantido apenas para referência e possível uso futuro
    private func loadCardsFromJson() -> [Card] {
        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Não foi possível encontrar ou carregar o arquivo cards.json")
            return []
        }
        
        do {
            let cards = try JSONDecoder().decode([Card].self, from: data)
            return cards
        } catch {
            print("Erro ao decodificar cards.json: \(error)")
            return []
        }
    }
    
    // Carrega os cards exclusivamente do Firestore
    func loadCards(completion: @escaping ([Card]) -> Void) {
        loadCards(forceRefresh: false, completion: completion)
    }
    
    func loadCards(forceRefresh: Bool, completion: @escaping ([Card]) -> Void) {
        FirestoreService.shared.fetchCards(forceRefresh: forceRefresh) { cards, error in
            if let error = error {
                print("Erro ao buscar cards no Firestore: \(error)")
                completion([])
                return
            }
            
            completion(cards ?? [])
        }
    }
    
    // Método atualizado para usar exclusivamente o Firestore
    func getDecks(completion: @escaping ([Deck]) -> Void) {
        getDecks(forceRefresh: false, completion: completion)
    }
    
    func getDecks(forceRefresh: Bool, completion: @escaping ([Deck]) -> Void) {
        // Se não for forceRefresh e tiver cache, usa o cache
        if !forceRefresh, let cachedDecks = loadDecksFromCache() {
            completion(cachedDecks)
            // Se não precisar atualizar, retorna
            if !shouldUpdate() {
                return
            }
        }
        
        // Se for primeira vez ou precisar atualizar, busca do Firestore
        FirestoreService.shared.getDecksFromFirestore(forceRefresh: forceRefresh) { [weak self] decks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Erro ao buscar decks no Firestore: \(error)")
                // Se tiver cache, usa como fallback
                if let cachedDecks = self.loadDecksFromCache() {
                    completion(cachedDecks)
                } else {
                    completion([])
                }
                return
            }
            
            if let decks = decks {
                // Salva no cache
                self.saveDecksToCache(decks)
                completion(decks)
            } else {
                // Se tiver cache, usa como fallback
                if let cachedDecks = self.loadDecksFromCache() {
                    completion(cachedDecks)
                } else {
                    completion([])
                }
            }
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