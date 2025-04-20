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
    
    // Idiomas disponíveis do Firebase
    @Published var idiomas: [Idioma] = []
    @Published var selectedIdioma: Idioma?
    
    private let dataService = DataService.shared
    private let progressManager = ProgressManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Chave para armazenar a última atualização do tema no UserDefaults
    private let lastThemeUpdateKey = "lastThemeUpdate_"
    
    init() {
        loadIdiomas()
    }
    
    // MARK: - Carregamento de Idiomas
    
    private func loadIdiomas() {
        print("📱 [LOG] Iniciando carregamento de idiomas...")
        isLoading = true
        dataService.getIdiomas { [weak self] idiomas in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Idiomas já vêm filtrados (apenas ativos) do DataService
                self.idiomas = idiomas
                print("📱 [LOG] Idiomas ativos carregados no ViewModel: \(idiomas.count)")
                
                // Seleciona automaticamente o primeiro idioma ativo e carrega seus cards
                if let firstIdioma = idiomas.first {
                    print("📱 [LOG] Selecionando primeiro idioma ativo: \(firstIdioma.nome)")
                    self.selectedIdioma = firstIdioma
                    self.selectedLanguage = firstIdioma.nome
                    self.loadDecksForCurrentIdioma()
                } else {
                    print("📱 [LOG] Nenhum idioma ativo disponível")
                    self.isLoading = false
                }
            }
        }
    }
    
    func selectIdioma(_ idioma: Idioma) {
        // Se o mesmo idioma já estiver selecionado, não faz nada
        if selectedIdioma?.id == idioma.id {
            print("📱 [LOG] Idioma \(idioma.nome) já está selecionado")
            return
        }
        
        print("📱 [LOG] Selecionando idioma: \(idioma.nome)")
        selectedIdioma = idioma
        selectedLanguage = idioma.nome
        
        // Quando um idioma é selecionado, carrega os decks desse idioma
        loadDecksForCurrentIdioma()
    }
    
    private func loadDecksForCurrentIdioma() {
        guard let idioma = selectedIdioma else {
            print("📱 [LOG] Tentativa de carregar decks sem idioma selecionado")
            isLoading = false
            return
        }
        
        print("📱 [LOG] Tentando carregar decks para idioma: \(idioma.nome)")
        
        // Verifica se já temos decks carregados para este idioma
        if !allDecks.isEmpty && allDecks.contains(where: { $0.idioma == idioma.nome }) {
            // Se já temos decks para este idioma, apenas filtrar
            let idiomaDecks = allDecks.filter { $0.idioma == idioma.nome }
            print("📱 [LOG] Usando decks em cache para idioma \(idioma.nome): \(idiomaDecks.count) decks")
            self.decks = idiomaDecks
            
            // Seleciona o primeiro deck do idioma se houver algum
            if let firstDeck = decks.first {
                print("📱 [LOG] Selecionando primeiro deck: \(firstDeck.nome)")
                self.selectDeck(firstDeck)
            }
            
            return
        }
        
        print("📱 [LOG] Carregando decks do idioma \(idioma.nome) do Firebase...")
        
        // Se não temos os decks deste idioma, carrega do serviço
        isLoading = true
        dataService.getDecksForLanguage(idioma.nome) { [weak self] decks in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Adiciona os novos decks ao allDecks (sem substituir os existentes de outros idiomas)
                let existingDecks = self.allDecks.filter { $0.idioma != idioma.nome }
                self.allDecks = existingDecks + decks
                
                // Define os decks atuais como apenas os do idioma selecionado
                self.decks = decks
                
                print("📱 [LOG] Decks carregados do Firebase para idioma \(idioma.nome): \(decks.count) decks")
                
                if let firstDeck = decks.first {
                    print("📱 [LOG] Selecionando primeiro deck: \(firstDeck.nome)")
                    self.selectDeck(firstDeck)
                } else {
                    print("📱 [LOG] Nenhum deck encontrado para idioma \(idioma.nome)")
                }
                
                self.isLoading = false
                self.updateRefreshStatus()
            }
        }
    }
    
    // MARK: - Gerenciamento de Decks
    
    func selectDeck(_ deck: Deck) {
        // Se já estiver no mesmo deck, apenas mantenha o estado atual
        if currentDeck?.storageId == deck.storageId {
            print("📱 [LOG] Deck já selecionado: \(deck.nome)")
            return
        }
        
        print("📱 [LOG] Selecionando deck: \(deck.nome) com \(deck.cards.count) cards")
        
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
            print("📱 [LOG] Deck \(deck.nome) está concluído")
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
        print("📱 [LOG] Aplicando filtro - Idioma: \(language ?? "todos"), Tema: \(theme ?? "todos")")
        selectedLanguage = language
        selectedTheme = theme
        isLoading = true
        
        // Se tivermos um idioma selecionado
        if let language = language {
            // Verifica se precisamos carregar os decks para este idioma
            let languageDecks = allDecks.filter { $0.idioma == language }
            
            // Verifica se já passou 3 horas desde a última atualização dos cards para este tema
            let updateKey = lastThemeUpdateKey + language + (theme ?? "")
            let shouldUpdate = shouldUpdateTheme(key: updateKey)
            
            // Se já temos os decks para este idioma e não precisamos atualizar
            if !languageDecks.isEmpty && !shouldUpdate {
                print("📱 [LOG] Usando decks em cache para filtro - encontrados \(languageDecks.count) decks")
                applyThemeFilter(languageDecks, theme: theme)
                return
            }
            
            print("📱 [LOG] Carregando decks do Firebase para filtro - idioma: \(language)")
            // Se não temos os decks para este idioma ou precisamos atualizar, carrega-os
            dataService.getDecksForLanguage(language) { [weak self] decks in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    // Adiciona os novos decks ao allDecks
                    let existingDecks = self.allDecks.filter { $0.idioma != language }
                    self.allDecks = existingDecks + decks
                    
                    print("📱 [LOG] Decks carregados para filtro: \(decks.count)")
                    
                    // Atualiza o timestamp da última atualização
                    UserDefaults.standard.set(Date(), forKey: updateKey)
                    
                    // Aplica o filtro de tema se necessário
                    self.applyThemeFilter(decks, theme: theme)
                }
            }
        } else {
            // Se não tivermos idioma selecionado, usa todos os decks
            print("📱 [LOG] Usando todos os decks (\(allDecks.count)) sem filtro de idioma")
            decks = allDecks
            
            if let theme = theme {
                // Filtra pelo tema
                print("📱 [LOG] Aplicando filtro apenas por tema: \(theme)")
                decks = decks.filter { $0.tema == theme }
                print("📱 [LOG] Resultado do filtro por tema: \(decks.count) decks")
            }
            
            updateSelectedDeck()
            isLoading = false
        }
    }
    
    private func applyThemeFilter(_ sourceDecks: [Deck], theme: String?) {
        if let theme = theme {
            // Filtra pelo tema
            print("📱 [LOG] Aplicando filtro de tema: \(theme) a \(sourceDecks.count) decks")
            decks = sourceDecks.filter { $0.tema == theme }
            print("📱 [LOG] Resultado após filtro de tema: \(decks.count) decks")
        } else {
            // Sem filtro de tema
            print("📱 [LOG] Sem filtro de tema, usando todos os \(sourceDecks.count) decks")
            decks = sourceDecks
        }
        
        updateSelectedDeck()
        isLoading = false
    }
    
    private func updateSelectedDeck() {
        if let firstDeck = decks.first {
            selectDeck(firstDeck)
        } else {
            currentDeck = nil
            currentCardIndex = 0
            correctCount = 0
            incorrectCount = 0
            currentDeckProgress = nil
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
        // Retorna os nomes dos idiomas disponíveis do Firebase
        return idiomas.map { $0.nome }.sorted()
    }
    
    func themesForLanguage(_ language: String) -> [String] {
        // Usar allDecks para mostrar todos os temas disponíveis para o idioma
        let themes = allDecks
            .filter { $0.idioma == language }
            .map { $0.tema }
            .filter { $0 != "Todos" } // Remove todos os "Todos" inicialmente
        
        // Cria um array com os temas únicos e ordenados
        var uniqueThemes = Array(Set(themes)).sorted()
        
        // Adiciona "Todos" apenas uma vez no final
        uniqueThemes.append("Todos")
        
        return uniqueThemes
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
        // Apenas garante que a lista de idiomas esteja carregada
        if idiomas.isEmpty && !isLoading {
            loadIdiomas()
        }
        // Não carrega automaticamente os decks
    }
    
    // Método para forçar a recarga dos decks do Firestore
    func refreshDecks() {
        print("📱 [LOG] Iniciando atualização forçada dos dados...")
        isLoadingData = true
        
        // Verifica se pode atualizar
        if let remainingTime = DataService.shared.timeUntilNextUpdate(), remainingTime > 0 {
            let hours = Int(remainingTime) / 3600
            let minutes = Int(remainingTime) % 3600 / 60
            timeUntilNextUpdateMessage = "Próxima atualização disponível em \(hours)h \(minutes)min"
            print("📱 [LOG] Atualização não permitida ainda. Próxima em: \(hours)h \(minutes)min")
            canRefreshData = false
            isLoadingData = false
            return
        }
        
        print("📱 [LOG] Atualizando idiomas do Firebase...")
        
        // Recarrega apenas os idiomas e o idioma selecionado
        dataService.getIdiomas(forceRefresh: true) { [weak self] idiomas in
            guard let self = self else { return }
            
            print("📱 [LOG] Idiomas atualizados: \(idiomas.count)")
            
            DispatchQueue.main.async {
                self.idiomas = idiomas
                
                // Se tem um idioma selecionado, recarrega seus decks
                if let selectedIdioma = self.selectedIdioma {
                    print("📱 [LOG] Atualizando decks para idioma: \(selectedIdioma.nome)")
                    
                    self.dataService.getDecksForLanguage(selectedIdioma.nome) { [weak self] decks in
                        guard let self = self else { return }
                        
                        print("📱 [LOG] Decks atualizados para idioma \(selectedIdioma.nome): \(decks.count) decks")
                        
                        DispatchQueue.main.async {
                            // Substitui os decks do idioma atual no allDecks
                            let otherDecks = self.allDecks.filter { $0.idioma != selectedIdioma.nome }
                            self.allDecks = otherDecks + decks
                            
                            // Atualiza os decks visíveis
                            if let theme = self.selectedTheme {
                                print("📱 [LOG] Aplicando filtro de tema: \(theme)")
                                self.decks = decks.filter { $0.tema == theme }
                            } else {
                                self.decks = decks
                            }
                            
                            // Seleciona um deck se necessário
                            if self.currentDeck == nil, let firstDeck = self.decks.first {
                                print("📱 [LOG] Selecionando primeiro deck: \(firstDeck.nome)")
                                self.selectDeck(firstDeck)
                            }
                            
                            print("📱 [LOG] Atualização concluída com sucesso")
                            
                            self.isLoadingData = false
                            self.canRefreshData = false
                            self.timeUntilNextUpdateMessage = "Dados atualizados com sucesso!"
                            
                            // Agenda a próxima verificação
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.updateRefreshStatus()
                            }
                        }
                    }
                } else {
                    print("📱 [LOG] Nenhum idioma selecionado para atualizar decks")
                    
                    self.isLoadingData = false
                    self.canRefreshData = false
                    self.timeUntilNextUpdateMessage = "Dados atualizados com sucesso!"
                    
                    // Agenda a próxima verificação
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.updateRefreshStatus()
                    }
                }
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
    
    // Método para verificar se deve atualizar os cards de um tema específico
    private func shouldUpdateTheme(key: String) -> Bool {
        if let lastUpdate = UserDefaults.standard.object(forKey: key) as? Date {
            // Verifica se já passou 3 horas desde a última atualização
            let threeHoursAgo = Date().addingTimeInterval(-10800) // 3 horas em segundos
            return lastUpdate < threeHoursAgo
        }
        return true // Se nunca atualizou, deve atualizar
    }
} 

