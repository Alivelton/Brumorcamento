import SwiftUI

public struct ReceivablesListView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var selectedFilter: String = "Pendentes"
    @State private var searchText: String = ""

    // Sheet de Baixa Rápida
    @State private var receivableToPay: Receivable? = nil
    @State private var quickPayMethod: String = "Mercado Pago (Pix)"
    @State private var quickPayDate: Date = Date()

    private let filterOptions = ["Pendentes", "Pagas", "Todas"]

    private var filteredReceivables: [Receivable] {
        var list = dataStore.receivables

        switch selectedFilter {
        case "Pendentes":
            list = list.filter { $0.status == .pendente }
        case "Pagas":
            list = list.filter { $0.status == .pago }
        default:
            break
        }

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.clienteNome.lowercased().contains(q) ||
                $0.descricao.lowercased().contains(q) ||
                ($0.orcamentoNumero?.lowercased().contains(q) ?? false)
            }
        }

        // Ordenar pendentes por data de vencimento crescente (os que vencem antes primeiro)
        // e pagos por data decrescente
        if selectedFilter == "Pendentes" {
            return list.sorted { $0.dataVencimento < $1.dataVencimento }
        } else {
            return list.sorted { ($0.dataPagamento ?? $0.dataVencimento) > ($1.dataPagamento ?? $1.dataVencimento) }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Cards de Totais Financeiros (A Receber vs Recebido)
                HStack(spacing: 12) {
                    StatCardView(
                        title: "A RECEBER",
                        amount: dataStore.totalAReceber,
                        icon: "clock.badge.exclamationmark.fill",
                        color: .orange,
                        subtitle: "\(dataStore.receivables.filter { $0.status == .pendente }.count) pendente(s)"
                    )

                    StatCardView(
                        title: "RECEBIDO",
                        amount: dataStore.totalRecebido,
                        icon: "checkmark.circle.fill",
                        color: .green,
                        subtitle: "\(dataStore.receivables.filter { $0.status == .pago }.count) liquidado(s)"
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Filtro rápido
                Picker("Filtro", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 6)

                // MARK: - Lista de Cobranças / Parcelas
                List {
                    if filteredReceivables.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "Nenhuma cobrança \(selectedFilter.lowercased())" : "Nenhum resultado para '\(searchText)'",
                            systemImage: "creditcard.and.123",
                            description: Text("As cobranças são geradas automaticamente ao criar ou aprovar um orçamento.")
                        )
                    } else {
                        ForEach(filteredReceivables) { rec in
                            NavigationLink(destination: ReceivableDetailView(receivableId: rec.id)) {
                                receivableRow(rec)
                            }
                            .swipeActions(edge: .leading) {
                                if rec.status == .pendente {
                                    Button {
                                        receivableToPay = rec
                                        quickPayDate = Date()
                                    } label: {
                                        Label("Dar Baixa", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.green)
                                } else {
                                    Button {
                                        dataStore.reopenReceivable(id: rec.id)
                                    } label: {
                                        Label("Reabrir", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.orange)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    dataStore.deleteReceivable(id: rec.id)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("A Receber")
            .searchable(text: $searchText, prompt: "Buscar cliente ou descrição...")
            .sheet(item: $receivableToPay) { rec in
                quickBaixaSheet(rec)
            }
        }
    }

    @ViewBuilder
    private func receivableRow(_ rec: Receivable) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Ícone de Status
            Image(systemName: rec.status == .pago ? "checkmark.seal.fill" : (rec.isOverdue ? "exclamationmark.circle.fill" : "clock.fill"))
                .font(.title2)
                .foregroundColor(rec.status == .pago ? .green : (rec.isOverdue ? .red : .orange))
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(rec.descricao)
                    .font(.headline)
                    .lineLimit(1)

                Text(rec.clienteNome)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("Venc: \(rec.dataVencimento.brlDateString)")
                            .font(.caption)
                    }
                    .foregroundColor(rec.isOverdue ? .red : .secondary)

                    if rec.status == .pago, let payDate = rec.dataPagamento {
                        Text("• Pago em \(payDate.brlDateString)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(rec.valor.brlCurrency)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if rec.status == .pendente {
                    Button(action: {
                        receivableToPay = rec
                        quickPayDate = Date()
                    }) {
                        Text("Dar Baixa")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    ColorBadge("Pago", color: .green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func quickBaixaSheet(_ rec: Receivable) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Cobrança Selecionada")) {
                    Text(rec.descricao)
                        .font(.headline)
                    Text("Cliente: \(rec.clienteNome)")
                        .foregroundColor(.secondary)
                    HStack {
                        Text("Valor:")
                        Spacer()
                        Text(rec.valor.brlCurrency)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                }

                Section(header: Text("Detalhes da Baixa")) {
                    DatePicker("Data do Recebimento", selection: $quickPayDate, displayedComponents: [.date, .hourAndMinute])

                    Picker("Meio de Pagamento", selection: $quickPayMethod) {
                        Text("Mercado Pago (Pix)").tag("Mercado Pago (Pix)")
                        Text("Mercado Pago (Cartão)").tag("Mercado Pago (Cartão)")
                        Text("Mercado Pago (Boleto)").tag("Mercado Pago (Boleto)")
                        Text("Pix Direto").tag("Pix Direto")
                        Text("Transferência Bancária").tag("Transferência Bancária")
                        Text("Dinheiro").tag("Dinheiro")
                    }
                }
            }
            .navigationTitle("Dar Baixa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { receivableToPay = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar Baixa") {
                        dataStore.markReceivableAsPaid(
                            id: rec.id,
                            paymentMethod: quickPayMethod,
                            date: quickPayDate
                        )
                        receivableToPay = nil
                    }
                    .fontWeight(.bold)
                    .tint(.green)
                }
            }
        }
    }
}
