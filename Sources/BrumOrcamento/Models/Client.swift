import Foundation

public struct Address: Codable, Equatable, Hashable {
    public var logradouro: String
    public var numero: String
    public var complemento: String
    public var bairro: String
    public var cidade: String
    public var estado: String
    public var cep: String

    public init(
        logradouro: String = "",
        numero: String = "",
        complemento: String = "",
        bairro: String = "",
        cidade: String = "",
        estado: String = "SP",
        cep: String = ""
    ) {
        self.logradouro = logradouro
        self.numero = numero
        self.complemento = complemento
        self.bairro = bairro
        self.cidade = cidade
        self.estado = estado
        self.cep = cep
    }

    public var inlineText: String {
        var parts: [String] = []
        if !logradouro.isEmpty {
            var street = logradouro
            if !numero.isEmpty { street += ", \(numero)" }
            if !complemento.isEmpty { street += " (\(complemento))" }
            parts.append(street)
        }
        if !bairro.isEmpty { parts.append(bairro) }
        if !cidade.isEmpty {
            var cityState = cidade
            if !estado.isEmpty { cityState += "/\(estado)" }
            parts.append(cityState)
        }
        if !cep.isEmpty { parts.append("CEP: \(cep)") }
        return parts.joined(separator: " - ")
    }
}

public struct Client: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var nome: String
    public var documento: String
    public var tipoDocumento: String
    public var telefone: String
    public var email: String
    public var endereco: Address
    public var criadoEm: Date

    public init(
        id: String = UUID().uuidString,
        nome: String,
        documento: String = "",
        tipoDocumento: String = "CNPJ",
        telefone: String = "",
        email: String = "",
        endereco: Address = Address(),
        criadoEm: Date = Date()
    ) {
        self.id = id
        self.nome = nome
        self.documento = documento
        self.tipoDocumento = tipoDocumento
        self.telefone = telefone
        self.email = email
        self.endereco = endereco
        self.criadoEm = criadoEm
    }
}
