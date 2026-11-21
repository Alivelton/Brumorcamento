import SwiftUI

public struct QuotesListView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Todos"
    @State private var showingNewQuoteSheet: Bool = false

    private let filterOptions = ["Todos", "Rascunho", "Aprovado", "Faturado", "Cancelado"]

    private var filteredQuotes: [Quote] {
        var list = dataStore.quotes

        if selectedFilter != "Todos" {
            list = list.filter { $0.status.rawValue == selectedFilter }
        }

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.numero.lowercased().contains(q) ||
                $0.clienteNome.lowercased().contains(q)
            }
        }

        return list.sorted { $0.dataCriacao > $1.dataCriacao }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtro rápido de status
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filterOptions, id: \.self) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedFilter == filter ? Color.accentColor : Color(uiColor: .secondarySystemFill))
                                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(uiColor: .systemBackground))

                List {
                    if filteredQuotes.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "Nenhum orçamento encontrado" : "Nenhum resultado para '\(searchText)'",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Toque em + para criar um novo orçamento com produtos, serviços e cobrança Mercado Pago.")
                        )
                    } else {
                        ForEach(filteredQuotes) { quote in
                            NavigationLink(destination: QuoteDetailView(quoteId: quote.id)) {
                                quoteRow(quote)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    dataStore.deleteQuote(id: quote.id)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if quote.status == .rascunho {
                                    Button {
                                        dataStore.approveQuote(id: quote.id)
                                    } label: {
                                        Label("Aprovar", systemImage: "hand.thumbsup.fill")
                                    }
                                    .tint(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Orçamentos")
            .searchable(text: $searchText, prompt: "Buscar por número ou cliente...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewQuoteSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewQuoteSheet) {
                NewQuoteView()
            }
        }
    }

    @ViewBuilder
    private func quoteRow(_ quote: Quote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(quote.numero)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                ColorBadge(quote.status.rawValue, color: colorForStatus(quote.status))
            }

            Text(quote.clienteNome)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Validade: \(quote.validade.brlDateString)")
                        .font(.caption)
                    if quote.isExpired {
                        Text("(Vencido)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                .foregroundColor(.secondary)

                Spacer()

                Text(quote.totalGeral.brlCurrency)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }

            if let mp = quote.mercadoPago, let link = mp.linkPagamento, !link.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Mercado Pago: \(mp.statusPagamento)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForStatus(_ status: QuoteStatus) -> Color {
        switch status {
        case .rascunho: return .gray
        case .enviado: return .blue
        case .aprovado: return .green
        case .faturado: return .purple
        case .cancelado: return .red
        }
    }
}
