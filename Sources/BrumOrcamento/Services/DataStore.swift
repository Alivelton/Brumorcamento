import Foundation
import Combine

public final class DataStore: ObservableObject {
    @Published public var clients: [Client] = []
    @Published public var quotes: [Quote] = []
    @Published public var receivables: [Receivable] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let localFileName = "dados_brum.json"

    public init() {
        loadData()
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var localFileURL: URL {
        documentsDirectory.appendingPathComponent(localFileName)
    }

    // MARK: - Carregamento Inicial e Persistência
    public func loadData() {
        isLoading = true
        errorMessage = nil

        // 1. Tentar ler do diretório local Documents (onde ficam as alterações salvas)
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            do {
                let data = try Data(contentsOf: localFileURL)
                if parseAndApplyDatabase(from: data) {
                    isLoading = false
                    return
                }
            } catch {
                print("Erro ao carregar dados locais: \(error.localizedDescription)")
            }
        }

        // 2. Primeiro uso: tentar carregar dos dados embutidos no Bundle (dados_iniciais.json)
        var loadedData: Data? = nil

        #if SWIFT_PACKAGE
        if let bundleURL = Bundle.module.url(forResource: "dados_iniciais", withExtension: "json") {
            loadedData = try? Data(contentsOf: bundleURL)
        }
        #endif

        if loadedData == nil {
            if let mainURL = Bundle.main.url(forResource: "dados_iniciais", withExtension: "json") {
                loadedData = try? Data(contentsOf: mainURL)
            }
        }

        // 3. Fallback: procurar no caminho ~/backup_dados_brum/dados_existentes.json ou caminhos relativos
        if loadedData == nil {
            let possiblePaths = [
                NSHomeDirectory() + "/backup_dados_brum/dados_existentes.json",
                FileManager.default.currentDirectoryPath + "/backup_dados_brum/dados_existentes.json",
                FileManager.default.currentDirectoryPath + "/Sources/BrumOrcamento/Resources/dados_iniciais.json"
            ]
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path),
                   let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                    loadedData = fileData
                    break
                }
            }
        }

        if let data = loadedData {
            if parseAndApplyDatabase(from: data) {
                // Salva imediatamente no DocumentsDirectory para os próximos usos
                save()
                isLoading = false
                return
            }
        }

        // Se nenhum arquivo foi encontrado, inicializa com lista vazia
        self.clients = []
        self.quotes = []
        self.receivables = []
        isLoading = false
    }

    private func parseAndApplyDatabase(from data: Data) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = Formatters.parseISO8601(dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Formato de data inválido: \(dateStr)"
            )
        }

        do {
            let database = try decoder.decode(AppDatabase.self, from: data)
            DispatchQueue.main.async {
                self.clients = database.clientes
                self.quotes = database.orcamentos
                self.receivables = database.cobrancas
            }
            return true
        } catch {
            print("Erro ao decodificar JSON: \(error)")
            self.errorMessage = "Falha ao processar banco de dados: \(error.localizedDescription)"
            return false
        }
    }

    public func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let str = Formatters.iso8601Formatter.string(from: date)
            try container.encode(str)
        }

        let database = AppDatabase(
            versao: "1.0",
            dataExportacao: Date(),
            clientes: self.clients,
            orcamentos: self.quotes,
            cobrancas: self.receivables
        )

        do {
            let data = try encoder.encode(database)
            try data.write(to: localFileURL, options: .atomic)
        } catch {
            print("Erro ao salvar dados localmente: \(error)")
            self.errorMessage = "Erro ao salvar: \(error.localizedDescription)"
        }
    }

    // MARK: - Clientes
    public func addClient(_ client: Client) {
        clients.append(client)
        save()
    }

    public func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
            // Atualizar nome do cliente nos orçamentos e contas a receber
            for i in 0..<quotes.count where quotes[i].clienteId == client.id {
                quotes[i].clienteNome = client.nome
            }
            for i in 0..<receivables.count where receivables[i].clienteId == client.id {
                receivables[i].clienteNome = client.nome
            }
            save()
        }
    }

    public func deleteClient(id: String) {
        clients.removeAll { $0.id == id }
        save()
    }

    public func getClient(by id: String) -> Client? {
        clients.first { $0.id == id }
    }

    // MARK: - Orçamentos
    public func addQuote(_ quote: Quote, autoCreateReceivable: Bool = true) {
        var newQuote = quote
        if newQuote.numero.isEmpty {
            let nextNum = (quotes.count + 1)
            newQuote.numero = String(format: "ORC-2026-%03d", nextNum)
        }
        newQuote.recalculateTotals()

        // Gerar cobrança Mercado Pago se configurado ou requerido
        if newQuote.mercadoPago == nil {
            newQuote.mercadoPago = MercadoPagoService.shared.generateCharge(for: newQuote)
        }

        quotes.append(newQuote)

        if autoCreateReceivable {
            let rec = Receivable(
                orcamentoId: newQuote.id,
                orcamentoNumero: newQuote.numero,
                clienteId: newQuote.clienteId,
                clienteNome: newQuote.clienteNome,
                descricao: "Cobrança Integral - \(newQuote.numero)",
                valor: newQuote.totalGeral,
                dataVencimento: newQuote.validade,
                status: .pendente,
                formaPagamento: "Mercado Pago (Pix / Boleto / Cartão)"
            )
            receivables.append(rec)
        }

        save()
    }

    public func updateQuote(_ quote: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == quote.id }) {
            var updated = quote
            updated.recalculateTotals()
            quotes[index] = updated
            save()
        }
    }

    public func deleteQuote(id: String) {
        quotes.removeAll { $0.id == id }
        receivables.removeAll { $0.orcamentoId == id }
        save()
    }

    public func approveQuote(id: String) {
        guard let index = quotes.firstIndex(where: { $0.id == id }) else { return }
        quotes[index].status = .aprovado
        
        // Se ainda não tiver cobrança gerada para ele em A Receber, cria
        let existingRecs = receivables.filter { $0.orcamentoId == id }
        if existingRecs.isEmpty {
            let rec = Receivable(
                orcamentoId: quotes[index].id,
                orcamentoNumero: quotes[index].numero,
                clienteId: quotes[index].clienteId,
                clienteNome: quotes[index].clienteNome,
                descricao: "Orçamento \(quotes[index].numero) - Aprovado",
                valor: quotes[index].totalGeral,
                dataVencimento: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                status: .pendente,
                formaPagamento: "Mercado Pago"
            )
            receivables.append(rec)
        }
        save()
    }

    public func generateMercadoPagoForQuote(id: String) {
        guard let index = quotes.firstIndex(where: { $0.id == id }) else { return }
        let mpData = MercadoPagoService.shared.generateCharge(for: quotes[index])
        quotes[index].mercadoPago = mpData
        save()
    }

    public func simulatePaymentConfirmation(quoteId: String) {
        guard let index = quotes.firstIndex(where: { $0.id == quoteId }) else { return }
        quotes[index].status = .faturado
        if quotes[index].mercadoPago != nil {
            quotes[index].mercadoPago?.statusPagamento = "Pago"
        }
        
        // Dá baixa nas contas a receber deste orçamento
        for i in 0..<receivables.count where receivables[i].orcamentoId == quoteId {
            receivables[i].markAsPaid(method: "Mercado Pago (Pix Retorno)", date: Date())
        }
        save()
    }

    // MARK: - A Receber (Cobranças / Parcelas)
    public func addReceivable(_ receivable: Receivable) {
        receivables.append(receivable)
        save()
    }

    public func updateReceivable(_ receivable: Receivable) {
        if let index = receivables.firstIndex(where: { $0.id == receivable.id }) {
            receivables[index] = receivable
            save()
        }
    }

    public func deleteReceivable(id: String) {
        receivables.removeAll { $0.id == id }
        save()
    }

    public func markReceivableAsPaid(id: String, paymentMethod: String = "Mercado Pago (Pix)", date: Date = Date()) {
        if let index = receivables.firstIndex(where: { $0.id == id }) {
            receivables[index].markAsPaid(method: paymentMethod, date: date)
            
            // Verificar se todas as parcelas do orçamento foram pagas
            if let orcId = receivables[index].orcamentoId {
                let related = receivables.filter { $0.orcamentoId == orcId }
                let allPaid = related.allSatisfy { $0.status == .pago }
                if allPaid, let qIndex = quotes.firstIndex(where: { $0.id == orcId }) {
                    quotes[qIndex].status = .faturado
                    quotes[qIndex].mercadoPago?.statusPagamento = "Pago"
                }
            }
            save()
        }
    }

    public func reopenReceivable(id: String) {
        if let index = receivables.firstIndex(where: { $0.id == id }) {
            receivables[index].reopen()
            save()
        }
    }

    // MARK: - Totais Calculados
    public var totalAReceber: Double {
        receivables.filter { $0.status == .pendente }.reduce(0) { $0 + $1.valor }
    }

    public var totalRecebido: Double {
        receivables.filter { $0.status == .pago }.reduce(0) { $0 + $1.valor }
    }

    public var totalAtrasado: Double {
        receivables.filter { $0.isOverdue }.reduce(0) { $0 + $1.valor }
    }

    // MARK: - Backup e Restauração
    public func resetToInitialBackup() {
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            try? FileManager.default.removeItem(at: localFileURL)
        }
        loadData()
    }
}
