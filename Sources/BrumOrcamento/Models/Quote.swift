import Foundation

public enum QuoteStatus: String, Codable, CaseIterable, Identifiable {
    case rascunho = "Rascunho"
    case enviado = "Enviado"
    case aprovado = "Aprovado"
    case faturado = "Faturado"
    case cancelado = "Cancelado"

    public var id: String { rawValue }

    public var badgeColorName: String {
        switch self {
        case .rascunho: return "gray"
        case .enviado: return "blue"
        case .aprovado: return "green"
        case .faturado: return "purple"
        case .cancelado: return "red"
        }
    }
}

public enum ItemType: String, Codable, CaseIterable, Identifiable {
    case material = "material"
    case servico = "servico"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .material: return "Produto / Material"
        case .servico: return "Serviço / Mão de Obra"
        }
    }

    public var shortLabel: String {
        switch self {
        case .material: return "Material"
        case .servico: return "Serviço"
        }
    }
}

public struct QuoteItem: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var tipo: ItemType
    public var descricao: String
    public var quantidade: Double
    public var precoUnitario: Double
    public var total: Double

    public init(
        id: String = UUID().uuidString,
        tipo: ItemType = .material,
        descricao: String = "",
        quantidade: Double = 1.0,
        precoUnitario: Double = 0.0,
        total: Double? = nil
    ) {
        self.id = id
        self.tipo = tipo
        self.descricao = descricao
        self.quantidade = quantidade
        self.precoUnitario = precoUnitario
        self.total = total ?? (quantidade * precoUnitario)
    }

    public mutating func recalculate() {
        self.total = self.quantidade * self.precoUnitario
    }
}

public struct MercadoPagoData: Codable, Equatable, Hashable {
    public var preferenciaId: String?
    public var linkPagamento: String?
    public var codigoPixCopiaCola: String?
    public var statusPagamento: String

    public init(
        preferenciaId: String? = nil,
        linkPagamento: String? = nil,
        codigoPixCopiaCola: String? = nil,
        statusPagamento: String = "Pendente"
    ) {
        self.preferenciaId = preferenciaId
        self.linkPagamento = linkPagamento
        self.codigoPixCopiaCola = codigoPixCopiaCola
        self.statusPagamento = statusPagamento
    }
}

public struct Quote: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var numero: String
    public var clienteId: String
    public var clienteNome: String
    public var dataCriacao: Date
    public var validade: Date
    public var diasValidade: Int
    public var status: QuoteStatus
    public var itens: [QuoteItem]
    public var subtotalMateriais: Double
    public var subtotalServicos: Double
    public var desconto: Double
    public var totalGeral: Double
    public var observacoes: String
    public var mercadoPago: MercadoPagoData?

    public init(
        id: String = UUID().uuidString,
        numero: String,
        clienteId: String,
        clienteNome: String,
        dataCriacao: Date = Date(),
        validade: Date? = nil,
        diasValidade: Int = 15,
        status: QuoteStatus = .rascunho,
        itens: [QuoteItem] = [],
        subtotalMateriais: Double = 0.0,
        subtotalServicos: Double = 0.0,
        desconto: Double = 0.0,
        totalGeral: Double = 0.0,
        observacoes: String = "",
        mercadoPago: MercadoPagoData? = nil
    ) {
        self.id = id
        self.numero = numero
        self.clienteId = clienteId
        self.clienteNome = clienteNome
        self.dataCriacao = dataCriacao
        self.diasValidade = diasValidade
        self.validade = validade ?? Calendar.current.date(byAdding: .day, value: diasValidade, to: dataCriacao) ?? dataCriacao
        self.status = status
        self.itens = itens
        self.subtotalMateriais = subtotalMateriais
        self.subtotalServicos = subtotalServicos
        self.desconto = desconto
        self.totalGeral = totalGeral
        self.observacoes = observacoes
        self.mercadoPago = mercadoPago
        
        if totalGeral == 0.0 && !itens.isEmpty {
            self.recalculateTotals()
        }
    }

    public mutating func recalculateTotals() {
        var matSum: Double = 0.0
        var srvSum: Double = 0.0
        for item in itens {
            let itemTotal = item.quantidade * item.precoUnitario
            if item.tipo == .material {
                matSum += itemTotal
            } else {
                srvSum += itemTotal
            }
        }
        self.subtotalMateriais = matSum
        self.subtotalServicos = srvSum
        self.totalGeral = max(0.0, (matSum + srvSum) - desconto)
    }

    public var isExpired: Bool {
        return Date() > validade && status == .rascunho
    }
}
