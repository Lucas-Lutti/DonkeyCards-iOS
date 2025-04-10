import SwiftUI

struct CardView: View {
    let card: Card
    @Binding var offset: CGSize
    @State private var isFlipped = false
    @State private var rotation: Double = 0
    
    // Calculando as opacidades dos indicadores baseados no offset
    private var swipeRightOpacity: Double {
        min(Double(max(0, offset.width)) / 100, 0.8)
    }
    
    private var swipeLeftOpacity: Double {
        min(Double(max(0, -offset.width)) / 100, 0.8)
    }
    
    var body: some View {
        ZStack {
            // Indicador de acerto (verde) - aparece quando arrasta para a direita
            RoundedRectangle(cornerRadius: 25)
                .fill(AppTheme.successColor)
                .opacity(swipeRightOpacity)
                .frame(
                    width: min(UIScreen.main.bounds.width - 40, 340),
                    height: min(UIScreen.main.bounds.height * 0.5, 440)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(swipeRightOpacity)
                )
            
            // Indicador de erro (vermelho) - aparece quando arrasta para a esquerda
            RoundedRectangle(cornerRadius: 25)
                .fill(AppTheme.errorColor)
                .opacity(swipeLeftOpacity)
                .frame(
                    width: min(UIScreen.main.bounds.width - 40, 340),
                    height: min(UIScreen.main.bounds.height * 0.5, 440)
                )
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(swipeLeftOpacity)
                )
            
            // Frente do card (palavra)
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
                .overlay(
                    ZStack {
                        // Borda verde quando arrasta para a direita
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(AppTheme.successColor, lineWidth: 5)
                            .opacity(swipeRightOpacity)
                        
                        // Borda vermelha quando arrasta para a esquerda
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(AppTheme.errorColor, lineWidth: 5)
                            .opacity(swipeLeftOpacity)
                    }
                )
            
            // Verso do card (resposta)
            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotation - 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .overlay(
                    ZStack {
                        // Borda verde quando arrasta para a direita
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(AppTheme.successColor, lineWidth: 5)
                            .opacity(swipeRightOpacity)
                        
                        // Borda vermelha quando arrasta para a esquerda
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(AppTheme.errorColor, lineWidth: 5)
                            .opacity(swipeLeftOpacity)
                    }
                    .opacity(isFlipped ? 1 : 0)
                )
        }
        .frame(
            width: min(UIScreen.main.bounds.width - 40, 340),
            height: min(UIScreen.main.bounds.height * 0.5, 440)
        )
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            TapGesture()
                .onEnded { _ in
                    flipCard()
                }
        )
    }
    
    private var cardFront: some View {
        ZStack {
            // Fundo com gradiente glassmorphism
            RoundedRectangle(cornerRadius: 25)
                .fill(AppTheme.gradientPrimary.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
            
            // Conteúdo do cartão
            VStack(spacing: 20) {
                HStack {
                    Text(card.idioma)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor.opacity(0.3))
                        )
                    
                    Spacer()
                    
                    Text(card.tema)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor.opacity(0.3))
                        )
                }
                .padding(.top, 5)
                
                Spacer()
                
                Text(card.palavra)
                    .font(.system(size: min(UIScreen.main.bounds.width * 0.1, 40), weight: .bold))
                    .foregroundColor(AppTheme.textColor)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Indicador para tocar para ver a resposta
                    Text("Toque para ver a resposta")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textColor)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor.opacity(0.3))
                        )
                    
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            .padding(25)
        }
    }
    
    private var cardBack: some View {
        ZStack {
            // Fundo com gradiente glassmorphism
            RoundedRectangle(cornerRadius: 25)
                .fill(AppTheme.gradientAccent.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
            
            // Conteúdo do cartão
            VStack(spacing: 20) {
                HStack {
                    Text(card.idioma)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.primaryColor.opacity(0.4))
                        )
                    
                    Spacer()
                    
                    Text(card.tema)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.primaryColor.opacity(0.4))
                        )
                }
                .padding(.top, 5)
                
                Spacer()
                
                Text(card.resposta)
                    .font(.system(size: min(UIScreen.main.bounds.width * 0.1, 40), weight: .bold))
                    .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Indicador para tocar para ver a palavra
                    Text("Toque para ver a palavra")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppTheme.primaryColor.opacity(0.4))
                        )
                    
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            .padding(25)
        }
    }
    
    private func flipCard() {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            if isFlipped {
                rotation += 180
            } else {
                rotation -= 180
            }
            isFlipped.toggle()
        }
    }
} 