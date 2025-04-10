import Foundation

struct Deck: Identifiable, Codable {
    var id = UUID()
    let nome: String
    let idioma: String
    let tema: String
    var cards: [Card]
    
    // ID único para persistência de progresso
    var storageId: String {
        "\(idioma)_\(tema)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, nome, idioma, tema, cards
    }
    
    init(nome: String, idioma: String, tema: String, cards: [Card] = []) {
        self.nome = nome
        self.idioma = idioma
        self.tema = tema
        self.cards = cards
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nome = try container.decode(String.self, forKey: .nome)
        idioma = try container.decode(String.self, forKey: .idioma)
        tema = try container.decode(String.self, forKey: .tema)
        cards = try container.decode([Card].self, forKey: .cards)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nome, forKey: .nome)
        try container.encode(idioma, forKey: .idioma)
        try container.encode(tema, forKey: .tema)
        try container.encode(cards, forKey: .cards)
    }
} 