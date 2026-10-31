//
//  CreatePostView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import SwiftUI

struct CreatePostView: View {
    @Bindable var appState: AppState
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Admin")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Give Oriva something you don't want to keep track of yourself.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {

                    NavigationLink {
                        PhotoTextImportView(appState: appState, startWithCamera: true)
                    } label: {
                        CaptureOptionContent(
                            icon: "camera.fill",
                            title: "Take a Photo",
                            subtitle: "Letters, bills, receipts and notices"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PhotoTextImportView(appState: appState)
                    } label: {
                        CaptureOptionContent(
                            icon: "photo.fill",
                            title: "Choose Photo or Screenshot",
                            subtitle: "Use something already on your phone"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        DocumentsView(appState: appState, startWithPDFImport: true)
                    } label: {
                        CaptureOptionContent(
                            icon: "doc.fill",
                            title: "Upload PDF",
                            subtitle: "Bills, policies, forms and documents"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PasteTextView(appState: appState)
                    } label: {
                        CaptureOptionContent(
                            icon: "text.alignleft",
                            title: "Paste Text",
                            subtitle: "Emails, messages or other information"
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")

                    Text("Nothing is acted on until you review it.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}


// MARK: - Inactive Capture Option

struct CaptureOption: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Button {
            // These capture methods will be connected later.
        } label: {
            CaptureOptionContent(
                icon: icon,
                title: title,
                subtitle: subtitle
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Capture Option Appearance

struct CaptureOptionContent: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {

            Image(systemName: icon)
                .font(.title2)
                .frame(width: 42, height: 42)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {

                Text(title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        }
    }
}


#Preview {
    CreatePostView(appState: AppState())
}
