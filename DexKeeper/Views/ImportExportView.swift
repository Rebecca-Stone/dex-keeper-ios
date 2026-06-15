import SwiftUI
import UIKit

struct ImportExportView: View {
    @EnvironmentObject private var store: TeamStore
    @Environment(\.dismiss) private var dismiss

    @State private var importText = ""
    @State private var importError: String?
    @State private var copied = false

    private var exportString: String { store.exportJSON() }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ScrollView {
                        Text(exportString)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 180)

                    Button {
                        UIPasteboard.general.string = exportString
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    } label: {
                        Label(copied ? "Copied!" : "Copy JSON", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }

                    ShareLink(item: exportString) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Copy or share this team. Paste it below on another device to import.")
                }

                Section {
                    TextEditor(text: $importText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 120)
                    if let importError {
                        Text(importError).font(.caption).foregroundStyle(.red)
                    }
                    Button {
                        if let s = UIPasteboard.general.string { importText = s }
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                    }
                    Button {
                        do {
                            try store.importJSON(importText)
                            dismiss()
                        } catch {
                            importError = error.localizedDescription
                        }
                    } label: {
                        Label("Replace My Team", systemImage: "square.and.arrow.down")
                    }
                    .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text("Import")
                } footer: {
                    Text("Importing replaces your current team.")
                }
            }
            .navigationTitle("Export / Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
