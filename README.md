# 🃏 DonkeyCards iOS

![DonkeyCards Logo](DonkeyCards/Assets.xcassets/LOGO.imageset/DonkeyCards_LOGO%20Background%20Removed.png)

DonkeyCards é um aplicativo iOS moderno que traz a experiência do clássico jogo de cartas "Burro" para seu iPhone. Desenvolvido com SwiftUI e Firebase, oferece uma experiência multiplayer em tempo real com recursos modernos e uma interface intuitiva.

## 🚀 Funcionalidades

- **Multiplayer em Tempo Real**: Jogue com amigos em tempo real usando o Firebase
- **Modo Offline**: Jogue contra a CPU quando estiver offline
- **Sistema de Progresso**: Acompanhe seu progresso e desbloqueie conquistas
- **Tutorial Interativo**: Aprenda a jogar com um tutorial guiado
- **Personalização**: Escolha entre diferentes temas e personalizações
- **Estatísticas**: Acompanhe suas estatísticas de jogo
- **Modo Noturno**: Suporte completo a tema claro/escuro

## 🛠 Tecnologias

- SwiftUI
- Firebase (Firestore, Authentication)
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
├── Components/          # Componentes reutilizáveis
├── Models/             # Modelos de dados
├── Services/           # Serviços (Firebase, Game Logic)
├── Utils/              # Utilitários e extensões
├── Views/              # Telas principais
└── Resources/          # Recursos (imagens, sons)
```

## 🎮 Como Jogar

1. Inicie o jogo
2. Escolha entre modo online ou offline
3. Se online:
   - Crie ou entre em uma sala
   - Aguarde outros jogadores
4. Se offline:
   - Escolha o número de jogadores CPU
5. O jogo começará automaticamente
6. Siga as instruções na tela para jogar

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