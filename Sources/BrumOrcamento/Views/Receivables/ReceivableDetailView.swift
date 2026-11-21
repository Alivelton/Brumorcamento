import SwiftUI

public struct ReceivableDetailView: View {
    let receivableId: String
    @EnvironmentObject private var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingMarkPaidSheet: Bool = false
    @State private var paymentMethod: String = "Mercado Pago (Pix)"
    @State private var paymentDate: Date = Date()
    @State private var showingCopiedAlert: Bool = false

    private var receivable: Receivable? {
        dataStore.receivables.first { $0.id == receivableId }
    }

    private let availableMethods = [
        "Mercado Pago (Pix)",
        "Mercado Pago (Cartão)",
        "Mercado Pago (Boleto)",
        "Pix Direto",
        "Transferência Bancária",
        "Dinheiro"
    ]

    public init(receivableId: String) {
        self.receivableId = receivableId
    }

    public var body: some View {
        Group {
            if let rec = receivable {
                List {
                    // MARK: - Resumo da Cobrança
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(rec.descricao)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                                ColorBadge(
                                    rec.status.rawValue,
                                    color: rec.status == .pago ? .green : (rec.isOverdue ? .red : .orange)
                                )
                            }

                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                                Text(rec.clienteNome)
                                    .font(.subheadline)
                            }

                            if let orcNum = rec.orcamentoNumero {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.secondary)
                                    Text("Origem: \(orcNum)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Divider()

                            HStack {
                                Text("Valor da Cobrança:")
                                    .font(.subheadline)
                                Spacer()
                                Text(rec.valor.brlCurrency)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                            }

                            HStack {
                                Text("Data de Vencimento:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text(rec.dataVencimento.brlDateString)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    if rec.isOverdue {
                                        Text("(Atrasado)")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                            }

                            if rec.status == .pago, let payDate = rec.dataPagamento {
                                HStack {
                                    Text("Data do Pagamento:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(payDate.brlDateTimeString)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                if let method = rec.formaPagamento {
                                    HStack {
                                        Text("Forma de Pagamento:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(method)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // MARK: - Ações de Baixa
                    Section(header: Text("Gestão de Baixa")) {
                        if rec.status == .pendente {
                            Button(action: { showingMarkPaidSheet = true }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Dar Baixa (Marcar como Pago)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                        } else {
                            Button(action: { dataStore.reopenReceivable(id: rec.id) }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Estornar / Reabrir Cobrança")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }

                    // MARK: - Mercado Pago / Pix
                    if rec.status == .pendente {
                        Section(header: Text("Cobrança Mercado Pago")) {
                            let mpData = MercadoPagoService.shared.generateCharge(for: rec)

                            if let pix = mpData.codigoPixCopiaCola {
                                Button(action: {
                                    MercadoPagoService.shared.copyToClipboard(pix)
                                    showingCopiedAlert = true
                                }) {
                                    Label("Copiar Pix Copia e Cola", systemImage: "qrcode")
                                }
                            }

                            if let link = mpData.linkPagamento {
                                Button(action: {
                                    MercadoPagoService.shared.copyToClipboard(link)
                                    showingCopiedAlert = true
                                }) {
                                    Label("Copiar Link de Pagamento", systemImage: "link")
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Detalhes da Cobrança")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showingMarkPaidSheet) {
                    markPaidSheetView(rec)
                }
                .alert("Copiado!", isPresented: $showingCopiedAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Código ou link copiado para a área de transferência.")
                }
            } else {
                Text("Cobrança não encontrada.")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func markPaidSheetView(_ rec: Receivable) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Dados do Pagamento")) {
                    HStack {
                        Text("Valor:")
                        Spacer()
                        Text(rec.valor.brlCurrency)
                            .fontWeight(.bold)
                    }

                    DatePicker("Data do Recebimento", selection: $paymentDate, displayedComponents: [.date, .hourAndMinute])

                    Picker("Forma de Pagamento", selection: $paymentMethod) {
                        ForEach(availableMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                }
            }
            .navigationTitle("Confirmar Baixa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingMarkPaidSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar Baixa") {
                        dataStore.markReceivableAsPaid(
                            id: rec.id,
                            paymentMethod: paymentMethod,
                            date: paymentDate
                        )
                        showingMarkPaidSheet = false
                    }
                    .fontWeight(.bold)
                    .tint(.green)
                }
            }
        }
    }
}
