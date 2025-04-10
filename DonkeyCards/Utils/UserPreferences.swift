import SwiftUI

enum UserPreferenceKeys {
    static let hasCompletedTutorial = "hasCompletedTutorial"
    static let deckProgressData = "deckProgressData"
}

class UserPreferences {
    // Singleton para acesso global
    static let shared = UserPreferences()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // Verifica se o usuário já completou o tutorial
    var hasCompletedTutorial: Bool {
        get {
            return userDefaults.bool(forKey: UserPreferenceKeys.hasCompletedTutorial)
        }
        set {
            userDefaults.set(newValue, forKey: UserPreferenceKeys.hasCompletedTutorial)
        }
    }
    
    // Marca o tutorial como concluído
    func completeTutorial() {
        hasCompletedTutorial = true
    }
    
    // APENAS PARA TESTES: Reseta as preferências
    func resetPreferences() {
        hasCompletedTutorial = false
    }
} 