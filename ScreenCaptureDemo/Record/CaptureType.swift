//
//  CaptureType.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/29.
//

import Foundation

enum VideoSource {
    case screen
    case window
    case camera
}

enum AudioSource {
    case system
    case microphone
}

enum InputSource {
    case mouseMove
    case mouseClick
    case cursor
    case keyboard
}

enum CaptureType {
    case video(VideoSource)
    case audio(AudioSource)
    case input(InputSource)
}
