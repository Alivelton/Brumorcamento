import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ItemOrcamento: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var tipo: String // "Serviço" ou "Material"
    var nome: String
    var unidade: String
    var qtd: Double
    var custoUn: Double
    var vendaUn: Double

    var totalVenda: Double { qtd * vendaUn }
    var totalCusto: Double { qtd * custoUn }
    var lucroItem: Double { totalVenda - totalCusto }
}

struct OrcamentoRua: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var numeroTemp: String
    var cliente: String
    var telefone: String
    var observacao: String
    var itens: [ItemOrcamento]
    var criadoEm: Date = Date()
    var sincronizado: Bool = false

    var totalGeral: Double { itens.reduce(0) { $0 + $1.totalVenda } }
    var custoGeral: Double { itens.reduce(0) { $0 + $1.totalCusto } }
    var lucroGeral: Double { totalGeral - custoGeral }
}

struct SyncPayload: Codable {
    var origem: String
    var dispositivo: String
    var enviadoEm: String
    var orcamentos: [OrcamentoRua]
}

struct ContentView: View {
    // Campos do orçamento atual
    @State private var cliente: String = ""
    @State private var telefone: String = ""
    @State private var observacao: String = ""

    // Campos de adição rápida de item
    @State private var tipoItem: String = "Serviço"
    @State private var unidadeItem: String = "SV"
    @State private var nomeItem: String = ""
    @State private var qtdTexto: String = "1"
    @State private var custoTexto: String = "0"
    @State private var vendaTexto: String = "0"

    // Itens em montagem e histórico local
    @State private var itensAtuais: [ItemOrcamento] = []
    @State private var orcamentos: [OrcamentoRua] = []

    // Configuração de sincronização (opcional / sob demanda)
    @State private var syncURL: String = "https://brum-orcamentos-sync.aliveltonbrum.workers.dev/"
    @State private var syncToken: String = ""
    @State private var statusMsg: String = "Modo offline ativo. Salva local no iPhone."
    @State private var sincronizando: Bool = false

    private let storageKey = "brum_solucoes_orcamentos_v1"
    private let urlKey = "brum_solucoes_sync_url_v1"
    private let tokenKey = "brum_solucoes_sync_token_v1"

    var body: some View {
        NavigationStack {
            Form {
                // 1. Dados do Cliente
                Section("Cliente") {
                    TextField("Nome ou Condomínio", text: $cliente)
                    TextField("WhatsApp (opcional)", text: $telefone)
                        #if canImport(UIKit)
                        .keyboardType(.phonePad)
                        #endif
                    TextField("Observação curta (opcional)", text: $observacao)
                }

                // 2. Adicionar Serviço ou Material
                Section("Adicionar Item") {
                    Picker("Tipo", selection: $tipoItem) {
                        Text("Serviço").tag("Serviço")
                        Text("Material").tag("Material")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: tipoItem) { _, novoTipo in
                        unidadeItem = (novoTipo == "Serviço") ? "SV" : "UN"
                    }

                    TextField("Descrição do serviço ou material", text: $nomeItem)

                    HStack {
                        TextField("Unid.", text: $unidadeItem)
                            .frame(width: 65)
                        TextField("Qtd", text: $qtdTexto)
                            #if canImport(UIKit)
                            .keyboardType(.decimalPad)
                            #endif
                        TextField("Custo R$", text: $custoTexto)
                            #if canImport(UIKit)
                            .keyboardType(.decimalPad)
                            #endif
                        TextField("Venda R$", text: $vendaTexto)
                            #if canImport(UIKit)
                            .keyboardType(.decimalPad)
                            #endif
                    }

                    Button("Adicionar ao Orçamento") {
                        adicionarItem()
                    }
                    .buttonStyle(.bordered)
                }

                // 3. Resumo do Orçamento Atual
                if !itensAtuais.isEmpty {
                    Section("Itens do Orçamento (\(formatBRL(totalAtual)))") {
                        ForEach(itensAtuais) { item in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.nome)
                                        .font(.body.bold())
                                    Text("\(item.tipo) · \(formatQtd(item.qtd)) \(item.unidade) · Custo: \(formatBRL(item.totalCusto))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(formatBRL(item.totalVenda))
                                    .font(.body.bold())
                            }
                        }
                        .onDelete { offsets in
                            itensAtuais.remove(atOffsets: offsets)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custo total: \(formatBRL(custoAtual))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("Lucro estimado: \(formatBRL(totalAtual - custoAtual))")
                                .font(.footnote.bold())
                                .foregroundStyle(.green)
                        }

                        Button("Salvar Orçamento no iPhone") {
                            salvarOrcamento()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }

                // 4. Orçamentos Salvos no iPhone
                Section("Orçamentos Salvos (\(orcamentos.count))") {
                    if orcamentos.isEmpty {
                        Text("Nenhum orçamento salvo ainda.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(orcamentos) { orc in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(orc.cliente.isEmpty ? "Cliente sem nome" : orc.cliente)
                                            .font(.headline)
                                        Text("\(orc.numeroTemp) · \(formatData(orc.criadoEm)) · \(orc.sincronizado ? "Sincronizado" : "Pendente sync")")
                                            .font(.caption)
                                            .foregroundStyle(orc.sincronizado ? .green : .orange)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(formatBRL(orc.totalGeral))
                                            .font(.headline)
                                        Text("Lucro: \(formatBRL(orc.lucroGeral))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                ForEach(orc.itens) { it in
                                    Text("• \(formatQtd(it.qtd)) \(it.unidade) - \(it.nome): \(formatBRL(it.totalVenda))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 12) {
                                    Button("Copiar Texto") {
                                        copiarTexto(orc)
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Enviar WhatsApp") {
                                        enviarWhatsApp(orc)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            orcamentos.remove(atOffsets: offsets)
                            persistirTudo()
                        }
                    }
                }

                // 5. Sincronização com o Servidor (Quando estiver online)
                Section("Conversa com Servidor") {
                    TextField("Endpoint de sincronização", text: $syncURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #if canImport(UIKit)
                        .keyboardType(.URL)
                        #endif

                    SecureField("Chave/Token simples (opcional)", text: $syncToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button(sincronizando ? "Sincronizando..." : "Sincronizar Orçamentos Agora") {
                        sincronizarComServidor()
                    }
                    .disabled(sincronizando)
                    .buttonStyle(.bordered)

                    Text(statusMsg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Brum Orçamentos")
            .onAppear {
                carregarTudo()
            }
        }
    }

    private var totalAtual: Double {
        itensAtuais.reduce(0) { $0 + $1.totalVenda }
    }

    private var custoAtual: Double {
        itensAtuais.reduce(0) { $0 + $1.totalCusto }
    }

    private func parseNumero(_ texto: String, padrao: Double) -> Double {
        let limpo = texto.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        return Double(limpo) ?? padrao
    }

    private func formatQtd(_ q: Double) -> String {
        if q.rounded() == q {
            return String(Int(q))
        }
        return String(format: "%.2f", q)
    }

    private func formatBRL(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: valor)) ?? "R$ 0,00"
    }

    private func formatData(_ data: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM HH:mm"
        return formatter.string(from: data)
    }

    private func adicionarItem() {
        let nomeLimpo = nomeItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nomeLimpo.isEmpty else {
            statusMsg = "Informe o nome do serviço ou material."
            return
        }
        let qtd = max(0.01, parseNumero(qtdTexto, padrao: 1.0))
        let custo = max(0.0, parseNumero(custoTexto, padrao: 0.0))
        let venda = max(0.0, parseNumero(vendaTexto, padrao: 0.0))

        let novoItem = ItemOrcamento(
            tipo: tipoItem,
            nome: nomeLimpo,
            unidade: unidadeItem.trimmingCharacters(in: .whitespaces).isEmpty ? "UN" : unidadeItem.trimmingCharacters(in: .whitespaces).uppercased(),
            qtd: qtd,
            custoUn: custo,
            vendaUn: venda
        )
        itensAtuais.append(novoItem)

        nomeItem = ""
        qtdTexto = "1"
        custoTexto = "0"
        vendaTexto = "0"
        statusMsg = "Item adicionado."
    }

    private func salvarOrcamento() {
        guard !itensAtuais.isEmpty else { return }
        let seq = orcamentos.count + 1
        let numStr = String(format: "ORC-RUA-%03d", seq)
        let novo = OrcamentoRua(
            numeroTemp: numStr,
            cliente: cliente.trimmingCharacters(in: .whitespacesAndNewlines),
            telefone: telefone.trimmingCharacters(in: .whitespacesAndNewlines),
            observacao: observacao.trimmingCharacters(in: .whitespacesAndNewlines),
            itens: itensAtuais,
            criadoEm: Date(),
            sincronizado: false
        )
        orcamentos.insert(novo, at: 0)
        itensAtuais = []
        cliente = ""
        telefone = ""
        observacao = ""
        persistirTudo()
        statusMsg = "Salvo localmente no iPhone (\(numStr))."
    }

    private func persistirTudo() {
        if let encoded = try? JSONEncoder().encode(orcamentos) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        UserDefaults.standard.set(syncURL, forKey: urlKey)
        UserDefaults.standard.set(syncToken, forKey: tokenKey)
    }

    private func carregarTudo() {
        if let savedURL = UserDefaults.standard.string(forKey: urlKey), !savedURL.isEmpty {
            syncURL = savedURL
        }
        if let savedToken = UserDefaults.standard.string(forKey: tokenKey) {
            syncToken = savedToken
        }
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([OrcamentoRua].self, from: data) {
            orcamentos = decoded
        }
    }

    private func montarMensagemWhatsApp(_ orc: OrcamentoRua) -> String {
        var linhas: [String] = []
        linhas.append("*Orçamento - Brum Soluções Técnicas*")
        if !orc.cliente.isEmpty {
            linhas.append("Cliente: *\(orc.cliente)*")
        }
        linhas.append("")
        for it in orc.itens {
            linhas.append("• \(formatQtd(it.qtd)) \(it.unidade) - \(it.nome): *\(formatBRL(it.totalVenda))*")
        }
        linhas.append("")
        linhas.append("*Total: \(formatBRL(orc.totalGeral))*")
        if !orc.observacao.isEmpty {
            linhas.append("Obs: \(orc.observacao)")
        }
        return linhas.joined(separator: "\n")
    }

    private func copiarTexto(_ orc: OrcamentoRua) {
        #if canImport(UIKit)
        UIPasteboard.general.string = montarMensagemWhatsApp(orc)
        statusMsg = "Texto do orçamento \(orc.numeroTemp) copiado."
        #endif
    }

    private func enviarWhatsApp(_ orc: OrcamentoRua) {
        #if canImport(UIKit)
        let msg = montarMensagemWhatsApp(orc)
        let digits = orc.telefone.filter(\.isNumber)
        let fone = (!digits.isEmpty && digits.count <= 11) ? "55\(digits)" : digits
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let link = fone.isEmpty ? "https://wa.me/?text=\(encoded)" : "https://wa.me/\(fone)?text=\(encoded)"
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func sincronizarComServidor() {
        persistirTudo()
        guard let url = URL(string: syncURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            statusMsg = "URL de sincronização inválida."
            return
        }
        let pendentes = orcamentos.filter { !$0.sincronizado }
        let listaEnviar = pendentes.isEmpty ? orcamentos : pendentes
        guard !listaEnviar.isEmpty else {
            statusMsg = "Não há orçamentos para sincronizar."
            return
        }

        sincronizando = true
        statusMsg = "Enviando para o servidor..."

        let pacote = SyncPayload(
            origem: "iphone-xtool",
            dispositivo: "iPhone",
            enviadoEm: ISO8601DateFormatter().string(from: Date()),
            orcamentos: listaEnviar
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !syncToken.trimmingCharacters(in: .whitespaces).isEmpty {
            request.setValue("Bearer \(syncToken.trimmingCharacters(in: .whitespaces))", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONEncoder().encode(pacote)

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                sincronizando = false
                if let error = error {
                    statusMsg = "Servidor offline ou sem rede agora (\(error.localizedDescription)). Mantido no iPhone."
                    return
                }
                if let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) {
                    let idsEnviados = Set(listaEnviar.map(\.id))
                    for idx in orcamentos.indices {
                        if idsEnviados.contains(orcamentos[idx].id) {
                            orcamentos[idx].sincronizado = true
                        }
                    }
                    persistirTudo()
                    statusMsg = "Sincronizado com sucesso (\(listaEnviar.count) orçamento(s))."
                } else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    statusMsg = "Servidor respondeu HTTP \(code). Mantido no iPhone."
                }
            }
        }.resume()
    }
}
