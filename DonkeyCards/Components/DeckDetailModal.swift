import SwiftUI

struct DeckDetailModal: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isShowing: Bool
    @State private var showCards: Bool = false
    @State private var isShowingResetConfirmation: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Barra superior com ícone para fechar
            HStack {
                Text("Detalhes do Deck")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding(8)
                        .background(Circle().fill(AppTheme.primaryColor.opacity(0.3)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Informações do deck
                    deckInfoView
                        .padding(.horizontal, 20)
                    
                    // Progresso do deck
                    deckProgressView
                        .padding(.horizontal, 20)
                    
                    // Botão para ver/esconder cartões
                    if let deck = viewModel.currentDeck, !deck.cards.isEmpty {
                        Button(action: {
                            withAnimation(.spring()) {
                                showCards.toggle()
                            }
                        }) {
                            HStack {
                                Text(showCards ? "Esconder Cartões" : "Ver Cartões (\(deck.cards.count))")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textColor)
                                
                                Image(systemName: showCards ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.primaryColor.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accentColor.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Contêiner para os cartões
                        VStack {
                            // Lista de cards (mostrados apenas quando showCards é true)
                            if showCards {
                                VStack(spacing: 5) {
                                    Text("Cartões no Deck")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AppTheme.textColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 15)
                                    
                                    Text("Toque em um cartão para ver a resposta")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 5)
                                    
                                    // Lista de cartões
                                    ForEach(deck.cards) { card in
                                        CardRow(
                                            card: card,
                                            isAnswered: viewModel.currentDeckProgress?.cardsRespondidas.keys.contains(card.storageId) ?? false,
                                            isCorrect: viewModel.currentDeckProgress?.cardsRespondidas[card.storageId] ?? false
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 5)
                                    }
                                    .padding(.bottom, 10)
                                }
                                .transition(.opacity)
                            } else {
                                // Espaçador vazio para manter algum espaço quando os cartões estão escondidos
                                Color.clear.frame(height: 10)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: showCards)
                        .frame(maxWidth: .infinity)
                        .background(showCards ? AppTheme.secondaryColor.opacity(0.1) : Color.clear)
                        .cornerRadius(10)
                        .padding(.horizontal, showCards ? 10 : 0)
                        .clipped()
                    }
                }
            }
            
            // Botões de ação
            HStack(spacing: 15) {
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Text("Fechar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                }
                
                Button(action: {
                    isShowingResetConfirmation = true
                }) {
                    Text("Resetar Deck")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.gradientAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                Rectangle()
                    .fill(AppTheme.secondaryColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
            )
        }
        .background(AppTheme.backgroundColor)
        .cornerRadius(20)
        .frame(maxWidth: UIScreen.main.bounds.width - 40, maxHeight: UIScreen.main.bounds.height * 0.8)
        .alert("Confirmar reinício", isPresented: $isShowingResetConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Reiniciar", role: .destructive) {
                viewModel.resetDeck()
                withAnimation {
                    isShowing = false
                }
            }
        } message: {
            Text("Tem certeza que deseja reiniciar este deck? Todo o progresso será perdido.")
        }
    }
    
    private var deckInfoView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.system(size: 18))
                Text("Nome: ")
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .font(.system(size: 16))
                Text(viewModel.currentDeck?.nome ?? "")
                    .foregroundColor(AppTheme.textColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            HStack {
                Image(systemName: "textformat.abc")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.system(size: 18))
                Text("Idioma: ")
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .font(.system(size: 16))
                Text(viewModel.currentDeck?.idioma ?? "")
                    .foregroundColor(AppTheme.textColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.system(size: 18))
                Text("Categoria: ")
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .font(.system(size: 16))
                Text(viewModel.currentDeck?.tema ?? "")
                    .foregroundColor(AppTheme.textColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.system(size: 18))
                Text("Total de Cartões: ")
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .font(.system(size: 16))
                Text("\(viewModel.currentDeck?.cards.count ?? 0)")
                    .foregroundColor(AppTheme.textColor)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 25)
        .padding(.vertical, 15)
    }
    
    private var deckProgressView: some View {
        VStack(spacing: 20) {
            // Gráfico de progresso circular
            ZStack {
                Circle()
                    .stroke(lineWidth: 15)
                    .opacity(0.3)
                    .foregroundColor(AppTheme.primaryColor)
                
                // Calcular porcentagem de acertos
                let totalResponses = viewModel.correctCount + viewModel.incorrectCount
                let percentage = totalResponses > 0 ? Double(viewModel.correctCount) / Double(totalResponses) : 0
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(percentage))
                    .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                    .foregroundColor(AppTheme.successColor)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.easeInOut, value: percentage)
                
                VStack(spacing: 5) {
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppTheme.textColor)
                    
                    Text("Precisão")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                }
            }
            .frame(width: 150, height: 150)
            
            // Cards estatísticos
            HStack(spacing: 15) {
                StatCard(
                    iconName: "checkmark.circle.fill",
                    value: viewModel.correctCount,
                    label: "Acertos",
                    color: AppTheme.successColor
                )
                
                StatCard(
                    iconName: "xmark.circle.fill",
                    value: viewModel.incorrectCount,
                    label: "Erros",
                    color: AppTheme.errorColor
                )
                
                StatCard(
                    iconName: "chart.bar.fill",
                    value: viewModel.correctCount + viewModel.incorrectCount,
                    label: "Total",
                    color: AppTheme.accentColor
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Componente reutilizável para estatísticas
    private struct StatCard: View {
        let iconName: String
        let value: Int
        let label: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textColor)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppTheme.primaryColor.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // Componente para exibir cartão na lista
    private struct CardRow: View {
        let card: Card
        let isAnswered: Bool
        let isCorrect: Bool
        @State private var showAnswer: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.palavra)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textColor)
                        
                        if showAnswer {
                            Text(card.resposta)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.accentColor)
                                .padding(.top, 2)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                .animation(.easeInOut(duration: 0.2), value: showAnswer)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if isAnswered {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect ? AppTheme.successColor : AppTheme.errorColor)
                                .font(.system(size: 20))
                        }
                        
                        Image(systemName: showAnswer ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.primaryColor.opacity(0.15))
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAnswer.toggle()
                }
            }
        }
    }
    
    // Componente reutilizável para estatísticas
    private struct StatisticView: View {
        let value: String
        let label: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 3) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.opacity(0.8).ignoresSafeArea()
        DeckDetailModal(viewModel: MainViewModel(), isShowing: .constant(true))
    }
} 