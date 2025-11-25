//
//  MediaSource.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/25.
//

import Foundation


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
    case screen(ScreenSource)
    case audio(AudioSource)
    case input(InputSource)
}
