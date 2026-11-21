import SwiftUI

public struct QuoteDetailView: View {
    let quoteId: String
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingCopiedAlert: Bool = false
    @State private var copiedMessage: String = ""
    @State private var showingShareSheet: Bool = false

    private var quote: Quote? {
        dataStore.quotes.first { $0.id == quoteId }
    }

    public init(quoteId: String) {
        self.quoteId = quoteId
    }

    public var body: some View {
        Group {
            if let quote = quote {
                List {
                    // MARK: - Cabeçalho do Orçamento
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(quote.numero)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                ColorBadge(quote.status.rawValue, color: colorForStatus(quote.status))
                            }

                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                                Text(quote.clienteNome)
                                    .font(.headline)
                            }

                            Divider()

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Emissão")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(quote.dataCriacao.brlDateString)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Validade (15 dias)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        Text(quote.validade.brlDateString)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        if quote.isExpired {
                                            Text("(Vencido)")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // MARK: - Itens
                    Section(header: Text("Itens (\(quote.itens.count))")) {
                        ForEach(quote.itens) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    ColorBadge(
                                        item.tipo.shortLabel,
                                        color: item.tipo == .material ? .blue : .purple
                                    )
                                    Text(item.descricao)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(item.total.brlCurrency)
                                        .fontWeight(.semibold)
                                }
                                HStack {
                                    Text("\(String(format: "%.1f", item.quantidade)) un. x \(item.precoUnitario.brlCurrency)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // MARK: - Resumo Financeiro
                    Section(header: Text("Totais do Orçamento")) {
                        HStack {
                            Text("Subtotal Materiais:")
                            Spacer()
                            Text(quote.subtotalMateriais.brlCurrency)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Subtotal Serviços:")
                            Spacer()
                            Text(quote.subtotalServicos.brlCurrency)
                                .foregroundColor(.secondary)
                        }
                        if quote.desconto > 0 {
                            HStack {
                                Text("Desconto Concedido:")
                                Spacer()
                                Text("- \(quote.desconto.brlCurrency)")
                                    .foregroundColor(.green)
                            }
                        }
                        HStack {
                            Text("TOTAL GERAL:")
                                .font(.headline)
                            Spacer()
                            Text(quote.totalGeral.brlCurrency)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 2)
                    }

                    // MARK: - Cobrança e Mercado Pago
                    Section(header: Text("Cobrança & Mercado Pago")) {
                        if let mp = quote.mercadoPago {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Mercado Pago", systemImage: "creditcard.fill")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    ColorBadge(mp.statusPagamento, color: mp.statusPagamento == "Pago" ? .green : .orange)
                                }

                                if let link = mp.linkPagamento, !link.isEmpty {
                                    HStack {
                                        Text("Link:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(link)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                        Button(action: {
                                            MercadoPagoService.shared.copyToClipboard(link)
                                            copiedMessage = "Link de pagamento copiado!"
                                            showingCopiedAlert = true
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.footnote)
                                        }
                                    }
                                }

                                if let pix = mp.codigoPixCopiaCola, !pix.isEmpty {
                                    Button(action: {
                                        MercadoPagoService.shared.copyToClipboard(pix)
                                        copiedMessage = "Código Pix Copia e Cola copiado com sucesso!"
                                        showingCopiedAlert = true
                                    }) {
                                        HStack {
                                            Image(systemName: "qrcode")
                                                .font(.headline)
                                            Text("Copiar Pix Copia e Cola")
                                                .fontWeight(.medium)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                }

                                // Botão de teste para simular retorno de pagamento via webhook/API
                                if mp.statusPagamento != "Pago" {
                                    Button(action: {
                                        dataStore.simulatePaymentConfirmation(quoteId: quote.id)
                                        copiedMessage = "Pagamento confirmado! Orçamento faturado e contas baixadas."
                                        showingCopiedAlert = true
                                    }) {
                                        Label("Simular Retorno de Pagamento Aprovado", systemImage: "checkmark.seal.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 4)
                        } else {
                            Button(action: {
                                dataStore.generateMercadoPagoForQuote(id: quote.id)
                            }) {
                                Label("Gerar Cobrança no Mercado Pago", systemImage: "link.badge.plus")
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    // MARK: - Ações de Status
                    Section(header: Text("Atualizar Status")) {
                        if quote.status == .rascunho {
                            Button(action: { dataStore.approveQuote(id: quote.id) }) {
                                Label("Aprovar Orçamento", systemImage: "hand.thumbsup.fill")
                                    .foregroundColor(.green)
                            }
                        }

                        if quote.status != .faturado {
                            Button(action: {
                                var q = quote
                                q.status = .faturado
                                dataStore.updateQuote(q)
                            }) {
                                Label("Marcar como Faturado", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }

                        if quote.status != .cancelado {
                            Button(role: .destructive, action: {
                                var q = quote
                                q.status = .cancelado
                                dataStore.updateQuote(q)
                            }) {
                                Label("Cancelar Orçamento", systemImage: "xmark.circle.fill")
                            }
                        }
                    }

                    // MARK: - Observações
                    if !quote.observacoes.isEmpty {
                        Section(header: Text("Observações")) {
                            Text(quote.observacoes)
                                .font(.footnote)
                        }
                    }
                }
                .navigationTitle(quote.numero)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { shareQuote(quote) }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .alert("Mercado Pago", isPresented: $showingCopiedAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(copiedMessage)
                }
            } else {
                Text("Orçamento não encontrado.")
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

    private func shareQuote(_ quote: Quote) {
        var text = """
        *ORÇAMENTO \(quote.numero)*
        Cliente: \(quote.clienteNome)
        Data: \(quote.dataCriacao.brlDateString)
        Validade: \(quote.validade.brlDateString) (15 dias)

        *ITENS:*
        """
        for item in quote.itens {
            text += "\n- [\(item.tipo.shortLabel)] \(item.descricao): \(item.quantidade)x = \(item.total.brlCurrency)"
        }
        text += """
        \n---------------------
        Materiais: \(quote.subtotalMateriais.brlCurrency)
        Serviços: \(quote.subtotalServicos.brlCurrency)
        Desconto: \(quote.desconto.brlCurrency)
        *TOTAL: \(quote.totalGeral.brlCurrency)*
        """

        if let mp = quote.mercadoPago, let link = mp.linkPagamento {
            text += "\n\n*Link para Pagamento (Mercado Pago / Pix):*\n\(link)"
            if let pix = mp.codigoPixCopiaCola {
                text += "\n\n*Pix Copia e Cola:*\n\(pix)"
            }
        }

        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true, completion: nil)
        }
    }
}
