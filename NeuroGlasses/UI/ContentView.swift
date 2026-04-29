import SwiftUI

struct ContentView: View {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var instructionStore = InstructionStore()
    @StateObject private var vm: NeuroViewModel

    @State private var showInstructions = false
    @State private var showSettings = false

    init() {
        let ss = SettingsStore()
        let is_ = InstructionStore()
        _settingsStore = StateObject(wrappedValue: ss)
        _instructionStore = StateObject(wrappedValue: is_)
        _vm = StateObject(wrappedValue: NeuroViewModel(settingsStore: ss, instructionStore: is_))
    }

    var body: some View {
        NavigationStack {
            ChatView(vm: vm)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(vm.glassesConnected ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(vm.glassesConnected ? "\(vm.glassesClientCount) glasses" : "No glasses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button { showInstructions = true } label: {
                            Image(systemName: "text.quote")
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        .sheet(isPresented: $showInstructions) {
            InstructionsView(vm: vm)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(store: settingsStore)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
    }
}
