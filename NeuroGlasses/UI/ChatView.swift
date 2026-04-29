import SwiftUI

struct ChatView: View {
    @ObservedObject var vm: NeuroViewModel
    @State private var inputText = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if vm.isStreaming && !vm.currentStreamText.isEmpty {
                            StreamingBubble(text: vm.currentStreamText)
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: vm.currentStreamText) { _ in
                    withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                }
            }

            Divider()

            if let instruction = vm.selectedInstruction {
                HStack {
                    Image(systemName: "text.quote")
                        .foregroundColor(.accentColor)
                    Text(instruction.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button { vm.selectedInstruction = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
            }

            HStack(spacing: 12) {
                TextField("Message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4)
                    .focused($focused)
                    .onSubmit { sendText() }

                Button(action: sendText) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isStreaming)

                RecordButton(isRecording: vm.isRecording, isStreaming: vm.isStreaming) {
                    vm.toggleRecording()
                }
            }
            .padding()
        }
        .navigationTitle("NeuroGlasses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.clearHistory() } label: {
                    Image(systemName: "trash")
                }
                .disabled(vm.messages.isEmpty)
            }
        }
    }

    private func sendText() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        vm.sendText(text)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct StreamingBubble: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .padding(12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 60)
        }
    }
}

struct RecordButton: View {
    let isRecording: Bool
    let isStreaming: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .foregroundColor(isRecording ? .white : .primary)
            }
        }
        .disabled(isStreaming)
    }
}
