// CameraPreviewBubble.swift
// A small draggable self-view shown while recording with the camera enabled,
// so the player can see themselves while narrating. Purely a live preview —
// ReplayKit composites the camera into the recorded video on its own even
// if this bubble is never shown.

import ReplayKit
import SwiftUI

private struct CameraPreviewRepresentable: UIViewRepresentable {
    let previewView: UIView

    func makeUIView(context: Context) -> UIView {
        previewView
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}

struct CameraPreviewBubble: View {
    @ObservedObject private var recorder = ScreenRecordingManager.shared
    @State private var dragOffset: CGSize = .zero
    @State private var position = CGSize(width: -16, height: -100)

    var body: some View {
        if recorder.isRecording, recorder.isCameraEnabled, let previewView = recorder.cameraPreviewView {
            CameraPreviewRepresentable(previewView: previewView)
                .frame(width: 100, height: 100)
                .clipShape(.circle)
                .overlay {
                    Circle().stroke(Color.soccerAccent, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                .offset(x: position.width + dragOffset.width, y: position.height + dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation }
                        .onEnded { value in
                            position.width += value.translation.width
                            position.height += value.translation.height
                            dragOffset = .zero
                        }
                )
                .transition(.opacity)
                .allowsHitTesting(true)
        }
    }
}
