import SwiftUI

struct InstructionsView: View {
    @ObservedObject var vm: NeuroViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var editTarget: Instruction?

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.instructionStore.instructions) { instruction in
                    Button {
                        vm.selectedInstruction = instruction
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(instruction.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                if vm.selectedInstruction?.id == instruction.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            Text(instruction.prompt)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            vm.instructionStore.instructions.removeAll { $0.id == instruction.id }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editTarget = instruction
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            }
            .navigationTitle("Instructions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAdd) {
                InstructionEditView(instruction: nil) { newInstruction in
                    vm.instructionStore.instructions.append(newInstruction)
                }
            }
            .sheet(item: $editTarget) { target in
                InstructionEditView(instruction: target) { updated in
                    if let idx = vm.instructionStore.instructions.firstIndex(where: { $0.id == updated.id }) {
                        vm.instructionStore.instructions[idx] = updated
                    }
                }
            }
        }
    }
}

struct InstructionEditView: View {
    let instruction: Instruction?
    let onSave: (Instruction) -> Void

    @State private var title: String
    @State private var prompt: String
    @Environment(\.dismiss) private var dismiss

    init(instruction: Instruction?, onSave: @escaping (Instruction) -> Void) {
        self.instruction = instruction
        self.onSave = onSave
        _title = State(initialValue: instruction?.title ?? "")
        _prompt = State(initialValue: instruction?.prompt ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Summarize", text: $title)
                }
                Section("Prompt") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(instruction == nil ? "New Instruction" : "Edit Instruction")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let result = Instruction(
                            id: instruction?.id ?? UUID(),
                            title: title,
                            prompt: prompt
                        )
                        onSave(result)
                        dismiss()
                    }
                    .disabled(title.isEmpty || prompt.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
