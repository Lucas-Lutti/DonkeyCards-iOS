import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class MainViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var allDecks: [Deck] = []
    @Published var currentDeck: Deck?
    @Published var currentCardIndex: Int = 0
    @Published var correctCount: Int = 0
    @Published var incorrectCount: Int = 0
    @Published var cardOffset: CGSize = .zero
    @Published var isShowingMenu: Bool = false
    @Published var selectedLanguage: String?
    @Published var selectedTheme: String?
    @Published var currentDeckProgress: DeckProgress?
    @Published var isLoading: Bool = false
    @Published var isLoadingData: Bool = false
    @Published var canRefreshData = false
    @Published var timeUntilNextUpdateMessage: String = ""
    
    private let dataService = DataService.shared
    private let progressManager = ProgressManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDecks()
    }
    
    private func loadDecks() {
        isLoading = true
        dataService.getDecks { [weak self] decks in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.allDecks = decks
                self.decks = decks
                
                if let firstDeck = decks.first {
                    self.selectDeck(firstDeck)
                }
                self.isLoading = false
                self.updateRefreshStatus()
            }
        }
    }
    
    func selectDeck(_ deck: Deck) {
        // Se já estiver no mesmo deck, apenas mantenha o estado atual
        if currentDeck?.storageId == deck.storageId {
            return
        }
        
        // Se já há um deck selecionado, salva o índice atual antes de trocar
        if let currentDeck = currentDeck {
            progressManager.salvarUltimoCardIndex(deckId: currentDeck.storageId, index: currentCardIndex)
        }
        
        // Atualiza para o novo deck
        currentDeck = deck
        
        // Reseta o offset do cartão para zero
        cardOffset = .zero
        
        // Carrega o progresso do novo deck
        loadDeckProgress()
        
        // Verifica se o deck está concluído e atualiza o estado se necessário
        progressManager.verificarConclusao(deckId: deck.storageId, totalCards: deck.cards.count)
        
        // Se o deck estiver concluído, definimos o índice para o último card
        // para manter a consistência visual com a barra de progresso completa
        if isDeckConcluido {
            currentCardIndex = max(0, min(currentCardIndex, deck.cards.count - 1))
        }
        
        // Fecha o menu lateral
        isShowingMenu = false
    }
    
    private func loadDeckProgress() {
        guard let deck = currentDeck else { return }
        
        // Carrega o progresso do deck atual
        let progress = progressManager.getProgress(for: deck.storageId)
        currentDeckProgress = progress
        
        // Restaura o índice do último cartão visualizado
        currentCardIndex = progress.ultimoCardIndex
        
        // Verifica se o índice é válido para o deck atual
        if currentCardIndex >= deck.cards.count {
            currentCardIndex = 0 // Reseta para 0 se o índice for inválido
        }
        
        // Atualiza os contadores com base no progresso carregado
        correctCount = progress.totalAcertos
        incorrectCount = progress.totalErros
    }
    
    func filterDecks(byLanguage language: String? = nil, byTheme theme: String? = nil) {
        selectedLanguage = language
        selectedTheme = theme
        isLoading = true
        
        DispatchQueue.main.async {
            var filteredDecks = self.allDecks
            
            if let language = language, let theme = theme {
                filteredDecks = self.allDecks.filter { $0.idioma == language && $0.tema == theme }
            } else if let language = language {
                filteredDecks = self.allDecks.filter { $0.idioma == language }
            } else if let theme = theme {
                filteredDecks = self.allDecks.filter { $0.tema == theme }
            }
            
            self.decks = filteredDecks
            
            if let firstDeck = self.decks.first {
                self.selectDeck(firstDeck)
            } else {
                self.currentDeck = nil
                self.currentCardIndex = 0
                self.correctCount = 0
                self.incorrectCount = 0
                self.currentDeckProgress = nil
            }
            
            self.isLoading = false
        }
    }
    
    var currentCard: Card? {
        guard let deck = currentDeck, !deck.cards.isEmpty, deck.cards.indices.contains(currentCardIndex) else {
            return nil
        }
        return deck.cards[currentCardIndex]
    }
    
    var isLastCard: Bool {
        guard let deck = currentDeck, !deck.cards.isEmpty else { return false }
        return currentCardIndex >= deck.cards.count
    }
    
    func markCorrect() {
        guard let deck = currentDeck, let card = currentCard else { return }
        
        correctCount += 1
        
        // Registra a resposta no gerenciador de progresso
        progressManager.registrarResposta(
            deckId: deck.storageId,
            cardId: card.storageId,
            acertou: true
        )
        
        // Verifica conclusão do deck
        progressManager.verificarConclusao(
            deckId: deck.storageId,
            totalCards: deck.cards.count
        )
        
        // Atualiza o progresso na view
        loadDeckProgress()
        
        moveToNextCard()
    }
    
    func markIncorrect() {
        guard let deck = currentDeck, let card = currentCard else { return }
        
        incorrectCount += 1
        
        // Registra a resposta no gerenciador de progresso
        progressManager.registrarResposta(
            deckId: deck.storageId,
            cardId: card.storageId,
            acertou: false
        )
        
        // Verifica conclusão do deck
        progressManager.verificarConclusao(
            deckId: deck.storageId,
            totalCards: deck.cards.count
        )
        
        // Atualiza o progresso na view
        loadDeckProgress()
        
        moveToNextCard()
    }
    
    private func moveToNextCard() {
        guard let deck = currentDeck, deck.cards.count > 0 else { return }
        
        if currentCardIndex < deck.cards.count - 1 {
            currentCardIndex += 1
            cardOffset = .zero
        } else {
            // Se chegou ao último card
            currentCardIndex = deck.cards.count // Avança para além do último card
            cardOffset = .zero
            
            // Verifica se o deck foi concluído e recarrega o progresso para exibir a data correta
            if let deckId = currentDeck?.storageId {
                progressManager.verificarConclusao(deckId: deckId, totalCards: deck.cards.count)
                // Recarrega o progresso para atualizar as informações na tela
                loadDeckProgress()
            }
        }
        
        // Salva o índice do cartão atual
        if let deck = currentDeck {
            progressManager.salvarUltimoCardIndex(deckId: deck.storageId, index: currentCardIndex)
        }
    }
    
    func handleCardDrag(value: DragGesture.Value) {
        cardOffset = value.translation
    }
    
    func handleCardDragEnded(value: DragGesture.Value) {
        withAnimation(.spring()) {
            let width = value.translation.width
            
            // Se o swipe foi significativo para a direita
            if width > 150 {
                cardOffset = CGSize(width: 1000, height: 0)
                markCorrect()
            }
            // Se o swipe foi significativo para a esquerda
            else if width < -150 {
                cardOffset = CGSize(width: -1000, height: 0)
                markIncorrect()
            }
            // Se não foi significativo, retorna o card para o centro
            else {
                cardOffset = .zero
            }
        }
    }
    
    func resetDeck() {
        guard let deck = currentDeck else { return }
        
        // Reseta o progresso do deck no gerenciador
        progressManager.resetarProgresso(for: deck.storageId)
        
        // Reseta o estado local
        currentCardIndex = 0
        correctCount = 0
        incorrectCount = 0
        cardOffset = .zero
        
        // Salva a posição inicial
        progressManager.salvarUltimoCardIndex(deckId: deck.storageId, index: currentCardIndex)
        
        // Recarrega o progresso (que estará zerado)
        loadDeckProgress()
    }
    
    var availableLanguages: [String] {
        get {
            // Usar allDecks em vez de decks para mostrar todos os idiomas disponíveis
            return Array(Set(allDecks.map { $0.idioma })).sorted()
        }
    }
    
    func themesForLanguage(_ language: String) -> [String] {
        // Usar allDecks para mostrar todos os temas disponíveis para o idioma
        let themes = allDecks
            .filter { $0.idioma == language }
            .map { $0.tema }
        return Array(Set(themes)).sorted()
    }
    
    func getProgressForDeck(language: String, theme: String) -> Double {
        // Usar allDecks para buscar informações de progresso
        if let deck = allDecks.first(where: { $0.idioma == language && $0.tema == theme }) {
            let progress = progressManager.getProgress(for: deck.storageId)
            // Calcula a porcentagem baseada no total de cartões respondidos
            return Double(progress.totalRespondidas) / Double(deck.cards.count) * 100.0
        }
        return 0.0
    }
    
    // MARK: - Métodos para facilitar acesso às estatísticas do deck atual
    var deckTotalCards: Int {
        return currentDeck?.cards.count ?? 0
    }
    
    var deckTotalRespondidas: Int {
        return currentDeckProgress?.totalRespondidas ?? 0
    }
    
    var deckPercentualAcertos: Double {
        return currentDeckProgress?.percentualAcertos ?? 0.0
    }
    
    var isDeckConcluido: Bool {
        return currentDeckProgress?.concluido ?? false
    }
    
    var dataConclusao: String {
        return currentDeckProgress?.formatarDataConclusao() ?? "Não concluído"
    }
    
    var tempoDesdeConclusao: String {
        return currentDeckProgress?.tempoDesdeConclusao() ?? "N/A"
    }
    
    // Retorna o texto com informações de conclusão do deck
    var textoConclusao: String {
        guard let progresso = currentDeckProgress, progresso.concluido else {
            return "Deck não concluído"
        }
        
        return "Deck concluído em \(progresso.formatarDataConclusao()) (há \(progresso.tempoDesdeConclusao()))"
    }
    
    // Retorna se deve mostrar a tela de conclusão do deck
    var mostrarTelaConclusao: Bool {
        // Retorna true se o deck estiver concluído
        return isDeckConcluido
    }
    
    // MARK: - Métodos para manejar decks concluídos
    
    // Continua revisando um deck mesmo que ele esteja concluído
    func continueReviewingDeck() {
        // Esta função permite ao usuário continuar revisando um deck concluído
        // Reiniciamos o índice do cartão atual para começar do início,
        // mas mantemos o status de conclusão
        currentCardIndex = 0
        
        // Atualiza o progresso e mantém as estatísticas
        loadDeckProgress()
        
        // Salva o índice do cartão atual para continuarmos a partir daqui
        if let deck = currentDeck {
            progressManager.salvarUltimoCardIndex(deckId: deck.storageId, index: currentCardIndex)
        }
    }
    
    // Método para resetar filtros e mostrar todos os decks disponíveis
    func resetFilters() {
        selectedLanguage = nil
        selectedTheme = nil
        decks = allDecks
    }
    
    // Método para garantir que a lista de idiomas e temas não seja restringida pela filtragem
    func ensureFullLanguageList() {
        // Não precisamos modificar a filtragem atual dos decks,
        // apenas garantir que o allDecks esteja carregado e atualizado
        if allDecks.isEmpty && !isLoading {
            loadDecks()
        }
    }
    
    // Método para forçar a recarga dos decks do Firestore
    func refreshDecks() {
        print("Atualizando decks...")
        isLoadingData = true
        
        // Verifica se pode atualizar
        if let remainingTime = DataService.shared.timeUntilNextUpdate(), remainingTime > 0 {
            let hours = Int(remainingTime) / 3600
            let minutes = Int(remainingTime) % 3600 / 60
            timeUntilNextUpdateMessage = "Próxima atualização disponível em \(hours)h \(minutes)min"
            canRefreshData = false
            isLoadingData = false
            return
        }
        
        DataService.shared.getDecks(forceRefresh: true) { [weak self] decks in
            guard let self = self else { return }
            self.allDecks = decks
            
            // Aplica os filtros existentes
            if let language = selectedLanguage {
                self.allDecks = self.allDecks.filter { $0.idioma == language }
            }
            if let theme = selectedTheme {
                self.allDecks = self.allDecks.filter { $0.tema == theme }
            }
            
            self.isLoadingData = false
            self.canRefreshData = false
            self.timeUntilNextUpdateMessage = "Dados atualizados com sucesso!"
            
            // Agenda a próxima verificação
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.updateRefreshStatus()
            }
        }
    }
    
    func updateRefreshStatus() {
        if let remainingTime = DataService.shared.timeUntilNextUpdate() {
            if remainingTime > 0 {
                let hours = Int(remainingTime) / 3600
                let minutes = Int(remainingTime) % 3600 / 60
                timeUntilNextUpdateMessage = "Próxima atualização disponível em \(hours)h \(minutes)min"
                canRefreshData = false
            } else {
                timeUntilNextUpdateMessage = "Atualização disponível"
                canRefreshData = true
            }
        } else {
            timeUntilNextUpdateMessage = "Atualização disponível"
            canRefreshData = true
        }
    }
} 

