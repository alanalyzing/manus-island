import AVFoundation
import AppKit
import Foundation

/// Records audio from the microphone and transcribes it via OpenAI Whisper API
@MainActor
class VoiceInputManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var recordingLevel: Float = 0
    @Published var recordingDuration: TimeInterval = 0
    @Published var error: String?

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var recordingStart: Date?
    private let recordingURL: URL

    override init() {
        let tempDir = FileManager.default.temporaryDirectory
        self.recordingURL = tempDir.appendingPathComponent("manus_voice_input.wav")
        super.init()
    }

    // MARK: - Recording

    func startRecording() {
        error = nil
        transcribedText = ""

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            recordingStart = Date()
            recordingDuration = 0

            // Update level meter and duration
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, let recorder = self.audioRecorder else { return }
                    recorder.updateMeters()
                    let level = recorder.averagePower(forChannel: 0)
                    // Normalize from -160..0 dB to 0..1
                    self.recordingLevel = max(0, min(1, (level + 50) / 50))
                    if let start = self.recordingStart {
                        self.recordingDuration = Date().timeIntervalSince(start)
                    }
                }
            }
        } catch {
            self.error = "Microphone access denied or unavailable"
            isRecording = false
        }
    }

    func stopRecording() async -> String? {
        guard isRecording else { return nil }
        audioRecorder?.stop()
        audioRecorder = nil
        levelTimer?.invalidate()
        levelTimer = nil
        isRecording = false
        recordingLevel = 0

        // Transcribe the recorded audio
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            error = "Recording file not found"
            return nil
        }

        let text = await transcribeAudio(fileURL: recordingURL)
        if let text = text {
            transcribedText = text
        }
        return text
    }

    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        levelTimer?.invalidate()
        levelTimer = nil
        isRecording = false
        recordingLevel = 0
        recordingDuration = 0
        try? FileManager.default.removeItem(at: recordingURL)
    }

    // MARK: - Transcription via OpenAI Whisper

    private func transcribeAudio(fileURL: URL) async -> String? {
        var openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        if openAIKey.isEmpty {
            openAIKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? ""
        }
        guard !openAIKey.isEmpty else {
            error = "OpenAI API key not set. Add it in Settings or set OPENAI_API_KEY env var."
            return nil
        }

        guard let audioData = try? Data(contentsOf: fileURL) else {
            error = "Could not read audio file"
            return nil
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body = Data()
        // Model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        // Audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                error = "Transcription failed"
                return nil
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }
        return nil
    }
}
