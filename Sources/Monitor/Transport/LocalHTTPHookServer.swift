import Foundation
import Network

// MARK: - LocalHTTPHookServer

/// Provider-agnostic local HTTP transport for hook delivery.
///
/// Lifecycle:
/// - `start(handler:)` binds to a local port and writes the port/token files.
/// - `stop()` cancels the listener and removes the port/token files.
///
/// The transport only manages HTTP concerns plus deferred connection handling.
/// Provider-specific response bodies are produced by the caller.
@MainActor
final class LocalHTTPHookServer {

    // MARK: - Types

    /// Handler called when a valid POST /hook request arrives.
    /// - Returns nil for async hooks (immediate 200 OK sent).
    /// - Returns a response body for immediate responses, or a transport marker
    ///   produced by `deferredResponseMarker(id:)` to keep the connection open.
    typealias HookHandler = @MainActor (_ payload: [String: Any]) -> [String: Any]?

    struct DeferredConnection {
        let id: String
        let provider: ProviderKind
        let connection: NWConnection
    }

    // MARK: - Constants

    static let portFile = NSHomeDirectory() + "/.claude/cc-beeper/port"
    static let tokenFile = NSHomeDirectory() + "/.claude/cc-beeper/token"
    private static let portRange: [UInt16] = Array(19222...19230)

    private enum TransportMetadata {
        static let holdConnection = "_hold_connection"
        static let deferredResponseID = "_transport_deferred_id"
    }

    // MARK: - State

    private var listener: NWListener?
    private var handler: HookHandler?
    private(set) var activePort: UInt16 = 0
    private(set) var bearerToken: String = ""

    /// Per-connection receive buffers, keyed by ObjectIdentifier of the NWConnection.
    private var connectionBuffers: [ObjectIdentifier: Data] = [:]

    /// Ordered deferred responses keyed by caller-provided ID.
    private(set) var pendingDeferredConnections: [DeferredConnection] = []

    // MARK: - Public API

    /// Start the HTTP server. Tries ports 19222-19230, falls back to OS-assigned port.
    /// Generates a cryptographic bearer token and writes it to the token file.
    func start(handler: @escaping HookHandler) {
        self.handler = handler
        generateAndWriteToken()
        startListener(portIndex: 0)
    }

    /// Stop the HTTP server and remove the port file and token file.
    func stop() {
        listener?.cancel()
        listener = nil
        removePort()
        removeToken()
        activePort = 0
    }

    /// Create a transport-only marker instructing the server to keep the
    /// connection open until `sendDeferredResponse(_:for:)` is called.
    static func deferredResponseMarker(id: String) -> [String: Any] {
        [
            TransportMetadata.holdConnection: true,
            TransportMetadata.deferredResponseID: id
        ]
    }

    /// Send a deferred HTTP response to a pending connection for the given ID.
    /// Returns true if more pending connections remain.
    @discardableResult
    func sendDeferredResponse(_ payload: [String: Any], for provider: ProviderKind, id: String) -> Bool {
        guard let index = pendingDeferredConnections.firstIndex(where: { $0.provider == provider && $0.id == id }) else { return false }
        let connection = pendingDeferredConnections.remove(at: index).connection
        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            sendResponse(200, body: body, on: connection)
        } else {
            sendResponse(200, body: Data(), on: connection)
        }
        return !pendingDeferredConnections.isEmpty
    }

    /// Cancel and remove all deferred responses for the given ID.
    /// If `fallbackPayload` is provided, a 200 response is sent before closing.
    func cancelDeferredResponses(for provider: ProviderKind, id: String, fallbackPayload: [String: Any]? = nil) {
        pendingDeferredConnections.removeAll { entry in
            guard entry.provider == provider && entry.id == id else { return false }
            if let fallbackPayload,
               let body = try? JSONSerialization.data(withJSONObject: fallbackPayload) {
                sendResponse(200, body: body, on: entry.connection)
            } else {
                entry.connection.cancel()
            }
            return true
        }
    }

    // MARK: - Instance Detection

    /// Check whether another vibe-beeper instance is listening on the given port.
    /// Performs a synchronous HTTP GET with a 2-second timeout.
    static func isPortResponding(_ port: UInt16) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isAlive = false
        let url = URL(string: "http://127.0.0.1:\(port)/hook")!
        var request = URLRequest(url: url, timeoutInterval: 2.0)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { _, response, _ in
            isAlive = (response as? HTTPURLResponse) != nil
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + 3.0)
        return isAlive
    }

    // MARK: - Port File

    /// Read the port number from the port file. Returns nil if the file doesn't exist or is invalid.
    static func readPort() -> UInt16? {
        guard let data = FileManager.default.contents(atPath: portFile),
              let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let port = UInt16(str) else { return nil }
        return port
    }

    /// Write the active port number atomically to the port file.
    func writePort(_ port: UInt16) {
        let dir = (Self.portFile as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        } catch {
            portWriteError = "Failed to create IPC directory: \(error.localizedDescription)"
            return
        }

        let tmp = Self.portFile + ".tmp"
        let content = "\(port)"
        do {
            try content.write(toFile: tmp, atomically: false, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: Self.portFile)
            try FileManager.default.moveItem(atPath: tmp, toPath: Self.portFile)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: Self.portFile)
            portWriteError = nil
        } catch {
            portWriteError = "Failed to write port file: \(error.localizedDescription)"
        }
    }

    /// Last port write error, if any. Nil means success.
    private(set) var portWriteError: String?

    /// Last listener error, if any. Nil means success.
    private(set) var listenerError: String?

    /// Remove the port file if it exists.
    func removePort() {
        try? FileManager.default.removeItem(atPath: Self.portFile)
    }

    // MARK: - Token Management

    /// Generate a cryptographically random bearer token and write it to the token file.
    private func generateAndWriteToken() {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        bearerToken = bytes.map { String(format: "%02x", $0) }.joined()

        let fm = FileManager.default
        let dir = (Self.tokenFile as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let tmp = Self.tokenFile + ".tmp"
        do {
            try bearerToken.write(toFile: tmp, atomically: false, encoding: .utf8)
            try? fm.removeItem(atPath: Self.tokenFile)
            try fm.moveItem(atPath: tmp, toPath: Self.tokenFile)
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: Self.tokenFile)
        } catch {
            portWriteError = "Failed to write token file: \(error.localizedDescription)"
        }
    }

    /// Remove the token file.
    private func removeToken() {
        try? FileManager.default.removeItem(atPath: Self.tokenFile)
    }

    // MARK: - Private: Listener Lifecycle

    private func startListener(portIndex: Int) {
        let ports = Self.portRange
        let portToTry: NWEndpoint.Port

        if portIndex < ports.count {
            portToTry = NWEndpoint.Port(rawValue: ports[portIndex])!
        } else {
            portToTry = NWEndpoint.Port(rawValue: 0)!
        }

        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host("127.0.0.1"),
            port: portToTry
        )

        guard let newListener = try? NWListener(using: params) else {
            listenerError = "Failed to create NWListener on port \(portToTry.rawValue)"
            return
        }

        newListener.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch state {
                case .ready:
                    let boundPort = newListener.port?.rawValue ?? 0
                    self.activePort = boundPort
                    self.listenerError = nil
                    self.writePort(boundPort)
                case .failed:
                    newListener.cancel()
                    self.startListener(portIndex: portIndex + 1)
                case .cancelled:
                    self.removePort()
                default:
                    break
                }
            }
        }

        newListener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor [weak self] in
                guard let self else { return }
                connection.start(queue: .main)
                self.receive(on: connection)
            }
        }

        newListener.start(queue: .main)
        self.listener = newListener
    }

    // MARK: - Private: HTTP Parsing

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let data, !data.isEmpty else {
                    if error != nil || isComplete {
                        self.cleanupBrokenConnection(connection)
                    } else {
                        self.receive(on: connection)
                    }
                    return
                }
                let key = ObjectIdentifier(connection)
                var buffer = self.connectionBuffers[key] ?? Data()
                buffer.append(data)
                self.connectionBuffers[key] = buffer
                self.processBuffer(for: connection)
            }
        }
    }

    /// Remove a broken/dropped connection from pending responses and buffers.
    private func cleanupBrokenConnection(_ connection: NWConnection) {
        let key = ObjectIdentifier(connection)
        connectionBuffers.removeValue(forKey: key)
        pendingDeferredConnections.removeAll { $0.connection === connection }
        connection.cancel()
    }

    private func processBuffer(for connection: NWConnection) {
        let key = ObjectIdentifier(connection)
        guard let buffer = connectionBuffers[key] else { return }

        guard let headerRange = findHeaderEnd(in: buffer) else {
            receive(on: connection)
            return
        }

        let headerData = buffer[..<headerRange.lowerBound]
        guard let headerStr = String(data: headerData, encoding: .utf8) else {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(400, body: Data(), on: connection)
            return
        }

        let requestLine = headerStr.components(separatedBy: "\r\n").first ?? ""
        guard requestLine.hasPrefix("POST") || requestLine.hasPrefix("GET") ||
              requestLine.hasPrefix("HEAD") || requestLine.hasPrefix("DELETE") ||
              requestLine.hasPrefix("PUT") || requestLine.hasPrefix("OPTIONS") else {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(400, body: Data(), on: connection)
            return
        }

        if !requestLine.hasPrefix("POST") {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(405, body: Data(), on: connection)
            return
        }

        if !requestLine.contains("/hook") {
            connectionBuffers.removeValue(forKey: key)
            sendResponse(404, body: Data(), on: connection)
            return
        }

        let bodyStart = headerRange.upperBound
        let contentLength = parseContentLength(from: headerStr) ?? 0

        guard buffer.count >= bodyStart + contentLength else {
            receive(on: connection)
            return
        }

        if !bearerToken.isEmpty {
            let authHeader = parseHeader("authorization", from: headerStr)
            let expectedPrefix = "Bearer "
            if !authHeader.hasPrefix(expectedPrefix) || String(authHeader.dropFirst(expectedPrefix.count)) != bearerToken {
                connectionBuffers.removeValue(forKey: key)
                sendResponse(401, body: Data(), on: connection)
                return
            }
        }

        let bodyData = buffer[bodyStart ..< bodyStart + contentLength]
        connectionBuffers.removeValue(forKey: key)
        handleBody(bodyData, connection: connection)
    }

    private func findHeaderEnd(in data: Data) -> Range<Data.Index>? {
        let terminator = Data([0x0D, 0x0A, 0x0D, 0x0A])
        return data.range(of: terminator)
    }

    private func parseContentLength(from headerStr: String) -> Int? {
        let value = parseHeader("content-length", from: headerStr)
        guard !value.isEmpty else { return nil }
        return Int(value)
    }

    /// Parse an HTTP header value by name (case-insensitive).
    private func parseHeader(_ name: String, from headerStr: String) -> String {
        let target = name.lowercased() + ":"
        for line in headerStr.components(separatedBy: "\r\n") {
            if line.lowercased().hasPrefix(target) {
                return String(line.dropFirst(target.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return ""
    }

    private func handleBody(_ bodyData: Data, connection: NWConnection) {
        guard !bodyData.isEmpty else {
            sendResponse(200, body: Data(), on: connection)
            return
        }

        guard let payload = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
            sendResponse(400, body: Data(), on: connection)
            return
        }

        guard let result = handler?(payload) else {
            sendResponse(200, body: Data(), on: connection)
            return
        }

        if let deferredID = deferredResponseID(from: result) {
            let provider = ProviderKind.from(payload: payload)
            pendingDeferredConnections.append(.init(id: deferredID, provider: provider, connection: connection))
            return
        }

        let cleanedResult = stripTransportMetadata(from: result)
        if let body = try? JSONSerialization.data(withJSONObject: cleanedResult) {
            sendResponse(200, body: body, on: connection)
        } else {
            sendResponse(200, body: Data(), on: connection)
        }
    }

    private func deferredResponseID(from result: [String: Any]) -> String? {
        let shouldHold = result[TransportMetadata.holdConnection] as? Bool ?? false
        guard shouldHold else { return nil }
        return result[TransportMetadata.deferredResponseID] as? String ?? ""
    }

    private func stripTransportMetadata(from result: [String: Any]) -> [String: Any] {
        var cleaned = result
        cleaned.removeValue(forKey: TransportMetadata.holdConnection)
        cleaned.removeValue(forKey: TransportMetadata.deferredResponseID)
        return cleaned
    }

    // MARK: - Private: HTTP Response

    private func sendResponse(_ statusCode: Int, body: Data, on connection: NWConnection) {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 401: statusText = "Unauthorized"
        case 404: statusText = "Not Found"
        case 405: statusText = "Method Not Allowed"
        default: statusText = "Error"
        }
        var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        response += "Content-Length: \(body.count)\r\n"
        response += "Connection: close\r\n"
        response += "\r\n"
        var responseData = Data(response.utf8)
        responseData.append(body)
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
