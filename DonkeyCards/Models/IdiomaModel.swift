import Foundation

struct Idioma: Identifiable, Codable {
    var id: String?
    let nome: String
    var ativo: Bool
    var dataCriacao: Date
    
    // ID persistente para acompanhamento
    var storageId: String {
        nome.lowercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, nome, ativo, dataCriacao
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        nome = try container.decode(String.self, forKey: .nome)
        ativo = try container.decode(Bool.self, forKey: .ativo)
        
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
    
    init(id: String? = nil, nome: String, ativo: Bool = true, dataCriacao: Date = Date()) {
        self.id = id
        self.nome = nome
        self.ativo = ativo
        self.dataCriacao = dataCriacao
    }
} 