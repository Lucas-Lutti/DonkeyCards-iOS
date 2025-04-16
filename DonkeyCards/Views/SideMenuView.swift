import SwiftUI

struct SideMenuView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isShowing: Bool
    
    @State private var selectedLanguage: String?
    @State private var expandedLanguage: String?
    @State private var lastUpdate: Date? = UserDefaults.standard.object(forKey: "lastLanguageUpdate") as? Date
    
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
            // Verifica se já passou uma hora desde a última atualização
            let oneHourAgo = Date().addingTimeInterval(-3600)
            if lastUpdate == nil || lastUpdate! < oneHourAgo {
                print("📱 [LOG] Atualizando idiomas do Firestore")
                DataService.shared.getIdiomas(forceRefresh: true) { [weak viewModel] idiomas in
                    guard let viewModel = viewModel else { return }
                    
                    // Filtra apenas os idiomas ativos
                    let idiomasAtivos = idiomas.filter { $0.ativo }
                    
                    DispatchQueue.main.async {
                        // Atualiza os idiomas no viewModel com apenas os idiomas ativos
                        print("📱 [LOG] Atualizando lista de idiomas: \(idiomasAtivos.count) idiomas ativos")
                        viewModel.idiomas = idiomasAtivos
                        
                        // Atualiza a última data de atualização
                        lastUpdate = Date()
                        UserDefaults.standard.set(lastUpdate, forKey: "lastLanguageUpdate")
                        
                        // Se tiver um idioma selecionado, verifica se ele ainda está ativo
                        if let selectedIdioma = viewModel.selectedIdioma {
                            if let updatedIdioma = idiomasAtivos.first(where: { $0.nome == selectedIdioma.nome }) {
                                // O idioma selecionado ainda está ativo, mantenha-o
                                viewModel.selectedIdioma = updatedIdioma
                            } else if let firstIdioma = idiomasAtivos.first {
                                // O idioma selecionado não está mais ativo, seleciona o primeiro ativo
                                print("📱 [LOG] Idioma selecionado não está mais ativo, selecionando o primeiro disponível")
                                viewModel.selectIdioma(firstIdioma)
                            }
                        } else if let firstIdioma = idiomasAtivos.first, viewModel.selectedIdioma == nil {
                            // Se não tiver idioma selecionado, seleciona o primeiro ativo
                            viewModel.selectIdioma(firstIdioma)
                        }
                        
                        // Define o idioma expandido como o idioma atualmente selecionado
                        if let selectedIdioma = viewModel.selectedIdioma {
                            expandedLanguage = selectedIdioma.nome
                        }
                    }
                }
            } else {
                print("📱 [LOG] Usando idiomas do cache")
            }
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
                ForEach(viewModel.idiomas) { idioma in
                    VStack(alignment: .leading, spacing: 0) {
                        // Botão do idioma
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                // Quando um idioma é clicado, expande ou colapsa o menu
                                if expandedLanguage == idioma.nome {
                                    expandedLanguage = nil
                                } else {
                                    expandedLanguage = idioma.nome
                                    // Apenas quando um idioma é expandido, seleciona-o e carrega os cards
                                    viewModel.selectIdioma(idioma)
                                }
                            }
                        }) {
                            HStack {
                                Text(idioma.nome)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(
                                        viewModel.selectedLanguage == idioma.nome || expandedLanguage == idioma.nome ? 
                                        AppTheme.accentColor : AppTheme.textColor
                                    )
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppTheme.accentColor)
                                    .rotationEffect(.degrees(expandedLanguage == idioma.nome ? 0 : -90))
                                    .animation(.spring(), value: expandedLanguage)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        viewModel.selectedLanguage == idioma.nome || expandedLanguage == idioma.nome ? 
                                        AppTheme.accentColor.opacity(0.1) : 
                                        Color.clear
                                    )
                            )
                        }
                        
                        // Lista de temas para o idioma
                        if expandedLanguage == idioma.nome {
                            VStack(alignment: .leading, spacing: 2) {
                                // Primeiro loop apenas para temas regulares (não o "Todos")
                                let regularThemes = viewModel.themesForLanguage(idioma.nome).filter { $0 != "Todos" }
                                
                                ForEach(regularThemes, id: \.self) { theme in
                                    Button(action: {
                                        withAnimation {
                                            viewModel.filterDecks(byLanguage: idioma.nome, byTheme: theme)
                                            withAnimation(.spring()) {
                                                isShowing = false
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text(theme)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(
                                                    viewModel.selectedLanguage == idioma.nome && 
                                                    viewModel.selectedTheme == theme ? 
                                                    AppTheme.accentColor : AppTheme.textColor.opacity(0.8)
                                                )
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            // Mostrar percentual de progresso
                                            let progress = viewModel.getProgressForDeck(language: idioma.nome, theme: theme)
                                            if progress > 0 {
                                                Text("\(Int(progress))%")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(AppTheme.accentColor.opacity(0.8))
                                                    .padding(.trailing, 8)
                                            }
                                            
                                            if viewModel.selectedLanguage == idioma.nome && viewModel.selectedTheme == theme {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(AppTheme.accentColor)
                                            }
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 15)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(
                                                    viewModel.selectedLanguage == idioma.nome && 
                                                    viewModel.selectedTheme == theme ? 
                                                    AppTheme.accentColor.opacity(0.08) : 
                                                    Color.clear
                                                )
                                        )
                                    }
                                    
                                    if theme != regularThemes.last {
                                        Divider()
                                            .background(AppTheme.accentColor.opacity(0.05))
                                            .padding(.horizontal, 15)
                                    }
                                }
                                
                                // Divider para separar os temas individuais da opção "Todos"
                                Divider()
                                    .background(AppTheme.accentColor.opacity(0.1))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 5)
                                
                                // Opção para mostrar todos os temas do idioma
                                Button(action: {
                                    withAnimation {
                                        viewModel.filterDecks(byLanguage: idioma.nome, byTheme: "Todos")
                                        withAnimation(.spring()) {
                                            isShowing = false
                                        }
                                    }
                                }) {
                                    HStack {
                                        Text("Todos os temas")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(
                                                viewModel.selectedLanguage == idioma.nome && 
                                                viewModel.selectedTheme == "Todos" ? 
                                                AppTheme.accentColor : AppTheme.textColor.opacity(0.8)
                                            )
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        // Mostrar percentual de progresso para todos os temas
                                        let progress = viewModel.getProgressForDeck(language: idioma.nome, theme: "Todos")
                                        if progress > 0 {
                                            Text("\(Int(progress))%")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppTheme.accentColor.opacity(0.8))
                                                .padding(.trailing, 8)
                                        }
                                        
                                        if viewModel.selectedLanguage == idioma.nome && viewModel.selectedTheme == "Todos" {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                viewModel.selectedLanguage == idioma.nome && 
                                                viewModel.selectedTheme == "Todos" ? 
                                                AppTheme.accentColor.opacity(0.08) : 
                                                Color.clear
                                            )
                                    )
                                }
                            }
                            .padding(.leading, 15)
                            .padding(.vertical, 5)
                            .background(AppTheme.accentColor.opacity(0.03))
                            .cornerRadius(8)
                            .transition(.slide)
                        }
                    }
                    
                    if idioma.nome != viewModel.idiomas.last?.nome {
                        Divider()
                            .background(AppTheme.accentColor.opacity(0.1))
                            .padding(.vertical, 5)
                    }
                }
                
                if viewModel.idiomas.isEmpty && !viewModel.isLoading {
                    Text("Nenhum idioma disponível")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(AppTheme.accentColor)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.vertical, 15)
        }
    }
    
    private var appInfo: some View {
        VStack(alignment: .center, spacing: 5) {
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
