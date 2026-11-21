# Brum Orçamentos (iOS) - SwiftPM + xtool

Aplicativo iOS nativo em **SwiftUI** estruturado como pacote **Swift Package Manager (SwiftPM)**, compatível com a ferramenta **[xtool](https://github.com/xtool-org/xtool)**. Focado na agilidade de atendimento em campo (**Orçamentos de Rua**) para a **Brum Soluções Técnicas**.

---

## Funcionalidades Principais

1. **Atendimento Rápido em Campo (Offline-First)**:
   - Registro do Cliente / Condomínio, WhatsApp e observações.
   - Adição dinâmica de itens (**Serviço** ou **Material**) com controle de unidade (`SV`, `UN`), quantidade, custo unitário e preço de venda.
   - Cálculo instantâneo do custo total, valor de venda e margem de lucro estimada.

2. **Compartilhamento Imediato**:
   - **WhatsApp**: Disparo com mensagem formatada em Markdown, valores destacados e cálculo de totais.
   - **Copiar Texto**: Cópia rápida para a área de transferência do iOS (`UIPasteboard`).

3. **Persistência Local e Histórico**:
   - Armazenamento atômico no iPhone via `UserDefaults` (`brum_solucoes_orcamentos_v1`).
   - Identificadores sequenciais temporários (`ORC-RUA-001`, `ORC-RUA-002`, ...).
   - Indicador visual de sincronização (*Sincronizado* vs *Pendente sync*).

4. **Sincronização com o Servidor (Cloudflare / API)**:
   - Endpoint: `https://faturamento.brum.xyz.br/api/orcamentos-rua` (configurável pelo usuário).
   - Suporte a Bearer Token simples de autenticação.
   - Envio em lote com atualização automática do status local após confirmação HTTP.

---

## Estrutura do Projeto

```
BrumOrcamento/
├── Package.swift                             # Manifesto SwiftPM (iOS 17, executable BrumOrcamento)
├── xtool.yml                                 # Configuração xtool (bundleID, displayName, product)
├── .gitignore
├── README.md
└── Sources/
    └── BrumOrcamento/
        ├── BrumOrcamentoApp.swift            # Entry point (@main struct BrumOrcamentoApp: App)
        ├── ContentView.swift                 # View principal, modelos (ItemOrcamento, OrcamentoRua) e sync
        └── Resources/
            └── Info.plist                    # Bundle metadata (CFBundleDisplayName, CFBundleIdentifier)
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
