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

## 🛠 Tecnologias

- SwiftUI
- Firebase Firestore
- Combine
- Swift Package Manager

## 📱 Requisitos

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## 🚀 Como Executar

1. Clone o repositório
```bash
git clone https://github.com/Lucas-Lutti/DonkeyCards-iOS.git
```

2. Abra o projeto no Xcode
```bash
cd DonkeyCards-iOS
open DonkeyCards.xcodeproj
```

3. Instale as dependências
- O projeto usa Swift Package Manager, as dependências serão baixadas automaticamente

4. Configure o Firebase
- Crie um projeto no [Firebase Console](https://console.firebase.google.com)
- Baixe o arquivo `GoogleService-Info.plist`
- Substitua o arquivo existente no projeto

5. Execute o projeto
- Selecione um simulador ou dispositivo
- Pressione ⌘R para executar

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
   - Deslize para a esquerda/direita para navegar entre os cartões
   - Toque no cartão para virá-lo e ver a resposta
   - Deslize para cima para marcar como correto
   - Deslize para baixo para marcar como incorreto

3. **Gerenciar Decks**:
   - Acesse o menu lateral para filtrar decks por idioma
   - Visualize detalhes do deck atual
   - Acompanhe seu progresso em cada deck

4. **Sincronização**:
   - Os dados são sincronizados automaticamente com o Firebase
   - O aplicativo funciona offline, sincronizando quando a conexão estiver disponível

## 🤝 Contribuindo

1. Faça um Fork do projeto
2. Crie uma Branch para sua Feature (`git checkout -b feature/AmazingFeature`)
3. Faça o Commit das suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Faça o Push para a Branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👥 Autores

- **Lucas Lutti** - *Desenvolvimento inicial* - [Lucas-Lutti](https://github.com/Lucas-Lutti)

## 🙏 Agradecimentos

- Equipe do Firebase
- Comunidade SwiftUI
- Todos os contribuidores e testadores

## 📞 Suporte

Se você encontrar algum problema ou tiver sugestões, por favor abra uma issue no GitHub.

---

⭐️ From [Lucas-Lutti](https://github.com/Lucas-Lutti) with ❤️ 