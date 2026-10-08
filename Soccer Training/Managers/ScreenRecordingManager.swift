// ScreenRecordingManager.swift
// Lets the player record the app's screen (with their own narration) and
// share it, without needing to find Screen Recording in Control Center.
// Uses ReplayKit's built-in preview/share sheet, so "record" and "post it"
// happen in one flow.

import AVFoundation
import Combine
import ReplayKit
import UIKit

@MainActor
final class ScreenRecordingManager: NSObject, ObservableObject {
    static let shared = ScreenRecordingManager()

    @Published private(set) var isRecording = false
    @Published var errorMessage: String?
    /// Shows you on camera (a small bubble composited into the recording),
    /// not just the app's screen.
    @Published var isCameraEnabled = true
    @Published var cameraPosition: RPCameraPosition = .front {
        didSet { recorder.cameraPosition = cameraPosition }
    }

    private let recorder = RPScreenRecorder.shared()

    /// The live camera self-view, once recording starts with the camera
    /// enabled. Nil until then, per ReplayKit's own API.
    var cameraPreviewView: UIView? {
        recorder.cameraPreviewView
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard recorder.isAvailable else {
            errorMessage = "Screen recording isn't available on this device."
            return
        }

        Task {
            guard await AVAudioApplication.requestRecordPermission() else {
                errorMessage = "Microphone access is off. Turn it on in Settings to hear your voice in recordings."
                return
            }
            beginRecording()
        }
    }

    private func beginRecording() {
        // Other parts of the app (the Pass and Turn drill's voice callouts)
        // can leave the shared audio session in a playback-only category.
        // That silently blocks ReplayKit's microphone capture even with
        // permission granted, so force a recording-capable session first.
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try? audioSession.setActive(true, options: [])

        // ReplayKit doesn't include narration unless this is explicitly on.
        // Set it immediately before starting in case another recording flow
        // changed the shared recorder's configuration.
        recorder.isMicrophoneEnabled = true
        recorder.isCameraEnabled = isCameraEnabled
        recorder.cameraPosition = cameraPosition
        recorder.startRecording { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.isRecording = true
                }
            }
        }
    }

    private func stopRecording() {
        recorder.stopRecording { [weak self] previewViewController, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isRecording = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let previewViewController else { return }
                previewViewController.previewControllerDelegate = self
                Self.topViewController()?.present(previewViewController, animated: true)
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            var top = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else {
            return nil
        }

        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

extension ScreenRecordingManager: RPPreviewViewControllerDelegate {
    nonisolated func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        Task { @MainActor in
            previewController.dismiss(animated: true)
        }
    }
}
