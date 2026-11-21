import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingResetAlert: Bool = false
    @State private var showingExportSheet: Bool = false
    @State private var exportURL: URL? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Estatísticas Locais")) {
                    HStack {
                        Label("Clientes", systemImage: "person.2.fill")
                        Spacer()
                        Text("\(dataStore.clients.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Orçamentos", systemImage: "doc.text.fill")
                        Spacer()
                        Text("\(dataStore.quotes.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Cobranças / A Receber", systemImage: "creditcard.fill")
                        Spacer()
                        Text("\(dataStore.receivables.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Persistência e Backup")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Armazenamento Local")
                            .font(.headline)
                        Text("Os dados são mantidos e salvos automaticamente no sandbox local do app (`Documents/dados_brum.json`).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)

                    Button(action: prepareExport) {
                        Label("Exportar Banco de Dados (JSON)", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive, action: { showingResetAlert = true }) {
                        Label("Restaurar Dados Originais (Seed Backup)", systemImage: "arrow.counterclockwise")
                    }
                }

                Section(header: Text("Sobre o Aplicativo")) {
                    HStack {
                        Text("Versão")
                        Spacer()
                        Text("1.0.0 (xtool build)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Build System")
                        Spacer()
                        Text("SwiftPM + xtool CLI")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Área do Cliente")
                        Spacer()
                        Text("Externa (Separada)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Configurações")
            .alert("Restaurar Dados?", isPresented: $showingResetAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Restaurar", role: .destructive) {
                    dataStore.resetToInitialBackup()
                }
            } message: {
                Text("Esta ação recarregará os registros originais do backup JSON e substituirá as alterações locais não exportadas.")
            }
        }
    }

    private func prepareExport() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let file = docs.appendingPathComponent("dados_brum.json")
        if FileManager.default.fileExists(atPath: file.path) {
            let av = UIActivityViewController(activityItems: [file], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(av, animated: true, completion: nil)
            }
        }
    }
}
