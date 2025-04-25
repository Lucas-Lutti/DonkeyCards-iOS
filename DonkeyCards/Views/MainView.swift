import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @EnvironmentObject private var authService: AuthService
    @State private var isShowingMenu = false
    @State private var isShowingDeckDetail = false
    @State private var isShowingTutorial = !UserPreferences.shared.hasCompletedTutorial
    @State private var isShowingResetConfirmation = false
    @State private var isShowingProfileView = false
    @State private var isShowingLoginView = false
    
    var body: some View {
        ZStack {
            // Fundo com gradiente
            backgroundView
                .ignoresSafeArea()
            
            // Conteúdo principal
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                
                Spacer(minLength: 0)
                
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppTheme.accentColor)
                        
                        Text("Carregando dados...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.textColor)
                            .padding(.top, 15)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    cardStack
                        .padding(.horizontal, 15)
                }
                
                Spacer(minLength: 0)
                
                if viewModel.decks.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.accentColor)
                        
                        Text("Nenhum dado encontrado no Firestore")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textColor)
                            .multilineTextAlignment(.center)
                        
                        Text("Não há cartões disponíveis no banco de dados. Por favor, adicione cartões diretamente no Firebase Firestore.")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textColor.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                isShowingMenu = true
                            }
                        }) {
                            Text("Abrir Menu")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 25)
                                .background(AppTheme.accentColor)
                                .cornerRadius(25)
                        }
                        .padding(.top, 10)
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppTheme.primaryColor.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                } else {
                    scoreDisplay
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isShowingDeckDetail = true
                            }
                        }
                    
                    VStack(spacing: 5) {
                        deckInfo
                            .padding(.bottom, 5)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    isShowingDeckDetail = true
                                }
                            }
                        
                        Text("Toque para ver mais detalhes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textColor.opacity(0.5))
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, getSafeAreaTop())
            
            // Menu lateral com overlay escuro quando aberto
            if isShowingMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isShowingMenu = false
                        }
                    }
                
                SideMenuView(viewModel: viewModel, isShowing: $isShowingMenu)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
            
            // Modal de detalhes do deck
            if isShowingDeckDetail {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isShowingDeckDetail = false
                        }
                    }
                
                DeckDetailModal(viewModel: viewModel, isShowing: $isShowingDeckDetail)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }
            
            // Tutorial na primeira execução
            if isShowingTutorial {
                TutorialOverlay(isActive: $isShowingTutorial)
                    .zIndex(10) // Garantir que fique acima de tudo
                    .transition(.opacity)
                    .onDisappear {
                        // Marcar o tutorial como concluído quando fechado
                        UserPreferences.shared.completeTutorial()
                    }
            }
        }
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .alert(isPresented: $isShowingResetConfirmation) {
            Alert(
                title: Text("Confirmar reinício"),
                message: Text("Tem certeza que deseja atualizar este deck? Todo o progresso será perdido."),
                primaryButton: .destructive(Text("Reiniciar")) {
                    viewModel.resetDeck()
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
        .sheet(isPresented: $isShowingProfileView) {
            if authService.isAuthenticated && authService.currentUser != nil {
                ProfileView()
            } else {
                LoginView()
            }
        }
        .sheet(isPresented: $isShowingLoginView) {
            LoginView()
        }
        .onAppear {
            print("📱 [MainView] View appeared")
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            print("📱 [MainView] Auth state changed: \(isAuthenticated)")
        }
    }
    
    // Função para obter o tamanho da safe area superior
    private func getSafeAreaTop() -> CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets.top ?? 47
    }
    
    // Fundo com gradiente e elementos decorativos
    private var backgroundView: some View {
        ZStack {
            // Gradient base que preenche toda a tela
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    Color(red: 0.03, green: 0.18, blue: 0.08) // Verde mais escuro
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Elementos decorativos - apenas bolas estáticas sem conexões
            // Círculo grande superior direito
            Circle()
                .fill(AppTheme.accentColor.opacity(0.08))
                .frame(width: UIScreen.main.bounds.width * 0.75)
                .position(x: UIScreen.main.bounds.width * 0.85, y: UIScreen.main.bounds.height * 0.2)
                .blur(radius: 5)
            
            // Círculo médio superior esquerdo
            Circle()
                .fill(AppTheme.accentColor.opacity(0.1))
                .frame(width: UIScreen.main.bounds.width * 0.5)
                .position(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.28)
                .blur(radius: 4)
            
            // Círculo grande inferior esquerdo
            Circle()
                .fill(AppTheme.accentColor.opacity(0.06))
                .frame(width: UIScreen.main.bounds.width * 0.6)
                .position(x: UIScreen.main.bounds.width * 0.1, y: UIScreen.main.bounds.height * 0.7)
                .blur(radius: 5)
            
            // Círculo médio inferior direito
            Circle()
                .fill(AppTheme.accentColor.opacity(0.09))
                .frame(width: UIScreen.main.bounds.width * 0.45)
                .position(x: UIScreen.main.bounds.width * 0.7, y: UIScreen.main.bounds.height * 0.75)
                .blur(radius: 4)
            
            // Círculo pequeno central
            Circle()
                .fill(AppTheme.accentColor.opacity(0.12))
                .frame(width: UIScreen.main.bounds.width * 0.3)
                .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5)
                .blur(radius: 3)
                
            // Círculo pequeno extra topo
            Circle()
                .fill(AppTheme.accentColor.opacity(0.07))
                .frame(width: UIScreen.main.bounds.width * 0.25)
                .position(x: UIScreen.main.bounds.width * 0.6, y: UIScreen.main.bounds.height * 0.15)
                .blur(radius: 2)
                
            // Círculo pequeno extra fundo
            Circle()
                .fill(AppTheme.accentColor.opacity(0.08))
                .frame(width: UIScreen.main.bounds.width * 0.35)
                .position(x: UIScreen.main.bounds.width * 0.4, y: UIScreen.main.bounds.height * 0.85)
                .blur(radius: 3)
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                withAnimation(.spring()) {
                    isShowingMenu.toggle()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.primaryColor.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 5) {
                Text("DonkeyCards")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.textColor)
                
                Text("Aprenda e deixe de ser 🐴")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                // Verifica se o usuário está autenticado
                if authService.isAuthenticated && authService.currentUser != nil {
                    DispatchQueue.main.async {
                        isShowingProfileView = true
                    }
                } else {
                    DispatchQueue.main.async {
                        isShowingLoginView = true
                    }
                }
            }) {
                Image(systemName: "person.circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.primaryColor.opacity(0.2))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                authService.isAuthenticated ? AppTheme.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            }
        }
        .padding(.vertical, 10)
    }
    
    private var cardStack: some View {
        ZStack {
            // Caso não haja cards, mostra uma mensagem
            if viewModel.currentCard == nil && !viewModel.isLastCard {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentColor.opacity(0.8))
                    
                    Text("Nenhum cartão disponível")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppTheme.textColor)
                    
                    Text("Selecione outro deck no menu")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isShowingMenu.toggle()
                        }
                    }) {
                        Text("Abrir Menu")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textColor)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(AppTheme.gradientAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 15)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppTheme.primaryColor.opacity(0.15))
                )
            }
            // Se o deck foi concluído mas ainda está sendo aberto para revisão
            else if viewModel.mostrarTelaConclusao && !viewModel.isLastCard {
                VStack(spacing: 20) {
                    // Troféu ou ícone de conclusão
                    ZStack {
                        Circle()
                            .fill(AppTheme.gradientAccent)
                            .frame(width: 100, height: 100)
                            .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.textColor)
                    }
                    
                    Text("Deck já concluído!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textColor)
                    
                    Text(viewModel.textoConclusao)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Taxa de acerto: \(Int(viewModel.deckPercentualAcertos))%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(
                            viewModel.deckPercentualAcertos >= 70 ? AppTheme.successColor :
                            viewModel.deckPercentualAcertos >= 50 ? Color.yellow : AppTheme.errorColor
                        )
                        .padding(.vertical, 5)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            // Selecionar outro deck
                            withAnimation(.spring()) {
                                isShowingMenu.toggle()
                            }
                        }) {
                            Text("Outro Deck")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.98, green: 0.95, blue: 0.0), 
                                            Color(red: 0.90, green: 0.88, blue: 0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        
                        Button(action: {
                            // Reiniciar o deck ao invés de apenas revisar
                            isShowingResetConfirmation = true
                        }) {
                            Text("Reiniciar Deck")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(AppTheme.gradientAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppTheme.primaryColor.opacity(0.15))
                )
                .padding(.horizontal, 10)
            }
            // Mostra o cartão atual
            else if let currentCard = viewModel.currentCard {
                CardView(card: currentCard, offset: $viewModel.cardOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.handleCardDrag(value: value)
                            }
                            .onEnded { value in
                                viewModel.handleCardDragEnded(value: value)
                            }
                    )
                
                // Indicadores de swipe
                HStack {
                    // Indicador de swipe para a esquerda (incorreto)
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(AppTheme.errorColor.opacity(0.8))
                        .opacity(viewModel.cardOffset.width < -50 ? Double(abs(viewModel.cardOffset.width)) / 250 : 0)
                        .offset(x: -130)
                        .blur(radius: 0.5)
                    
                    Spacer()
                    
                    // Indicador de swipe para a direita (correto)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(AppTheme.successColor.opacity(0.8))
                        .opacity(viewModel.cardOffset.width > 50 ? Double(viewModel.cardOffset.width) / 250 : 0)
                        .offset(x: 130)
                        .blur(radius: 0.5)
                }
            }
            // Mostra o botão de reiniciar se acabaram os cartões
            else {
                VStack(spacing: 25) {
                    // Troféu ou ícone de conclusão
                    ZStack {
                        Circle()
                            .fill(AppTheme.gradientAccent)
                            .frame(width: 120, height: 120)
                            .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textColor)
                    }
                    
                    Text("Deck concluído!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textColor)
                    
                    Text(viewModel.textoConclusao)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 15) {
                        HStack(spacing: 20) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.successColor)
                                Text("\(viewModel.correctCount)")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(AppTheme.successColor.opacity(0.15))
                            .clipShape(Capsule())
                            
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.errorColor)
                                Text("\(viewModel.incorrectCount)")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(AppTheme.errorColor.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        
                        Text("Taxa de acerto: \(Int(viewModel.deckPercentualAcertos))%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(
                                viewModel.deckPercentualAcertos >= 70 ? AppTheme.successColor :
                                viewModel.deckPercentualAcertos >= 50 ? Color.yellow : AppTheme.errorColor
                            )
                            .padding(.vertical, 5)
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation(.spring()) {
                                isShowingMenu.toggle()
                            }
                        }) {
                            Text("Outro Deck")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.98, green: 0.95, blue: 0.0), 
                                            Color(red: 0.90, green: 0.88, blue: 0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        
                        Button(action: {
                            isShowingResetConfirmation = true
                        }) {
                            Text("Reiniciar Deck")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(AppTheme.gradientAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppTheme.primaryColor.opacity(0.15))
                )
                .padding(.horizontal, 20)
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.55)
    }
    
    private var scoreDisplay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.primaryColor.opacity(0.15))
                .frame(height: 100)
            
            HStack(spacing: 25) {
                VStack(alignment: .center, spacing: 5) {
                    if let progress = viewModel.currentDeckProgress {
                        // Progresso total
                        Text("\(progress.totalRespondidas)/\(viewModel.deckTotalCards)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Respondidos")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    } else {
                        Text("0/0")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Respondidos")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.accentColor.opacity(0.2))
                    .frame(width: 1, height: 30)
                
                VStack(alignment: .center, spacing: 5) {
                    Text("\(viewModel.correctCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.successColor)
                    
                    Text("Acertos")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.accentColor.opacity(0.2))
                    .frame(width: 1, height: 30)
                
                VStack(alignment: .center, spacing: 5) {
                    Text("\(viewModel.incorrectCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.errorColor)
                    
                    Text("Erros")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
        }
    }
    
    private var deckInfo: some View {
        if let currentDeck = viewModel.currentDeck {
            return VStack(spacing: 5) {
                HStack {
                    Text("Deck: \(currentDeck.nome)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
                .padding(.horizontal, 20)
                
                HStack {
                    Capsule()
                        .fill(AppTheme.accentColor.opacity(0.2))
                        .frame(width: progressWidth(total: CGFloat(currentDeck.cards.count)), height: 8)
                        .overlay(
                            Capsule()
                                .fill(AppTheme.accentColor)
                                .frame(width: calculateProgressWidth(deck: currentDeck))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                        .padding(.horizontal, 20)
                }
                
                // Se o deck estiver concluído, mostra sempre como último cartão
                if viewModel.isDeckConcluido {
                    Text("Deck concluído (\(currentDeck.cards.count)/\(currentDeck.cards.count))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                } else {
                    let cardIndex = min(viewModel.currentCardIndex, currentDeck.cards.count - 1)
                    let displayIndex = currentDeck.cards.isEmpty ? 0 : cardIndex + 1
                    Text("Card \(displayIndex) de \(currentDeck.cards.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppTheme.primaryColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppTheme.accentColor.opacity(0.2), lineWidth: 1)
            )
            .eraseToAnyView()
        } else {
            return EmptyView().eraseToAnyView()
        }
    }
    
    // Função para calcular a largura da barra de progresso
    private func progressWidth(current: CGFloat = 0, total: CGFloat) -> CGFloat {
        let baseWidth = UIScreen.main.bounds.width - 80
        return current > 0 ? (current / total) * baseWidth : baseWidth
    }
    
    // Função para calcular a largura da barra de progresso considerando o estado atual
    private func calculateProgressWidth(deck: Deck) -> CGFloat {
        let baseWidth = UIScreen.main.bounds.width - 80
        
        // Se não houver cards, retorna zero
        if deck.cards.isEmpty {
            return 0
        }
        
        // Se o deck foi concluído, mostra a barra completa
        if viewModel.isDeckConcluido {
            return baseWidth
        }
        
        // Se já terminou o deck (currentCardIndex >= cards.count)
        if viewModel.currentCardIndex >= deck.cards.count {
            return baseWidth
        }
        
        // Caso normal: mostra o progresso atual
        let current = CGFloat(viewModel.currentCardIndex + 1)
        let total = CGFloat(deck.cards.count)
        return (current / total) * baseWidth
    }
}

// Extension para transformar qualquer View em AnyView
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
