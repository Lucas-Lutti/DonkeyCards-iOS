//
//  DonkeyCardsApp.swift
//  DonkeyCards
//
//  Created by Lucas Hinova on 05/04/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configuração para ignorar avisos do App Check
        let args = ProcessInfo.processInfo.arguments
        if !args.contains("-FIRDebugEnabled") {
            UserDefaults.standard.set("NO", forKey: "FirebaseAppCheckDebugConsoleEnabled")
            FirebaseConfiguration.shared.setLoggerLevel(.error) // Reduzir verbosidade
        }
        
        // Configuração básica do Firebase
        FirebaseApp.configure()
        
        // Configuração do Firestore
        let firestore = Firestore.firestore()
        let settings = firestore.settings
        // Não podemos desabilitar o AppCheck diretamente, mas podemos ajustar outras configurações
        // que podem ajudar a melhorar a performance
        settings.isPersistenceEnabled = true
        // Usar o valor máximo para cache - 100MB
        settings.cacheSizeBytes = 104857600
        firestore.settings = settings
        
        return true
    }
}

@main
struct DonkeyCardsApp: App {
    // Registrar o AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Outras configurações iniciais aqui, se necessário
        
        // Apenas para testes - Descomentar esta linha para resetar o tutorial
        UserPreferences.shared.resetPreferences()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark) // Garantir que o app sempre seja exibido em modo escuro
                .ignoresSafeArea()
        }
    }
}
