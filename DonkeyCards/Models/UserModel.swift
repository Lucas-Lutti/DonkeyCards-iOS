import Foundation

struct UserModel: Identifiable, Codable {
    var id: String?
    var username: String
    var profileImageURL: String?
    var gold: Int
    var isFull: Bool
    
    // Campo para controlar configurações do usuário
    var settings: [String: Bool] = [:]
    
    // Construtor padrão
    init(id: String? = nil, username: String, profileImageURL: String? = nil, gold: Int = 0, isFull: Bool = false) {
        self.id = id
        self.username = username
        self.profileImageURL = profileImageURL
        self.gold = gold
        self.isFull = isFull
    }
} 
