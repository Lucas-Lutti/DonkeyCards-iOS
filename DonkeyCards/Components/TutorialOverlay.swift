import SwiftUI

struct TutorialOverlay: View {
    @Binding var isActive: Bool
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var showArrowRight = false
    @State private var showArrowLeft = false
    @State private var buttonOpacity: CGFloat = 0
    @State private var currentStep = 0
    @State private var hintOpacity: CGFloat = 0
    @State private var cardColorOverlay: Color = .clear
    @State private var cardColorOpacity: CGFloat = 0
    
    // Temporização das animações
    let cardAnimationDuration: Double = 1.2
    let delayBetweenAnimations: Double = 0.5
    
    var body: some View {
        ZStack {
            // Fundo com blur intenso para a tela principal
            Color.black.opacity(0.7)
                .background(Material.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Gradiente de fundo do onboarding
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    AppTheme.backgroundColor.opacity(0.92),
                    AppTheme.primaryColor.opacity(0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.9)
            .ignoresSafeArea()
            
            // Padrão de fundo com efeito de profundidade
            ZStack {
                ForEach(0..<8) { index in
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.03))
                        .frame(width: 120 + CGFloat(index * 10), height: 120 + CGFloat(index * 10))
                        .offset(x: -50 + CGFloat(index * 5), y: 150 - CGFloat(index * 15))
                        .blur(radius: 12)
                        .opacity(0.3)
                }
                
                ForEach(0..<5) { index in
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.02))
                        .frame(width: 100 + CGFloat(index * 15), height: 100 + CGFloat(index * 15))
                        .offset(x: 120 - CGFloat(index * 5), y: -100 + CGFloat(index * 10))
                        .blur(radius: 12)
                        .opacity(0.3)
                }
            }
            
            // Conteúdo principal
            VStack(spacing: 0) {
                // Logo e Título do App
                VStack(spacing: 15) {
                    Image("LOGO")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: AppTheme.accentColor.opacity(0.6), radius: 10, x: 0, y: 5)
                        .padding(.top, 40)
                    
                    Text("DonkeyCards")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.accentColor)
                    
                    Text("Aprenda vocabulário\ncom flashcards interativos")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                        .padding(.top, 5)
                }
                .opacity(hintOpacity)
                
                Spacer()
                
                // Container para o card e as dicas
                ZStack {
                    // Dicas visuais (atrás do card) - lado direito
                    if showArrowRight {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppTheme.successColor)
                                    .shadow(color: AppTheme.successColor.opacity(0.5), radius: 5, x: 0, y: 0)
                                
                                HStack(spacing: 4) {
                                    Text("Sei")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.accentColor)
                                        .offset(x: hintOpacity == 1 ? 5 : 0)
                                        .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: hintOpacity)
                                }
                            }
                            .padding(.trailing, 150)
                            .opacity(hintOpacity)
                        }
                        .zIndex(1)
                    }
                    
                    // Dicas visuais (atrás do card) - lado esquerdo
                    if showArrowLeft {
                        HStack {
                            VStack(spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppTheme.errorColor)
                                    .shadow(color: AppTheme.errorColor.opacity(0.5), radius: 5, x: 0, y: 0)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.accentColor)
                                        .offset(x: hintOpacity == 1 ? -5 : 0)
                                        .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: hintOpacity)
                                    
                                    Text("Não sei")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.leading, 150)
                            .opacity(hintOpacity)
                            
                            Spacer()
                        }
                        .zIndex(1)
                    }
                    
                    // Card principal
                    ZStack {
                        // Base do card
                        RoundedRectangle(cornerRadius: 25)
                            .fill(AppTheme.primaryColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(AppTheme.accentColor, lineWidth: 1.5)
                                    .opacity(0.8)
                            )
                            .shadow(
                                color: AppTheme.accentColor.opacity(0.15),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        
                        // Padrão decorativo no card
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentColor.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .offset(x: -100, y: 80)
                                .blur(radius: 15)
                            
                            Circle()
                                .fill(AppTheme.accentColor.opacity(0.07))
                                .frame(width: 150, height: 150)
                                .offset(x: 110, y: -60)
                                .blur(radius: 10)
                        }
                        
                        // Sobreposição de cor baseada na direção do deslize
                        RoundedRectangle(cornerRadius: 25)
                            .fill(cardColorOverlay)
                            .opacity(cardColorOpacity)
                            .blendMode(.overlay)
                        
                        // Borda indicativa de direção
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(cardColorOverlay, lineWidth: 3)
                            .opacity(cardColorOpacity * 0.8)
                        
                        // Conteúdo do cartão
                        VStack(spacing: 16) {
                            Text("VOCABULARY")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(2)
                                .foregroundColor(AppTheme.accentColor.opacity(0.7))
                            
                            Text("Palavra")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Exemplo")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 8)
                        }
                    }
                    .frame(width: 300, height: 200)
                    .offset(cardOffset)
                    .scaleEffect(cardScale)
                    .rotation3DEffect(
                        .degrees(cardRotation),
                        axis: (x: 0, y: 1, z: 0.2)
                    )
                    .zIndex(10) // Card sempre fica acima das dicas
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .padding(.bottom, 20)
                
                // Dicas minimalistas
                Text(currentStepHint)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                    .transition(.opacity)
                    .id("hint-\(currentStep)")
                
                // Botão para começar (sempre presente)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = false
                    }
                }) {
                    Text("Começar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.backgroundColor)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(AppTheme.gradientAccent)
                                .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        )
                }
                .opacity(buttonOpacity)
                .scaleEffect(buttonOpacity > 0.5 ? 1 : 0.8)
                .padding(.bottom, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startTutorialAnimation()
        }
    }
    
    // Texto para cada passo da animação
    private var currentStepHint: String {
        switch currentStep {
        case 0:
            return "Gestos simples para revisar seus cartões"
        case 1:
            return "Arraste para a direita quando souber a resposta"
        case 2:
            return "Arraste para a esquerda quando não souber"
        case 3:
            return "Pronto para começar!"
        default:
            return ""
        }
    }
    
    // Sequência completa de animação
    private func startTutorialAnimation() {
        // Iniciar a sequência após um pequeno delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Primeiro mostrar a logo e título
            withAnimation(.easeOut(duration: 0.8)) {
                hintOpacity = 1
            }
            
            // Após mostrar a logo, mostrar o card e botão
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.8)) {
                    cardScale = 1.0
                    currentStep = 0
                    buttonOpacity = 1.0
                }
                
                // Após introdução, mostrar animação de deslize para direita
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showArrowRight = true
                        currentStep = 1
                    }
                    
                    // Animar cartão para direita com cor verde
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        // Aplicar cor verde
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cardColorOverlay = AppTheme.successColor
                            cardColorOpacity = 0.3
                        }
                        
                        // Animar deslize para direita
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            cardOffset = CGSize(width: 120, height: 0)
                            cardRotation = 8
                            cardColorOpacity = 0.5
                        }
                        
                        // Retornar cartão ao centro
                        DispatchQueue.main.asyncAfter(deadline: .now() + cardAnimationDuration) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                cardOffset = .zero
                                cardRotation = 0
                                cardColorOpacity = 0
                            }
                            
                            // Esconder seta direita
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showArrowRight = false
                            }
                            
                            // Mostrar animação de deslize para esquerda
                            DispatchQueue.main.asyncAfter(deadline: .now() + delayBetweenAnimations) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showArrowLeft = true
                                    currentStep = 2
                                }
                                
                                // Animar cartão para esquerda com cor vermelha
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    // Aplicar cor vermelha
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        cardColorOverlay = AppTheme.errorColor
                                        cardColorOpacity = 0.3
                                    }
                                    
                                    // Animar deslize para esquerda
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                        cardOffset = CGSize(width: -120, height: 0)
                                        cardRotation = -8
                                        cardColorOpacity = 0.5
                                    }
                                    
                                    // Retornar cartão ao centro
                                    DispatchQueue.main.asyncAfter(deadline: .now() + cardAnimationDuration) {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            cardOffset = .zero
                                            cardRotation = 0
                                            cardColorOpacity = 0
                                        }
                                        
                                        // Esconder setas esquerda
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showArrowLeft = false
                                        }
                                        
                                        // Mostrar texto final
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            // Mostrar texto final
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                currentStep = 3
                                            }
                                            
                                            // Reiniciar ciclo de animação após uma pausa
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                if isActive {
                                                    // Voltar ao passo 1 para reiniciar o ciclo de animação
                                                    withAnimation(.easeInOut(duration: 0.4)) {
                                                        showArrowRight = true
                                                        currentStep = 1
                                                    }
                                                    
                                                    // Animar cartão para direita novamente com cor verde
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                        // Aplicar cor verde
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            cardColorOverlay = AppTheme.successColor
                                                            cardColorOpacity = 0.3
                                                        }
                                                        
                                                        // Animar deslize para direita
                                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                            cardOffset = CGSize(width: 120, height: 0)
                                                            cardRotation = 8
                                                            cardColorOpacity = 0.5
                                                        }
                                                        
                                                        // Retornar cartão ao centro
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + cardAnimationDuration) {
                                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                                cardOffset = .zero
                                                                cardRotation = 0
                                                                cardColorOpacity = 0
                                                            }
                                                            
                                                            // Esconder seta direita
                                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                                showArrowRight = false
                                                            }
                                                            
                                                            // Mostrar animação de deslize para esquerda
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + delayBetweenAnimations) {
                                                                withAnimation(.easeInOut(duration: 0.4)) {
                                                                    showArrowLeft = true
                                                                    currentStep = 2
                                                                }
                                                                
                                                                // Animar cartão para esquerda com cor vermelha
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                                    // Aplicar cor vermelha
                                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                                        cardColorOverlay = AppTheme.errorColor
                                                                        cardColorOpacity = 0.3
                                                                    }
                                                                    
                                                                    // Animar deslize para esquerda
                                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                                        cardOffset = CGSize(width: -120, height: 0)
                                                                        cardRotation = -8
                                                                        cardColorOpacity = 0.5
                                                                    }
                                                                    
                                                                    // Retornar cartão ao centro
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + cardAnimationDuration) {
                                                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                                            cardOffset = .zero
                                                                            cardRotation = 0
                                                                            cardColorOpacity = 0
                                                                        }
                                                                        
                                                                        // Esconder setas esquerda
                                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                                            showArrowLeft = false
                                                                        }
                                                                        
                                                                        // Continuar a animação enquanto o tutorial estiver ativo
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                                            if isActive {
                                                                                startTutorialAnimation()
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TutorialOverlay_Previews: PreviewProvider {
    static var previews: some View {
        TutorialOverlay(isActive: .constant(true))
            .preferredColorScheme(.dark)
    }
} 