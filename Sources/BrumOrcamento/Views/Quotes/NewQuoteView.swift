import SwiftUI

public struct NewQuoteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore

    @State private var selectedClientId: String = ""
    @State private var showingQuickClientSheet: Bool = false

    @State private var quoteNumber: String = ""
    @State private var dataCriacao: Date = Date()
    @State private var validade: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    @State private var observacoes: String = "Validade de 15 dias. Pagamento via Mercado Pago ou Pix."

    // Itens
    @State private var items: [QuoteItem] = []
    @State private var showingAddItemSheet: Bool = false
    @State private var newItemType: ItemType = .material
    @State private var newItemDesc: String = ""
    @State private var newItemQty: String = "1"
    @State private var newItemPrice: String = ""

    // Desconto
    @State private var descontoText: String = "0"

    // Mercado Pago
    @State private var autoGenerateMercadoPago: Bool = true
    @State private var autoCreateReceivable: Bool = true

    public init() {}

    private var subtotalMateriais: Double {
        items.filter { $0.tipo == .material }.reduce(0) { $0 + ($1.quantidade * $1.precoUnitario) }
    }

    private var subtotalServicos: Double {
        items.filter { $0.tipo == .servico }.reduce(0) { $0 + ($1.quantidade * $1.precoUnitario) }
    }

    private var descontoValue: Double {
        Double(descontoText.replacingOccurrences(of: ",", with: ".")) ?? 0.0
    }

    private var totalGeral: Double {
        max(0.0, (subtotalMateriais + subtotalServicos) - descontoValue)
    }

    private var selectedClient: Client? {
        dataStore.clients.first { $0.id == selectedClientId }
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Cliente
                Section(header: Text("Cliente")) {
                    if dataStore.clients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nenhum cliente cadastrado ainda.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("+ Cadastrar Cliente Rápido") {
                                showingQuickClientSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Picker("Selecionar Cliente *", selection: $selectedClientId) {
                            Text("Selecione um cliente").tag("")
                            ForEach(dataStore.clients) { c in
                                Text(c.nome).tag(c.id)
                            }
                        }

                        Button(action: { showingQuickClientSheet = true }) {
                            Label("Cadastrar Novo Cliente", systemImage: "person.crop.circle.badge.plus")
                                .font(.subheadline)
                        }
                    }

                    if let c = selectedClient {
                        VStack(alignment: .leading, spacing: 4) {
                            if !c.documento.isEmpty {
                                Text("\(c.tipoDocumento): \(c.documento)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if !c.telefone.isEmpty {
                                Text("Tel: \(c.telefone)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // MARK: - Dados do Orçamento
                Section(header: Text("Informações do Orçamento")) {
                    HStack {
                        Text("Número")
                        Spacer()
                        TextField("Automático", text: $quoteNumber)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }

                    DatePicker("Data de Emissão", selection: $dataCriacao, displayedComponents: .date)
                    DatePicker("Validade (15 dias padrão)", selection: $validade, displayedComponents: .date)
                }

                // MARK: - Itens (Materiais e Serviços)
                Section(header: Text("Itens (Produtos, Materiais e Serviços)")) {
                    if items.isEmpty {
                        Text("Nenhum item adicionado ao orçamento.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(items) { item in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        ColorBadge(
                                            item.tipo.shortLabel,
                                            color: item.tipo == .material ? .blue : .purple
                                        )
                                        Text(item.descricao)
                                            .fontWeight(.medium)
                                    }
                                    Text("\(String(format: "%.1f", item.quantidade)) x \(item.precoUnitario.brlCurrency)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(item.total.brlCurrency)
                                    .fontWeight(.semibold)
                            }
                        }
                        .onDelete(perform: deleteItem)
                    }

                    HStack(spacing: 12) {
                        Button(action: {
                            newItemType = .material
                            showingAddItemSheet = true
                        }) {
                            Label("Material / Produto", systemImage: "cube.box.fill")
                                .font(.footnote)
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            newItemType = .servico
                            showingAddItemSheet = true
                        }) {
                            Label("Serviço / Mão de Obra", systemImage: "wrench.and.screwdriver.fill")
                                .font(.footnote)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Desconto e Totais
                Section(header: Text("Valores e Descontos")) {
                    HStack {
                        Text("Desconto (R$)")
                        Spacer()
                        TextField("0,00", text: $descontoText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }

                    HStack {
                        Text("Subtotal Materiais:")
                        Spacer()
                        Text(subtotalMateriais.brlCurrency)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Subtotal Serviços:")
                        Spacer()
                        Text(subtotalServicos.brlCurrency)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("TOTAL GERAL:")
                            .font(.headline)
                        Spacer()
                        Text(totalGeral.brlCurrency)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Mercado Pago & Cobrança
                Section(header: Text("Cobrança & Mercado Pago")) {
                    Toggle("Gerar cobrança Pix / Mercado Pago", isOn: $autoGenerateMercadoPago)
                    Toggle("Lançar automaticamente em 'A Receber'", isOn: $autoCreateReceivable)
                }

                // MARK: - Observações
                Section(header: Text("Observações e Condições")) {
                    TextEditor(text: $observacoes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Novo Orçamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { saveQuote() }
                        .disabled(selectedClientId.isEmpty || items.isEmpty)
                        .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingQuickClientSheet) {
                ClientFormView { createdClient in
                    selectedClientId = createdClient.id
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                addItemSheetView
            }
            .onAppear {
                if quoteNumber.isEmpty {
                    let nextNum = dataStore.quotes.count + 1
                    quoteNumber = String(format: "ORC-2026-%03d", nextNum)
                }
                if selectedClientId.isEmpty, let firstClient = dataStore.clients.first {
                    selectedClientId = firstClient.id
                }
            }
        }
    }

    private var addItemSheetView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tipo do Item")) {
                    Picker("Tipo", selection: $newItemType) {
                        Text("Produto / Material").tag(ItemType.material)
                        Text("Serviço / Mão de Obra").tag(ItemType.servico)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Detalhes")) {
                    TextField("Descrição do item ou serviço *", text: $newItemDesc)
                    HStack {
                        Text("Quantidade:")
                        Spacer()
                        TextField("1", text: $newItemQty)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                    }
                    HStack {
                        Text("Preço Unitário (R$):")
                        Spacer()
                        TextField("0,00", text: $newItemPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }

                Section {
                    let qty = Double(newItemQty.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                    let prc = Double(newItemPrice.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                    HStack {
                        Text("Total do Item:")
                            .fontWeight(.medium)
                        Spacer()
                        Text((qty * prc).brlCurrency)
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .navigationTitle(newItemType == .material ? "Adicionar Material" : "Adicionar Serviço")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetNewItemFields()
                        showingAddItemSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adicionar") {
                        commitAddItem()
                    }
                    .disabled(newItemDesc.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }

    private func commitAddItem() {
        let cleanDesc = newItemDesc.trimmingCharacters(in: .whitespaces)
        guard !cleanDesc.isEmpty else { return }
        let qty = Double(newItemQty.replacingOccurrences(of: ",", with: ".")) ?? 1.0
        let prc = Double(newItemPrice.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let item = QuoteItem(
            tipo: newItemType,
            descricao: cleanDesc,
            quantidade: qty,
            precoUnitario: prc,
            total: qty * prc
        )
        items.append(item)
        resetNewItemFields()
        showingAddItemSheet = false
    }

    private func resetNewItemFields() {
        newItemDesc = ""
        newItemQty = "1"
        newItemPrice = ""
    }

    private func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    private func saveQuote() {
        guard let client = selectedClient else { return }

        var quote = Quote(
            numero: quoteNumber.trimmingCharacters(in: .whitespaces),
            clienteId: client.id,
            clienteNome: client.nome,
            dataCriacao: dataCriacao,
            validade: validade,
            diasValidade: 15,
            status: .rascunho,
            itens: items,
            subtotalMateriais: subtotalMateriais,
            subtotalServicos: subtotalServicos,
            desconto: descontoValue,
            totalGeral: totalGeral,
            observacoes: observacoes
        )

        if autoGenerateMercadoPago {
            quote.mercadoPago = MercadoPagoService.shared.generateCharge(for: quote)
        }

        dataStore.addQuote(quote, autoCreateReceivable: autoCreateReceivable)
        dismiss()
    }
}
