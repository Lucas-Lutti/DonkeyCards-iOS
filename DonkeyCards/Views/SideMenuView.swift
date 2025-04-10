import SwiftUI

struct SideMenuView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isShowing: Bool
    
    @State private var selectedLanguage: String?
    @State private var expandedLanguage: String?
    
    var body: some View {
        ZStack {
            // Fundo escurecido para quando o menu estiver aberto
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }
            
            // Menu
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    menuHeader
                    
                    Divider()
                        .background(AppTheme.accentColor.opacity(0.3))
                        .padding(.top, 5)
                        .padding(.bottom, 15)
                    
                    languageList
                    
                    Spacer()
                    
                    appInfo
                }
                .frame(width: min(UIScreen.main.bounds.width * 0.85, 310))
                .padding(.top, getSafeAreaTop())
                .padding(.bottom, 20)
                .padding(.horizontal, 25)
                .background(
                    ZStack {
                        // Fundo do menu com gradiente
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.backgroundColor,
                                Color(red: 0.03, green: 0.18, blue: 0.08) // Verde mais escuro
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        
                        // Elementos decorativos
                        Circle()
                            .fill(AppTheme.accentColor.opacity(0.05))
                            .frame(width: UIScreen.main.bounds.width * 0.45)
                            .offset(x: UIScreen.main.bounds.width * 0.25, y: -UIScreen.main.bounds.height * 0.15)
                        
                        Circle()
                            .fill(AppTheme.accentColor.opacity(0.08))
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                            .offset(x: -UIScreen.main.bounds.width * 0.1, y: UIScreen.main.bounds.height * 0.3)
                    }
                )
                .clipShape(
                    RoundedCorner(radius: 30, corners: [.topRight, .bottomRight])
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 5, y: 0)
                .ignoresSafeArea(.all, edges: .leading)
                
                Spacer()
            }
        }
        .onAppear {
            // Quando o menu aparecer, garantimos que os decks filtrados não afetam
            // as opções disponíveis no menu
            viewModel.ensureFullLanguageList()
        }
    }
    
    // Função para obter o tamanho da safe area superior
    private func getSafeAreaTop() -> CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets.top ?? 47
    }
    
    private var menuHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                // Ícone e título do app
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.gradientAccent)
                            .frame(width: 44, height: 44)
                            .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image("LOGO")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(AppTheme.textColor)
                    }
                    
                    Text("DonkeyCards")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textColor)
                }
                
                Spacer()
                
                // Botão de fechar
                Button(action: {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                }
            }
            
            // Subtítulo explicativo
            Text("Selecione um idioma e tema para estudar")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textColor.opacity(0.6))
                .padding(.top, 5)
                .padding(.bottom, 10)
        }
    }
    
    private var languageList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.availableLanguages, id: \.self) { language in
                    VStack(alignment: .leading, spacing: 0) {
                        // Botão do idioma
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedLanguage == language {
                                    expandedLanguage = nil
                                } else {
                                    expandedLanguage = language
                                }
                            }
                        }) {
                            HStack {
                                Text(language)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(
                                        viewModel.selectedLanguage == language || expandedLanguage == language ? 
                                        AppTheme.accentColor : AppTheme.textColor
                                    )
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppTheme.accentColor)
                                    .rotationEffect(.degrees(expandedLanguage == language ? 0 : -90))
                                    .animation(.spring(), value: expandedLanguage)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        viewModel.selectedLanguage == language || expandedLanguage == language ? 
                                        AppTheme.accentColor.opacity(0.1) : 
                                        Color.clear
                                    )
                            )
                        }
                        
                        // Lista de temas para o idioma
                        if expandedLanguage == language {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(viewModel.themesForLanguage(language), id: \.self) { theme in
                                    Button(action: {
                                        withAnimation {
                                            viewModel.filterDecks(byLanguage: language, byTheme: theme)
                                            withAnimation(.spring()) {
                                                isShowing = false
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text(theme)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(
                                                    viewModel.selectedLanguage == language && 
                                                    viewModel.selectedTheme == theme ? 
                                                    AppTheme.accentColor : AppTheme.textColor.opacity(0.8)
                                                )
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            let progress = viewModel.getProgressForDeck(language: language, theme: theme)
                                            if progress > 0 {
                                                Text("\(Int(progress))%")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(AppTheme.accentColor.opacity(0.8))
                                            }
                                            
                                            if viewModel.selectedLanguage == language && viewModel.selectedTheme == theme {
                                                Circle()
                                                    .fill(AppTheme.accentColor)
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 15)
                                    }
                                    
                                    if theme != viewModel.themesForLanguage(language).last {
                                        Divider()
                                            .background(AppTheme.primaryColor.opacity(0.1))
                                            .padding(.horizontal, 15)
                                    }
                                }
                                
                                Divider()
                                    .background(AppTheme.primaryColor.opacity(0.1))
                                    .padding(.horizontal, 15)
                                
                                Button(action: {
                                    withAnimation {
                                        viewModel.filterDecks(byLanguage: language)
                                        withAnimation(.spring()) {
                                            isShowing = false
                                        }
                                    }
                                }) {
                                    HStack {
                                        Text("Todos os temas")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(
                                                viewModel.selectedLanguage == language && 
                                                viewModel.selectedTheme == nil ? 
                                                AppTheme.accentColor : AppTheme.textColor.opacity(0.8)
                                            )
                                        
                                        Spacer()
                                        
                                        if viewModel.selectedLanguage == language && viewModel.selectedTheme == nil {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.primaryColor.opacity(0.05))
                            )
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private var appInfo: some View {
        VStack(alignment: .center, spacing: 5) {
            Button(action: {
                if viewModel.canRefreshData {
                    viewModel.refreshDecks()
                    // Dar feedback tátil 
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.canRefreshData ? AppTheme.accentColor.opacity(0.6) : AppTheme.textColor.opacity(0.3))
                    
                    Text(viewModel.canRefreshData ? "Atualizar" : viewModel.timeUntilNextUpdateMessage)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(viewModel.canRefreshData ? AppTheme.accentColor.opacity(0.6) : AppTheme.textColor.opacity(0.3))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(viewModel.canRefreshData ? AppTheme.accentColor.opacity(0.1) : AppTheme.textColor.opacity(0.05))
                )
            }
            .disabled(!viewModel.canRefreshData)
            .padding(.bottom, 10)
            
            Text("DonkeyCards v1.0")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textColor.opacity(0.6))
            
            Text("Aprendizado inteligente para todos")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textColor.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 5)
    }
}

// Helper para criar cantos arredondados específicos
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 