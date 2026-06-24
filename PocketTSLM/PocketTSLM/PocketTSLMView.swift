//
// This source file is part of the PocketTSLM project
//
// SPDX-FileCopyrightText: 2026 The Authors
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SwiftUI
import OSLog

/// Chat-style front end for PocketTSLM. On launch it loads the model via the Spezi LLM
/// stack; once ready it offers four suggestion buttons (EEG/ECG benchmark, EEG/ECG
/// sample). Tapping one runs the operation on-device and appends the constructed prompt
/// as the sender bubble and the model's generated answer as the reply bubble.
struct PocketTSLMView: View {
    private static let logger = Logger(subsystem: "PocketTSLM", category: "PocketTSLMView")

    @Environment(HealthDataInterpreter.self) private var interpreter

    @State private var chat: Chat = []
    @State private var didSetup = false
    @State private var isRunning = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if interpreter.loaded {
                    chatInterface
                } else {
                    loadingView
                }
            }
            .navigationTitle("PocketTSLM")
            .toolbar {
                if interpreter.loaded && !chat.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { chat.removeAll() } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .disabled(isRunning)
                        .accessibilityLabel(Text("Clear"))
                    }
                }
            }
        }
        .task {
            guard !didSetup else { return }
            didSetup = true
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }
            do {
                try await interpreter.setup()
            } catch {
                Self.logger.error("setup() failed: \(error.localizedDescription, privacy: .public)")
                errorMessage = error.localizedDescription
            }
        }
    }

    private var chatInterface: some View {
        VStack(spacing: 0) {
            if chat.isEmpty {
                emptyState
            } else {
                MessagesView(chat, hideMessages: .custom(hiddenMessageTypes: []))
            }
            Divider()
            actionBar
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("On-device time-series LLM")
                .font(.headline)
            Text("Pick a task below to run it on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var actionBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                actionButton("EEG bench", systemImage: "chart.bar") { await interpreter.eegBenchmark() }
                actionButton("ECG bench", systemImage: "chart.bar.doc.horizontal") { await interpreter.ecgBenchmark() }
            }
            HStack(spacing: 8) {
                actionButton("EEG sample", systemImage: "brain.head.profile") { await interpreter.eegSample() }
                actionButton("ECG sample", systemImage: "heart.text.square") { await interpreter.ecgSample() }
            }
            if isRunning {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Running on-device…").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding()
    }

    private func actionButton(
        _ title: String,
        systemImage: String,
        _ operation: @escaping () async -> ChatTurn
    ) -> some View {
        Button {
            run(operation)
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRunning)
    }

    private func run(_ operation: @escaping () async -> ChatTurn) {
        isRunning = true
        Task {
            let turn = await operation()
            await MainActor.run {
                chat.append(ChatEntity(role: .user, content: turn.prompt))
                chat.append(ChatEntity(role: .assistant, content: turn.response))
                isRunning = false
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            if !errorMessage.isEmpty {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Setup failed").font(.headline)
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                ProgressView()
                Text(interpreter.loadingStage.rawValue).font(.subheadline)
                if !interpreter.loadingDetail.isEmpty {
                    Text(interpreter.loadingDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            Spacer()
        }
    }
}
