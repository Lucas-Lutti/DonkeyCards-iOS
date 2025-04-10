import Foundation

// Modelo para armazenar o progresso de um deck
struct DeckProgress: Codable, Identifiable {
    let id: String  // Mesmo ID do deck (storageId)
    var cardsRespondidas: [String: Bool]  // [cardID: acertou/errou]
    var totalAcertos: Int
    var totalErros: Int
    var concluido: Bool
    var dataConclusao: Date?  // Data de conclusão do deck
    var ultimaInteracao: Date
    var ultimoCardIndex: Int  // Índice do último cartão visualizado
    
    // Inicializador para novo progresso
    init(deckId: String) {
        self.id = deckId
        self.cardsRespondidas = [:]
        self.totalAcertos = 0
        self.totalErros = 0
        self.concluido = false
        self.dataConclusao = nil
        self.ultimaInteracao = Date()
        self.ultimoCardIndex = 0
    }
    
    // Métodos auxiliares
    mutating func registrarResposta(cardId: String, acertou: Bool) {
        cardsRespondidas[cardId] = acertou
        if acertou {
            totalAcertos += 1
        } else {
            totalErros += 1
        }
        ultimaInteracao = Date()
    }
    
    mutating func atualizarUltimoCard(index: Int) {
        ultimoCardIndex = index
        ultimaInteracao = Date()
    }
    
    mutating func marcarComoConcluido() {
        concluido = true
        if dataConclusao == nil {
            dataConclusao = Date()
        }
    }
    
    var totalRespondidas: Int {
        return cardsRespondidas.count
    }
    
    var percentualAcertos: Double {
        guard totalRespondidas > 0 else { return 0.0 }
        return Double(totalAcertos) / Double(totalRespondidas) * 100.0
    }
    
    // Formata a data de conclusão para exibição
    func formatarDataConclusao() -> String {
        guard let data = dataConclusao else { return "Não concluído" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: data)
    }
    
    // Retorna há quanto tempo o deck foi concluído
    func tempoDesdeConclusao() -> String {
        guard let data = dataConclusao else { return "N/A" }
        
        let agora = Date()
        let calendar = Calendar.current
        let componentes = calendar.dateComponents([.day, .hour, .minute], from: data, to: agora)
        
        if let dias = componentes.day, dias > 0 {
            return "\(dias) dia\(dias > 1 ? "s" : "")"
        } else if let horas = componentes.hour, horas > 0 {
            return "\(horas) hora\(horas > 1 ? "s" : "")"
        } else if let minutos = componentes.minute, minutos > 0 {
            return "\(minutos) minuto\(minutos > 1 ? "s" : "")"
        } else {
            return "Agora mesmo"
        }
    }
}

class ProgressManager {
    static let shared = ProgressManager()
    private let defaults = UserDefaults.standard
    private let progressKey = UserPreferenceKeys.deckProgressData
    
    private var allProgress: [String: DeckProgress] = [:]
    
    private init() {
        loadAllProgress()
    }
    
    // Carrega todo o progresso armazenado
    private func loadAllProgress() {
        guard let data = defaults.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode([String: DeckProgress].self, from: data) else {
            allProgress = [:]
            return
        }
        allProgress = decoded
    }
    
    // Salva todo o progresso
    private func saveAllProgress() {
        guard let encoded = try? JSONEncoder().encode(allProgress) else {
            print("Erro ao codificar progresso")
            return
        }
        defaults.set(encoded, forKey: progressKey)
    }
    
    // Obtém progresso para um deck específico
    func getProgress(for deckId: String) -> DeckProgress {
        if let progress = allProgress[deckId] {
            return progress
        } else {
            // Se não existir, cria novo progresso
            let newProgress = DeckProgress(deckId: deckId)
            allProgress[deckId] = newProgress
            saveAllProgress()
            return newProgress
        }
    }
    
    // Registra uma resposta
    func registrarResposta(deckId: String, cardId: String, acertou: Bool) {
        var progress = getProgress(for: deckId)
        progress.registrarResposta(cardId: cardId, acertou: acertou)
        allProgress[deckId] = progress
        saveAllProgress()
    }
    
    // Salva o índice do último cartão visualizado
    func salvarUltimoCardIndex(deckId: String, index: Int) {
        var progress = getProgress(for: deckId)
        progress.atualizarUltimoCard(index: index)
        allProgress[deckId] = progress
        saveAllProgress()
    }
    
    // Verifica se o deck foi concluído
    func verificarConclusao(deckId: String, totalCards: Int) {
        var progress = getProgress(for: deckId)
        if progress.totalRespondidas >= totalCards {
            progress.marcarComoConcluido()
            allProgress[deckId] = progress
            saveAllProgress()
        }
    }
    
    // Redefine o progresso de um deck específico
    func resetarProgresso(for deckId: String) {
        allProgress[deckId] = DeckProgress(deckId: deckId)
        saveAllProgress()
    }
    
    // Redefine todo o progresso (opcional)
    func resetarTodoProgresso() {
        allProgress = [:]
        saveAllProgress()
    }
    
    // Retorna todos os decks concluídos
    func getDecksConcluidos() -> [String] {
        return allProgress.filter { $0.value.concluido }.map { $0.key }
    }
} 