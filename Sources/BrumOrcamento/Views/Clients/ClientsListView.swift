import SwiftUI

public struct ClientsListView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var searchText: String = ""
    @State private var showingNewClientSheet: Bool = false

    private var filteredClients: [Client] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return dataStore.clients.sorted { $0.nome < $1.nome }
        }
        let q = searchText.lowercased()
        return dataStore.clients.filter {
            $0.nome.lowercased().contains(q) ||
            $0.documento.contains(q) ||
            $0.email.lowercased().contains(q) ||
            $0.telefone.contains(q)
        }.sorted { $0.nome < $1.nome }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if filteredClients.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Nenhum cliente cadastrado" : "Nenhum cliente encontrado",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text(searchText.isEmpty ? "Toque em + para cadastrar seu primeiro cliente." : "Tente buscar por outro termo.")
                    )
                } else {
                    ForEach(filteredClients) { client in
                        NavigationLink(destination: ClientDetailView(clientId: client.id)) {
                            HStack(spacing: 12) {
                                // Avatar com iniciais
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Text(initials(for: client.nome))
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(client.nome)
                                        .font(.headline)
                                        .lineLimit(1)

                                    if !client.documento.isEmpty {
                                        Text("\(client.tipoDocumento): \(client.documento)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if !client.telefone.isEmpty {
                                        Text(client.telefone)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                dataStore.deleteClient(id: client.id)
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Clientes")
            .searchable(text: $searchText, prompt: "Buscar cliente ou documento...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewClientSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewClientSheet) {
                ClientFormView()
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            let f = parts[0].prefix(1)
            let s = parts[1].prefix(1)
            return "\(f)\(s)".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "CL"
    }
}
