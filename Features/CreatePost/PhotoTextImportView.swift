import SwiftUI
import PhotosUI
import Vision
import UIKit
import ImageIO

struct PhotoTextImportView: View {
    @Bindable var appState: AppState
    var startWithCamera: Bool = false

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var extractedText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(startWithCamera ? "Take a Photo" : "Choose Photo or Screenshot")
                    .font(.title2.bold())

                Text(startWithCamera
                     ? "Photograph a clear, well-lit letter, bill, receipt or notice. Review the recognised text before tracking anything."
                     : "Select a clear image of a letter, bill, receipt or notice. Oriva will recognise its text so you can review it before tracking anything.")
                    .foregroundStyle(.secondary)

                if startWithCamera {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            errorMessage = nil
                            showCamera = true
                        } else {
                            errorMessage = "The camera is unavailable on this device or simulator. Test capture on a physical iPhone, or use Choose Photo or Screenshot."
                        }
                    } label: {
                        Label("Open Camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                } else {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                }

                if isProcessing {
                    ProgressView("Reading image…")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                if !extractedText.isEmpty {
                    Text("Recognised text")
                        .font(.headline)
                    TextEditor(text: $extractedText)
                        .frame(minHeight: 220)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    NavigationLink {
                        AdminAnalysisView(appState: appState, originalText: extractedText)
                    } label: {
                        Text("Review Information")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing || extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .navigationTitle(startWithCamera ? "Camera" : "Photo Text")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            OrivaCameraPicker { image in
                Task { await recogniseText(in: image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task { await recogniseText(from: newValue) }
        }
    }

    @MainActor
    private func recogniseText(from item: PhotosPickerItem) async {
        isProcessing = true
        extractedText = ""
        errorMessage = nil
        defer { isProcessing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "This image could not be opened. Please choose another photo or screenshot."
                return
            }
            try performRecognition(on: image)
        } catch {
            errorMessage = "Text recognition failed. Please try another image."
        }
    }

    @MainActor
    private func recogniseText(in image: UIImage) async {
        isProcessing = true
        extractedText = ""
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try performRecognition(on: image)
        } catch {
            errorMessage = "Text recognition failed. Please take another photo."
        }
    }

    @MainActor
    private func performRecognition(on image: UIImage) throws {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler: VNImageRequestHandler
        if let cgImage = image.cgImage {
            handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: CGImagePropertyOrientation(image.imageOrientation),
                options: [:]
            )
        } else if let ciImage = image.ciImage {
            handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        } else {
            errorMessage = "This image could not be opened. Please try another image."
            return
        }

        try handler.perform([request])
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            errorMessage = "No readable text was found. Try a clearer image."
        } else {
            extractedText = text
        }
    }
}

private struct OrivaCameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            dismiss()
            if let image { onCapture(image) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
