import SwiftUI

public struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore

    private var editingClient: Client?
    var onClientCreated: ((Client) -> Void)? = nil

    @State private var nome: String = ""
    @State private var tipoDocumento: String = "CNPJ"
    @State private var documento: String = ""
    @State private var telefone: String = ""
    @State private var email: String = ""

    // Endereço
    @State private var logradouro: String = ""
    @State private var numero: String = ""
    @State private var complemento: String = ""
    @State private var bairro: String = ""
    @State private var cidade: String = "São Paulo"
    @State private var estado: String = "SP"
    @State private var cep: String = ""

    public init(editingClient: Client? = nil, onClientCreated: ((Client) -> Void)? = nil) {
        self.editingClient = editingClient
        self.onClientCreated = onClientCreated
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Identificação")) {
                    TextField("Nome / Razão Social *", text: $nome)
                        .autocorrectionDisabled()

                    Picker("Tipo de Documento", selection: $tipoDocumento) {
                        Text("CNPJ").tag("CNPJ")
                        Text("CPF").tag("CPF")
                    }
                    .pickerStyle(.segmented)

                    TextField(tipoDocumento == "CNPJ" ? "00.000.000/0001-00" : "000.000.000-00", text: $documento)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section(header: Text("Contato")) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        TextField("Telefone / WhatsApp", text: $telefone)
                            .keyboardType(.phonePad)
                    }

                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        TextField("E-mail", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                Section(header: Text("Endereço")) {
                    TextField("Logradouro (Rua, Av.)", text: $logradouro)
                    HStack {
                        TextField("Número", text: $numero)
                            .frame(maxWidth: 100)
                        TextField("Complemento (Sala, Galpão)", text: $complemento)
                    }
                    TextField("Bairro", text: $bairro)
                    HStack {
                        TextField("Cidade", text: $cidade)
                        TextField("UF", text: $estado)
                            .frame(maxWidth: 60)
                            .textInputAutocapitalization(.characters)
                    }
                    TextField("CEP", text: $cep)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
            .navigationTitle(editingClient == nil ? "Novo Cliente" : "Editar Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        saveClient()
                    }
                    .disabled(nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if let client = editingClient {
                    nome = client.nome
                    tipoDocumento = client.tipoDocumento
                    documento = client.documento
                    telefone = client.telefone
                    email = client.email
                    logradouro = client.endereco.logradouro
                    numero = client.endereco.numero
                    complemento = client.endereco.complemento
                    bairro = client.endereco.bairro
                    cidade = client.endereco.cidade
                    estado = client.endereco.estado
                    cep = client.endereco.cep
                }
            }
        }
    }

    private func saveClient() {
        let cleanName = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let address = Address(
            logradouro: logradouro.trimmingCharacters(in: .whitespaces),
            numero: numero.trimmingCharacters(in: .whitespaces),
            complemento: complemento.trimmingCharacters(in: .whitespaces),
            bairro: bairro.trimmingCharacters(in: .whitespaces),
            cidade: cidade.trimmingCharacters(in: .whitespaces),
            estado: estado.trimmingCharacters(in: .whitespaces).uppercased(),
            cep: cep.trimmingCharacters(in: .whitespaces)
        )

        if var client = editingClient {
            client.nome = cleanName
            client.tipoDocumento = tipoDocumento
            client.documento = documento
            client.telefone = telefone
            client.email = email
            client.endereco = address
            dataStore.updateClient(client)
            onClientCreated?(client)
        } else {
            let newClient = Client(
                nome: cleanName,
                documento: documento,
                tipoDocumento: tipoDocumento,
                telefone: telefone,
                email: email,
                endereco: address
            )
            dataStore.addClient(newClient)
            onClientCreated?(newClient)
        }
        dismiss()
    }
}
