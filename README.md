# 🃏 DonkeyCards iOS

<div align="center">
  <img src="DonkeyCards/Assets.xcassets/LOGO.imageset/DonkeyCards_LOGO%20Background%20Removed.png" alt="DonkeyCards Logo" width="200"/>
</div>

DonkeyCards é um aplicativo iOS para estudo de idiomas através de cartões de memória (flashcards). Desenvolvido com SwiftUI e Firebase, o aplicativo permite que os usuários estudem vocabulário em diferentes idiomas e temas, com um sistema de acompanhamento de progresso e interface intuitiva.

## 🚀 Funcionalidades

- **Decks de Cartões**: Organize seus estudos por idioma e tema
- **Sistema de Progresso**: Acompanhe seu desempenho em cada deck
- **Tutorial Interativo**: Aprenda a usar o aplicativo com um guia passo a passo
- **Modo Offline**: Acesse seus decks mesmo sem conexão com a internet
- **Sincronização com Firebase**: Mantenha seus dados atualizados em tempo real
- **Interface Intuitiva**: Design moderno com gestos para navegar entre os cartões
- **Tema Personalizado**: Interface com cores vibrantes e tema escuro
- **Sistema de Cache Inteligente**: Controle de atualizações para economizar dados e melhorar performance

## 🛠 Tecnologias

- SwiftUI
- Firebase Firestore
- Combine
- Swift Package Manager

## 📱 Requisitos

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## 📁 Estrutura do Projeto

```
DonkeyCards/
├── Components/          # Componentes reutilizáveis (DeckDetailModal, TutorialOverlay)
├── Models/             # Modelos de dados (Card, Deck)
├── Services/           # Serviços (DataService, FirestoreService, ProgressManager)
├── Utils/              # Utilitários (Theme, UserPreferences)
├── ViewModels/         # ViewModels (MainViewModel)
├── Views/              # Telas principais (MainView, CardView, SideMenuView)
└── Resources/          # Recursos (imagens, sons)
```

## 🎮 Como Usar

1. **Iniciar o Aplicativo**:
   - Na primeira execução, um tutorial interativo guiará você pelo aplicativo
   - Você pode pular o tutorial a qualquer momento

2. **Navegar pelos Decks**:
   - Toque no cartão para virá-lo e ver a resposta
   - Deslize para a direita para marcar como correto
   - Deslize para a esquerda para marcar como incorreto

3. **Gerenciar Decks**:
   - Acesse o menu lateral para filtrar decks por idioma
   - Visualize detalhes do deck atual
   - Acompanhe seu progresso em cada deck

4. **Sincronização**:
   - Os dados são sincronizados automaticamente com o Firebase
   - O aplicativo funciona offline, sincronizando quando a conexão estiver disponível

## 🔄 Sistema de Atualização de Dados

O DonkeyCards implementa um sistema inteligente de atualização de dados para economizar consumo de rede e melhorar a performance:

- **Atualização de Idiomas**: 
  - Ao abrir o menu lateral, o aplicativo verifica se já passou 1 hora desde a última consulta de idiomas
  - Só consulta o Firestore se o tempo mínimo tiver passado, caso contrário utiliza dados em cache

- **Atualização de Temas e Cards**:
  - Ao selecionar um tema, o aplicativo verifica se já passou 3 horas desde a última atualização
  - Só consulta os cards do Firestore se o intervalo de 3 horas tiver passado
  - Cards são armazenados por idioma no cache local para acesso rápido

- **Persistência de Dados**:
  - Todos os dados são salvos localmente utilizando UserDefaults
  - O progresso de estudo é mantido mesmo se o aplicativo ficar offline
  - A sincronização ocorre automaticamente quando necessário

Este sistema garante que o aplicativo permaneça rápido e responsivo, enquanto mantém os dados atualizados de forma eficiente.

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes. 