import Foundation

public struct AppDatabase: Codable {
    public var versao: String
    public var dataExportacao: Date
    public var clientes: [Client]
    public var orcamentos: [Quote]
    public var cobrancas: [Receivable]

    enum CodingKeys: String, CodingKey {
        case versao
        case dataExportacao = "data_exportacao"
        case clientes
        case orcamentos
        case cobrancas
    }

    public init(
        versao: String = "1.0",
        dataExportacao: Date = Date(),
        clientes: [Client] = [],
        orcamentos: [Quote] = [],
        cobrancas: [Receivable] = []
    ) {
        self.versao = versao
        self.dataExportacao = dataExportacao
        self.clientes = clientes
        self.orcamentos = orcamentos
        self.cobrancas = cobrancas
    }
}
