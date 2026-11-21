import SwiftUI

public struct ClientDetailView: View {
    let clientId: String
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingEditSheet: Bool = false

    private var client: Client? {
        dataStore.clients.first { $0.id == clientId }
    }

    private var clientQuotes: [Quote] {
        dataStore.quotes.filter { $0.clienteId == clientId }
    }

    private var clientReceivables: [Receivable] {
        dataStore.receivables.filter { $0.clienteId == clientId }
    }

    public init(clientId: String) {
        self.clientId = clientId
    }

    public var body: some View {
        Group {
            if let client = client {
                List {
                    // Seção de Contato e Ações Rápidas
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(client.nome)
                                .font(.title2)
                                .fontWeight(.bold)

                            if !client.documento.isEmpty {
                                Text("\(client.tipoDocumento): \(client.documento)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        // Botões de Ação Rápida
                        HStack(spacing: 20) {
                            if !client.telefone.isEmpty {
                                Button(action: { dialPhone(client.telefone) }) {
                                    VStack {
                                        Image(systemName: "phone.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.green)
                                        Text("Ligar")
                                            .font(.caption2)
                                    }
                                }
                                .buttonStyle(.plain)

                                Button(action: { openWhatsApp(client.telefone) }) {
                                    VStack {
                                        Image(systemName: "message.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.green)
                                        Text("WhatsApp")
                                            .font(.caption2)
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            if !client.email.isEmpty {
                                Button(action: { sendEmail(client.email) }) {
                                    VStack {
                                        Image(systemName: "envelope.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                        Text("E-mail")
                                            .font(.caption2)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }

                    // Detalhes de Endereço
                    if !client.endereco.inlineText.isEmpty {
                        Section(header: Text("Endereço")) {
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                Text(client.endereco.inlineText)
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Histórico de Orçamentos
                    Section(header: Text("Orçamentos (\(clientQuotes.count))")) {
                        if clientQuotes.isEmpty {
                            Text("Nenhum orçamento cadastrado.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(clientQuotes) { quote in
                                NavigationLink(destination: QuoteDetailView(quoteId: quote.id)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(quote.numero)
                                                .fontWeight(.semibold)
                                            Text(quote.dataCriacao.brlDateString)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(quote.totalGeral.brlCurrency)
                                                .fontWeight(.bold)
                                            ColorBadge(quote.status.rawValue, color: colorForStatus(quote.status))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Histórico de Cobranças
                    Section(header: Text("A Receber / Pagamentos (\(clientReceivables.count))")) {
                        if clientReceivables.isEmpty {
                            Text("Nenhuma cobrança vinculada.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(clientReceivables) { rec in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(rec.descricao)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Venc: \(rec.dataVencimento.brlDateString)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(rec.valor.brlCurrency)
                                            .fontWeight(.bold)
                                        ColorBadge(rec.status.rawValue, color: rec.status == .pago ? .green : .orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Detalhes do Cliente")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Editar") {
                            showingEditSheet = true
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    ClientFormView(editingClient: client)
                }
            } else {
                Text("Cliente não encontrado.")
                    .foregroundColor(.secondary)
            }
        }
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

    private func dialPhone(_ phone: String) {
        let clean = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(clean)") {
            UIApplication.shared.open(url)
        }
    }

    private func openWhatsApp(_ phone: String) {
        let clean = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        var fullNumber = clean
        if !fullNumber.hasPrefix("55") && (fullNumber.count == 10 || fullNumber.count == 11) {
            fullNumber = "55\(fullNumber)"
        }
        if let url = URL(string: "https://wa.me/\(fullNumber)") {
            UIApplication.shared.open(url)
        }
    }

    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}
