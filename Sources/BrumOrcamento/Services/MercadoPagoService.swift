import Foundation
import UIKit

public final class MercadoPagoService {
    public static let shared = MercadoPagoService()

    private init() {}

    /// Gera cobrança via Mercado Pago com link direto e Pix Copia e Cola
    public func generateCharge(
        for quote: Quote,
        customTitle: String? = nil,
        customAmount: Double? = nil
    ) -> MercadoPagoData {
        let amount = customAmount ?? quote.totalGeral
        let title = customTitle ?? "Orçamento \(quote.numero) - Brum"
        let preferenceId = "MP-PREF-\(UUID().uuidString.prefix(8).uppercased())"
        let slug = quote.numero.lowercased().replacingOccurrences(of: "/", with: "-")
        let paymentLink = "https://mpago.la/pos/\(slug)"

        let pixCode = generatePixCopiaCola(
            chavePix: "financeiro@brum.com.br",
            nomeBeneficiario: "BRUM SERVICOS METALURGICOS",
            cidadeBeneficiario: "SAO PAULO",
            valor: amount,
            identificador: quote.numero.replacingOccurrences(of: "-", with: "")
        )

        return MercadoPagoData(
            preferenciaId: preferenceId,
            linkPagamento: paymentLink,
            codigoPixCopiaCola: pixCode,
            statusPagamento: "Pendente"
        )
    }

    /// Gera cobrança via Mercado Pago para uma parcela específica A Receber
    public func generateCharge(for receivable: Receivable) -> MercadoPagoData {
        let preferenceId = "MP-REC-\(UUID().uuidString.prefix(8).uppercased())"
        let slug = (receivable.orcamentoNumero ?? "rec").lowercased().replacingOccurrences(of: "/", with: "-")
        let paymentLink = "https://mpago.la/pos/\(slug)-parc"

        let pixCode = generatePixCopiaCola(
            chavePix: "financeiro@brum.com.br",
            nomeBeneficiario: "BRUM SERVICOS METALURGICOS",
            cidadeBeneficiario: "SAO PAULO",
            valor: receivable.valor,
            identificador: String(receivable.id.prefix(8))
        )

        return MercadoPagoData(
            preferenciaId: preferenceId,
            linkPagamento: paymentLink,
            codigoPixCopiaCola: pixCode,
            statusPagamento: "Pendente"
        )
    }

    /// Monta o payload padrão Pix Banco Central (EMVCo)
    private func generatePixCopiaCola(
        chavePix: String,
        nomeBeneficiario: String,
        cidadeBeneficiario: String,
        valor: Double,
        identificador: String
    ) -> String {
        func formatField(id: String, value: String) -> String {
            let length = String(format: "%02d", value.count)
            return "\(id)\(length)\(value)"
        }

        let p00 = formatField(id: "00", value: "01") // Payload Format Indicator
        let merchantAccount = formatField(id: "00", value: "br.gov.bcb.pix") + formatField(id: "01", value: chavePix)
        let p26 = formatField(id: "26", value: merchantAccount)
        let p52 = formatField(id: "52", value: "0000") // Merchant Category Code
        let p53 = formatField(id: "53", value: "986") // BRL
        let amountStr = String(format: "%.2f", valor)
        let p54 = formatField(id: "54", value: amountStr)
        let p58 = formatField(id: "58", value: "BR")
        let cleanName = String(nomeBeneficiario.prefix(25))
        let p59 = formatField(id: "59", value: cleanName)
        let cleanCity = String(cidadeBeneficiario.prefix(15))
        let p60 = formatField(id: "60", value: cleanCity)
        let additionalData = formatField(id: "05", value: String(identificador.prefix(25)))
        let p62 = formatField(id: "62", value: additionalData)

        let rawPayload = "\(p00)\(p26)\(p52)\(p53)\(p54)\(p58)\(p59)\(p60)\(p62)6304"
        let crc = computeCRC16(string: rawPayload)
        return "\(rawPayload)\(crc)"
    }

    private func computeCRC16(string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "0000" }
        var crc: UInt16 = 0xFFFF
        let polynomial: UInt16 = 0x1021

        for byte in data {
            for i in 0..<8 {
                let bit = ((byte >> (7 - i)) & 1) == 1
                let c15 = ((crc >> 15) & 1) == 1
                crc <<= 1
                if c15 ^ bit {
                    crc ^= polynomial
                }
            }
        }
        return String(format: "%04X", crc)
    }

    public func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}
