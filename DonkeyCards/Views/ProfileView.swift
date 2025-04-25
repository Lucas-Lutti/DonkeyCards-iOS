import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditingUsername = false
    @State private var editedUsername = ""
    @State private var isEditingProfileImage = false
    @State private var profileImageURL = ""
    
    // Centralizar alertas
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertAction: (() -> Void)? = nil
    
    @State private var showReauthView = false
    
    var body: some View {
        ZStack {
            // Fundo com gradiente
            backgroundView
                .ignoresSafeArea()
            
            // Conteúdo principal
            ScrollView {
                VStack(spacing: 25) {
                    // Cabeçalho e avatar
                    headerView
                        .padding(.top, 40)
                    
                    // Informações do perfil
                    if let user = viewModel.currentUser {
                        profileInfoView(user: user)
                    } else {
                        VStack(spacing: 20) {
                            Text("Dados indisponíveis")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            Button {
                                viewModel.refreshUserData()
                            } label: {
                                Text("Tentar carregar novamente")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppTheme.primaryColor.opacity(0.4))
                                    )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(AppTheme.primaryColor.opacity(0.3))
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                    
                    // Botões de ação
                    actionsView
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 30)
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.height > 50 {
                            dismiss()
                        }
                    }
            )
            
            // Overlay de loading
            if viewModel.isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppTheme.accentColor)
                    
                    Text("Processando...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor)
                        .padding(.top, 15)
                }
            }
        }
        // Alerta único centralizado
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if let action = alertAction {
                    action()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isEditingUsername) {
            EditUsernameView(username: viewModel.currentUser?.username ?? "", isPresented: $isEditingUsername) { newUsername in
                if !newUsername.isEmpty {
                    viewModel.updateUserData(username: newUsername) { _ in }
                }
            }
        }
        .sheet(isPresented: $isEditingProfileImage) {
            EditProfileImageView(imageURL: viewModel.currentUser?.profileImageURL ?? "", isPresented: $isEditingProfileImage) { newURL in
                viewModel.updateUserData(profileImageURL: newURL) { _ in }
            }
        }
        .sheet(isPresented: $showReauthView) {
            ReauthenticationView(isPresented: $showReauthView) { email, password in
                viewModel.reauthenticateAndDeleteAccount(email: email, password: password)
            }
        }
        .onAppear {
            print("📱 [ProfileView] onAppear")
            
            // Inscrever nos eventos de alerta do ViewModel
            viewModel.alertCallback = { title, message, action in
                self.alertTitle = title
                self.alertMessage = message
                self.alertAction = action
                self.showAlert = true
            }
        }
        .onChange(of: viewModel.isInitialized) { initialized in
            if initialized {
                print("📱 [ProfileView] Initialization complete, checking auth status")
                if !viewModel.checkAuthenticationStatus() {
                    print("📱 [ProfileView] Authentication check failed after init, will dismiss")
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            // Remover callback quando a view desaparecer
            viewModel.alertCallback = nil
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        ZStack {
            // Gradient base que preenche toda a tela
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    Color(red: 0.03, green: 0.18, blue: 0.08) // Verde mais escuro
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Elementos decorativos
            Circle()
                .fill(AppTheme.accentColor.opacity(0.08))
                .frame(width: UIScreen.main.bounds.width * 0.75)
                .position(x: UIScreen.main.bounds.width * 0.85, y: UIScreen.main.bounds.height * 0.2)
                .blur(radius: 5)
            
            Circle()
                .fill(AppTheme.accentColor.opacity(0.1))
                .frame(width: UIScreen.main.bounds.width * 0.5)
                .position(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.28)
                .blur(radius: 4)
            
            Circle()
                .fill(AppTheme.accentColor.opacity(0.06))
                .frame(width: UIScreen.main.bounds.width * 0.6)
                .position(x: UIScreen.main.bounds.width * 0.1, y: UIScreen.main.bounds.height * 0.7)
                .blur(radius: 5)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Avatar com botão para editar
            ZStack(alignment: .bottomTrailing) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryColor.opacity(0.3))
                        .frame(width: 110, height: 110)
                    
                    if let profileImageURL = viewModel.currentUser?.profileImageURL, !profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: profileImageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.accentColor)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
                .frame(width: 110, height: 110)
            }
            .padding(.bottom, 10)
            
            // Título
            Text("Seu Perfil")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.accentColor)
                .padding(.bottom, 5)
            
            // Nome de usuário com opção de editar
            if let username = viewModel.currentUser?.username {
                HStack {
                    Text(username)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.textColor)
                    
                    Button {
                        // Preparar para edição do nome de usuário
                        editedUsername = username
                        isEditingUsername = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }
    
    private func profileInfoView(user: UserModel) -> some View {
        VStack(spacing: 25) {
            // Container com as informações
            VStack(spacing: 20) {
                // Username
                infoRow(title: "Username", value: user.username)
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.2))
                
                // Ouro
                infoRow(title: "Ouro", value: "\(user.gold)")
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.2))
                
                // Status premium
                infoRow(title: "Status Premium", value: user.isFull ? "Ativo" : "Inativo")
            }
            .padding(.vertical, 25)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppTheme.primaryColor.opacity(0.3))
            )
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textColor)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var actionsView: some View {
        VStack(spacing: 15) {
            // Botão para voltar (agora com destaque)
            Button {
                dismiss()
            } label: {
                Text("Voltar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.gradientAccent)
                    .cornerRadius(12)
                    .shadow(color: AppTheme.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            
            // Botão de logout (agora sem destaque)
            Button {
                viewModel.logout()
            } label: {
                Text("Sair da conta")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.top, 5)
            
            // Botão para excluir conta
            Button {
                alertTitle = "Confirmar exclusão"
                alertMessage = "Esta ação não pode ser desfeita. Todos os seus dados serão excluídos permanentemente."
                alertAction = {
                    showReauthView = true
                }
                showAlert = true
            } label: {
                Text("Excluir conta")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.errorColor)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - Vistas auxiliares para edição

struct EditUsernameView: View {
    @State var username: String
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
    
    var body: some View {
        ZStack {
            // Fundo
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    Color(red: 0.03, green: 0.18, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("Editar Nome de Usuário")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.top, 30)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nome de Usuário")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor)
                    
                    TextField("", text: $username)
                        .padding()
                        .background(AppTheme.primaryColor.opacity(0.3))
                        .foregroundColor(AppTheme.textColor)
                        .cornerRadius(10)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 30)
                
                HStack(spacing: 15) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textColor.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primaryColor.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        onSave(username)
                        isPresented = false
                    } label: {
                        Text("Salvar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.gradientAccent)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
    }
}

struct EditProfileImageView: View {
    @State var imageURL: String
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
    
    var body: some View {
        ZStack {
            // Fundo
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    Color(red: 0.03, green: 0.18, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("Editar Foto de Perfil")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.top, 30)
                
                // Pré-visualização da imagem
                if !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(AppTheme.primaryColor.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppTheme.accentColor)
                            )
                    }
                    .padding(.bottom, 15)
                } else {
                    Circle()
                        .fill(AppTheme.primaryColor.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.accentColor)
                        )
                        .padding(.bottom, 15)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("URL da Imagem")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textColor)
                    
                    TextField("", text: $imageURL)
                        .padding()
                        .background(AppTheme.primaryColor.opacity(0.3))
                        .foregroundColor(AppTheme.textColor)
                        .cornerRadius(10)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 30)
                
                HStack(spacing: 15) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textColor.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primaryColor.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        onSave(imageURL)
                        isPresented = false
                    } label: {
                        Text("Salvar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.02, green: 0.15, blue: 0.07))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.gradientAccent)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                
                // Botão para limpar a imagem
                Button {
                    imageURL = ""
                } label: {
                    Text("Remover imagem")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.errorColor)
                }
                .padding(.top, 5)
                
                Spacer()
            }
        }
    }
}

// Vista para reautenticação do usuário
struct ReauthenticationView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @Binding var isPresented: Bool
    var onAuthenticate: (String, String) -> Void
    
    var body: some View {
        ZStack {
            // Fundo
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    Color(red: 0.03, green: 0.18, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("Confirmar Exclusão")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.top, 30)
                
                Text("Por razões de segurança, você precisa confirmar suas credenciais antes de excluir sua conta.")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Campo de email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textColor)
                        
                        TextField("", text: $email)
                            .padding()
                            .background(AppTheme.primaryColor.opacity(0.3))
                            .foregroundColor(AppTheme.textColor)
                            .cornerRadius(10)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    
                    // Campo de senha
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Senha")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textColor)
                        
                        SecureField("", text: $password)
                            .padding()
                            .background(AppTheme.primaryColor.opacity(0.3))
                            .foregroundColor(AppTheme.textColor)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                
                HStack(spacing: 15) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textColor.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primaryColor.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        onAuthenticate(email, password)
                        isPresented = false
                    } label: {
                        Text("Excluir Conta")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.errorColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                Spacer()
            }
        }
    }
} 
