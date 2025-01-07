import Foundation
import WebKit
import AVFoundation

struct DeepgramResponse: Codable {
    let metadata: Metadata
    let results: Results
}

struct Metadata: Codable {
    let transactionKey: String?
    let requestID: String
    let sha256: String
    let created: String // You can parse this into a Date if needed
    let duration: Double
    let channels: Int
    let models: [String]
    let modelInfo: [String: ModelInfo]

    enum CodingKeys: String, CodingKey {
        case transactionKey = "transaction_key"
        case requestID = "request_id"
        case sha256
        case created
        case duration
        case channels
        case models
        case modelInfo = "model_info"
    }
}

struct ModelInfo: Codable {
    let name: String
    let version: String
    let arch: String
}

struct Results: Codable {
    let channels: [Channel]
}

struct Channel: Codable {
    let alternatives: [Alternative]
}

struct Alternative: Codable {
    let transcript: String
    let confidence: Double
    let words: [Word]
    let paragraphs: Paragraphs?
}

struct Word: Codable {
    let word: String
    let start: Double
    let end: Double
    let confidence: Double
    let punctuatedWord: String?

    enum CodingKeys: String, CodingKey {
        case word
        case start
        case end
        case confidence
        case punctuatedWord = "punctuated_word"
    }
}

struct Paragraphs: Codable {
    let transcript: String
    let paragraphs: [Paragraph]
}

struct Paragraph: Codable {
    let sentences: [Sentence]
    let numWords: Int
    let start: Double
    let end: Double

    enum CodingKeys: String, CodingKey {
        case sentences
        case numWords = "num_words"
        case start
        case end
    }
}

struct Sentence: Codable {
    let text: String
    let start: Double
    let end: Double
}

struct ProfanityTimestamp {
    let word: String
    let start: Double 
    let end: Double
}

struct ProfanityAnalysis {
    let timestamps: [ProfanityTimestamp]
    let transcript: String
}

@MainActor
@Observable
public final class DeepgramService {
    private var webSocket: URLSessionWebSocketTask?
    var isListening = false
    var onTranscriptReceived: ((String) -> Void)?
    var onTranscriptionComplete: (() -> Void)?
    
    private var transcriptionTimer: Timer?
    private var lastTranscriptionTime: Date?
    
    let apiKey: String
        
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func requestTranscript(audioFileURL: URL) async throws -> DeepgramResponse {
        // Read the audio file as binary data
        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioFileURL)
        } catch {
            throw NSError(domain: "com.example.app", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to read audio file: \(error.localizedDescription)"])
        }
        // Specify the URL for the Deepgram API endpoint
//        let url = URL(string: "https://api.deepgram.com/v1/listen")!
        
        // Specify the URL for the Deepgram API endpoint with parameters
          var components = URLComponents(string: "https://api.deepgram.com/v1/listen")!
          components.queryItems = [
              URLQueryItem(name: "model", value: "nova-2"),
              URLQueryItem(name: "smart_format", value: "true")
          ]
          let url = components.url!
        
        // Create the URLRequest object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set request headers
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization") // Replace DEEPGRAM_API_KEY with your actual API key
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        
        // Set request body with audio data
        request.httpBody = audioData
        
        // Perform the request using async/await
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Error response from Deepgram: \(response)")
                    throw DeepgramError.invalidResponse
                } else {
                    print("No error response, status code: \(response)")
                    throw DeepgramError.invalidResponse
                }
        }
        // Decode the JSON response into the structs
        do {
            let decoder = JSONDecoder()
            let deepgramResponse = try decoder.decode(DeepgramResponse.self, from: data)
            return deepgramResponse
        } catch {
            throw NSError(domain: "com.example.app", code: 3, userInfo: [NSLocalizedDescriptionKey: "Error decoding JSON: \(error.localizedDescription)"])
        }
    }
    
    func startRealtimeTranscription() {
        let wsURL = "wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=44100&channels=1&model=nova-2"
        guard let url = URL(string: wsURL) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        
        isListening = true
        receiveMessage()
    }
    
    private func receiveMessage() {
        
        Task { @MainActor in
            do {
                if let message = try await webSocket?.receive() {
                    switch message {
                    case .data(let data):
                        handleTranscriptData(data)
                    case .string(let str):
                        handleTranscriptString(str)
                    @unknown default:
                        break
                    }
                    // Continue receiving if still listening
                    if isListening == true {
                        receiveMessage()
                    }
                }
            } catch {
                print("WebSocket error: \(error)")
            }
        }
        
    }
    
    private func handleTranscriptString(_ jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return
        }
               
        struct RealtimeResponse: Codable {
            struct Alternative: Codable {
                let transcript: String
                let confidence: Double
            }
            struct Channel: Codable {
                let alternatives: [Alternative]
            }
            let channel: Channel
            let is_final: Bool
        }
        
        do {
            let response = try JSONDecoder().decode(RealtimeResponse.self, from: jsonData)
            print("Transcript: \(response.channel.alternatives.first?.transcript ?? "NO TRANS")")
            if response.is_final,
               let transcript = response.channel.alternatives.first?.transcript {
                Task { @MainActor [weak self] in
                    self?.onTranscriptReceived?(transcript)
                    self?.resetTranscriptionTimer()
                }
            }
        } catch {
            print("Failed to decode realtime response: \(error)")
        }
    }
    
    func sendAudioData(_ samples: [Float]) {
        guard isListening else { return }
        
        // Convert float samples to 16-bit PCM
        var int16Data = [Int16]()
        for sample in samples {
            let clamped = min(max(sample, -1.0), 1.0)
            let int16Sample = Int16(clamped * Float(Int16.max))
            int16Data.append(int16Sample)
        }
        
        let data = Data(bytes: int16Data, count: int16Data.count * MemoryLayout<Int16>.size)
        
        webSocket?.send(.data(data)) { error in
            if let error = error {
                print("Error sending audio data: \(error)")
            }
        }
    }
    
    func stopRealtimeTranscription() {
        isListening = false
        webSocket?.cancel()
        webSocket = nil
    }
    
    private func handleTranscriptData(_ data: Data) {
        guard let jsonString = String(data: data, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert websocket data")
            return
        }
        
        struct RealtimeResponse: Codable {
            struct Alternative: Codable {
                let transcript: String
            }
            struct Channel: Codable {
                let alternatives: [Alternative]
            }
            let channel: Channel
            let is_final: Bool
        }
        
        do {
            let response = try JSONDecoder().decode(RealtimeResponse.self, from: jsonData)
            if response.is_final,
               let transcript = response.channel.alternatives.first?.transcript {
                onTranscriptReceived?(transcript)
            }
        } catch {
            print("Failed to decode realtime response: \(error)")
        }
    }
    
    private func resetTranscriptionTimer() {
        transcriptionTimer?.invalidate()
        transcriptionTimer = nil
        lastTranscriptionTime = Date()
        
        print("Starting transcription timer at \(self.lastTranscriptionTime!)")
        
        transcriptionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("Transcription complete")
            Task { @MainActor in
                self.onTranscriptionComplete?()
                self.stopRealtimeTranscription()
            }
        }
    }
}

enum DeepgramError: Error {
    case invalidResponse
    case decodingError
}
