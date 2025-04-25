struct DonkeyCardsApp: App {
    // Registrar o AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Serviço de autenticação como objeto compartilhado com a UI
    @StateObject private var authService = AuthService.shared
    
    init() {
        print("📱 [App] Initializing DonkeyCards")
        
        // Outras configurações iniciais aqui, se necessário
        
        // Descomentar esta linha para resetar o tutorial
        // UserPreferences.shared.resetPreferences()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark) // Garantir que o app sempre seja exibido em modo escuro
                .ignoresSafeArea()
                .environmentObject(authService) // Disponibilizar o serviço de autenticação para toda a UI
                .onAppear {
                    print("📱 [App] MainView appeared")
                }
        }
    }
} 