import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            QuotesListView()
                .tabItem {
                    Label("Orçamentos", systemImage: "doc.text.fill")
                }
                .tag(0)

            ReceivablesListView()
                .tabItem {
                    Label("A Receber", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            ClientsListView()
                .tabItem {
                    Label("Clientes", systemImage: "person.2.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}
