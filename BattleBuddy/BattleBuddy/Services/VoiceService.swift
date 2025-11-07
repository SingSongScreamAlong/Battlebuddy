//
//  VoiceService.swift
//  BattleBuddy
//
//  Speech recognition and text-to-speech service
//

import Foundation
import Speech
import AVFoundation

class VoiceService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var transcribedText = ""
    @Published var audioLevel: Float = 0.0
    @Published var permissionStatus: PermissionStatus = .notDetermined

    // MARK: - Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Text-to-Speech
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var speechCompletionHandler: (() -> Void)?

    // MARK: - Audio Session
    private let audioSession = AVAudioSession.sharedInstance()

    enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
    }

    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }

    // MARK: - Permissions
    func requestPermissions() async -> Bool {
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        // Request microphone authorization
        let micStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        let authorized = speechStatus && micStatus

        await MainActor.run {
            self.permissionStatus = authorized ? .authorized : .denied
        }

        return authorized
    }

    // MARK: - Speech-to-Text
    func startListening(onResult: @escaping (String) -> Void) {
        // Check if already listening
        guard !isListening else { return }

        // Cancel any ongoing recognition
        stopListening()

        // Configure audio session
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // Get audio input node
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                let transcription = result.bestTranscription.formattedString

                DispatchQueue.main.async {
                    self.transcribedText = transcription
                }

                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                DispatchQueue.main.async {
                    self.isListening = false
                    if !self.transcribedText.isEmpty {
                        onResult(self.transcribedText)
                    }
                }
            }
        }

        // Configure audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level for visualization
            let channelData = buffer.floatChannelData?[0]
            let channelDataCount = Int(buffer.frameLength)

            if let data = channelData {
                var sum: Float = 0
                for i in 0..<channelDataCount {
                    sum += abs(data[i])
                }
                let average = sum / Float(channelDataCount)

                DispatchQueue.main.async {
                    self?.audioLevel = average
                }
            }
        }

        // Start audio engine
        audioEngine.prepare()

        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.transcribedText = ""
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        DispatchQueue.main.async {
            self.isListening = false
            self.audioLevel = 0.0
        }
    }

    // MARK: - Text-to-Speech
    func speak(_ text: String, rate: Float = 0.5, voice: AVSpeechSynthesisVoice? = nil, onComplete: (() -> Void)? = nil) {
        // Stop any ongoing speech
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        // Store completion handler
        speechCompletionHandler = onComplete

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate // 0.0 (slow) to 1.0 (fast), default 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Use enhanced quality voice if available
        if let voice = voice {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        // Configure audio session for playback
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session for speech: \(error)")
        }

        DispatchQueue.main.async {
            self.isSpeaking = true
        }

        speechSynthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    // MARK: - Cleanup
    deinit {
        stopListening()
        stopSpeaking()
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speechCompletionHandler?()
            self.speechCompletionHandler = nil
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speechCompletionHandler?()
            self.speechCompletionHandler = nil
        }
    }
}
