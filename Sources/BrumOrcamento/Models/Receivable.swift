import Foundation

public enum ReceivableStatus: String, Codable, CaseIterable, Identifiable {
    case pendente = "Pendente"
    case pago = "Pago"
    case atrasado = "Atrasado"

    public var id: String { rawValue }

    public var badgeColorName: String {
        switch self {
        case .pendente: return "orange"
        case .pago: return "green"
        case .atrasado: return "red"
        }
    }
}

public struct Receivable: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var orcamentoId: String?
    public var orcamentoNumero: String?
    public var clienteId: String
    public var clienteNome: String
    public var descricao: String
    public var valor: Double
    public var dataVencimento: Date
    public var status: ReceivableStatus
    public var dataPagamento: Date?
    public var formaPagamento: String?

    public init(
        id: String = UUID().uuidString,
        orcamentoId: String? = nil,
        orcamentoNumero: String? = nil,
        clienteId: String,
        clienteNome: String,
        descricao: String,
        valor: Double,
        dataVencimento: Date,
        status: ReceivableStatus = .pendente,
        dataPagamento: Date? = nil,
        formaPagamento: String? = nil
    ) {
        self.id = id
        self.orcamentoId = orcamentoId
        self.orcamentoNumero = orcamentoNumero
        self.clienteId = clienteId
        self.clienteNome = clienteNome
        self.descricao = descricao
        self.valor = valor
        self.dataVencimento = dataVencimento
        self.status = status
        self.dataPagamento = dataPagamento
        self.formaPagamento = formaPagamento
    }

    public var isOverdue: Bool {
        return status == .pendente && Date() > dataVencimento
    }

    public mutating func markAsPaid(method: String = "Mercado Pago (Pix)", date: Date = Date()) {
        self.status = .pago
        self.dataPagamento = date
        self.formaPagamento = method
    }

    public mutating func reopen() {
        self.status = .pendente
        self.dataPagamento = nil
        self.formaPagamento = nil
    }
}
