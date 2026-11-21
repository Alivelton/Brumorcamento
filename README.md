# Brum Orçamento (iOS) - SwiftPM + xtool

Aplicativo iOS nativo em **SwiftUI** estruturado como pacote **Swift Package Manager (SwiftPM)** com suporte ao **[xtool](https://github.com/xtool-org/xtool)** para compilação, assinatura e deploy sem necessidade do Xcode pesado no Linux ou macOS.

---

## Módulos e Funcionalidades

1. **Orçamentos (`Quotes`)**:
   - Criação e cálculo automático de itens de **Material / Produto** e **Serviço / Mão de Obra**.
   - Controle de validade com padrão de 15 dias.
   - Status: *Rascunho*, *Enviado*, *Aprovado*, *Faturado* e *Cancelado*.
   - Integração com **Mercado Pago** (geração automática de código Pix Copia e Cola EMVCo e links de checkout).

2. **A Receber (`Receivables`)**:
   - Acompanhamento do fluxo financeiro com cartões de status (*Pendente*, *Pago*, *Atrasado*).
   - Liquidação e baixa de cobranças direta com registro da forma de pagamento.
   - Geração de Pix avulso por parcela.

3. **Clientes (`Clients`)**:
   - Cadastro ágil e completo (Nome, CNPJ/CPF, Telefone, E-mail, Endereço).
   - Ações rápidas: Ligar e Chamar no WhatsApp.

4. **Ajustes e Persistência (`Settings` & `DataStore`)**:
   - Persistência local atômica em `Documents/dados_brum.json`.
   - Inicialização automática a partir de `dados_iniciais.json` / backup no primeiro uso.
   - Exportação e restauração da base via painel do sistema.

---

## Estrutura de Diretórios

```
BrumOrcamento/
├── Package.swift                             # Manifesto SwiftPM
├── xtool.yml                                 # Configuração xtool (bundleID, infoPath)
├── .gitignore
├── README.md
├── backup_dados_brum/
│   └── dados_existentes.json                 # Backup de dados existente
└── Sources/
    └── BrumOrcamento/
        ├── BrumOrcamentoApp.swift            # Entry point (@main)
        ├── Models/
        │   ├── AppDatabase.swift             # Schema do banco
        │   ├── Client.swift                  # Modelos de Clientes e Endereço
        │   ├── Quote.swift                   # Modelos de Orçamentos e Itens
        │   └── Receivable.swift              # Modelos de Cobranças / Parcelas
        ├── Services/
        │   ├── DataStore.swift               # Persistência e estado reativo
        │   └── MercadoPagoService.swift      # Cobranças e Pix EMVCo
        ├── Views/
        │   ├── MainTabView.swift             # Navegação principal por abas
        │   ├── Common/
        │   │   ├── Formatters.swift          # Formatação de moeda BRL, datas e badges
        │   │   └── StatCardView.swift        # Cards de totais financeiros
        │   ├── Quotes/
        │   │   ├── QuotesListView.swift
        │   │   ├── QuoteDetailView.swift
        │   │   └── NewQuoteView.swift
        │   ├── Receivables/
        │   │   ├── ReceivablesListView.swift
        │   │   └── ReceivableDetailView.swift
        │   ├── Clients/
        │   │   ├── ClientsListView.swift
        │   │   ├── ClientDetailView.swift
        │   │   └── ClientFormView.swift
        │   └── Settings/
        │       └── SettingsView.swift
        └── Resources/
            ├── Info.plist                    # Metadados do app iOS
            └── dados_iniciais.json           # Base inicial de dados
```

---

## Como Rodar com `xtool`

```bash
cd /home/alivelton/BrumOrcamento

# Compila, assina e instala no iPhone conectado via USB:
xtool dev

# Listar dispositivos conectados:
xtool devices
```
