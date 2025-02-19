//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

/// Primary interface for interacting with Compiler's Back End
public final actor CompilerClient {
    /// Application ID (retrievable from the Comiler Developer Dashboard)
    let appID: UUID

    internal let baseURL: String = "https://backend.compiler.inc"
    internal let keychain: KeychainHelper = KeychainHelper.standard
    internal let functionLogger: DebugLogger
    internal let modelLogger: DebugLogger
    internal let authLogger: DebugLogger
    
    /// Initialize the Compiler Client
    /// - Parameters:
    ///   - appID: Application ID (retrievable from the Comiler Developer Dashboard)
    ///   - enableDebugLogging: Whether or not to log debug info
    public init(appID: UUID, enableDebugLogging: Bool = false) {
        self.appID = appID
        self.functionLogger = DebugLogger(Logger.functionCalls, isEnabled: enableDebugLogging)
        self.modelLogger = DebugLogger(Logger.modelCalls, isEnabled: enableDebugLogging)
        self.authLogger = DebugLogger(Logger.auth, isEnabled: enableDebugLogging)
    }
}
