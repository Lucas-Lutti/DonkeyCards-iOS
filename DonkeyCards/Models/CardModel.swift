import Foundation

struct Card: Identifiable, Codable {
    var id: String?
    let palavra: String
    let resposta: String
    let idioma: String
    let tema: String
    var dataCriacao: Date = Date()
    
    // ID persistente para acompanhamento
    var storageId: String {
        "\(idioma)_\(tema)_\(palavra)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, palavra, resposta, idioma, tema, dataCriacao
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        palavra = try container.decode(String.self, forKey: .palavra)
        resposta = try container.decode(String.self, forKey: .resposta)
        idioma = try container.decode(String.self, forKey: .idioma)
        tema = try container.decode(String.self, forKey: .tema)
        // Tratamento especial para a data, permitindo diferentes formatos ou ausência
        if let timestamp = try? container.decode(Double.self, forKey: .dataCriacao) {
            dataCriacao = Date(timeIntervalSince1970: timestamp)
        } else if let dateString = try? container.decode(String.self, forKey: .dataCriacao),
                  let date = ISO8601DateFormatter().date(from: dateString) {
            dataCriacao = date
        } else {
            dataCriacao = try container.decodeIfPresent(Date.self, forKey: .dataCriacao) ?? Date()
        }
    }
    
    init(id: String? = nil, palavra: String, resposta: String, idioma: String, tema: String, dataCriacao: Date = Date()) {
        self.id = id
        self.palavra = palavra
        self.resposta = resposta
        self.idioma = idioma
        self.tema = tema
        self.dataCriacao = dataCriacao
    }
} 
