import SwiftUI

enum AppTheme {
    // Nova paleta de cores com verde escuro e amarelo fluorescente
    static let primaryColor = Color(red: 0.05, green: 0.25, blue: 0.10) // Verde escuro
    static let secondaryColor = Color(red: 0.03, green: 0.18, blue: 0.08) // Verde mais escuro
    static let accentColor = Color(red: 0.98, green: 0.95, blue: 0.0) // Amarelo fluorescente
    static let backgroundColor = Color(red: 0.02, green: 0.15, blue: 0.07) // Verde muito escuro (quase preto)
    static let textColor = Color.white
    static let errorColor = Color(red: 0.93, green: 0.26, blue: 0.26) // Vermelho moderno
    static let successColor = Color(red: 0.90, green: 0.95, blue: 0.0) // Amarelo fluorescente mais claro
    
    static let cardFrontColor = Color(red: 0.05, green: 0.25, blue: 0.10) // Verde escuro
    static let cardBackColor = Color(red: 0.08, green: 0.28, blue: 0.13) // Verde escuro mais claro
    
    static let gradientPrimary = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.05, green: 0.25, blue: 0.10),
            Color(red: 0.03, green: 0.18, blue: 0.08)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientAccent = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.98, green: 0.95, blue: 0.0),
            Color(red: 0.90, green: 0.88, blue: 0.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07)) // Verde escuro como texto sobre fundo amarelo
            .padding()
            .background(AppTheme.gradientAccent)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(AppTheme.gradientPrimary)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
} 