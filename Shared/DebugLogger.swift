import Foundation
import os.log

final class DebugLogger {
    static let shared = DebugLogger()
    
    private let osLog = OSLog(subsystem: AppConstants.mainAppBundleID, category: "ShioriShare")
    private let fileManager = FileManager.default
    private let fileQueue = DispatchQueue(label: "DebugLogger.file")
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    private let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var logsDirectory: URL? {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) else {
            return nil
        }
        return containerURL.appendingPathComponent("logs", isDirectory: true)
    }
    
    private var currentLogFile: URL? {
        guard let logsDir = logsDirectory else { return nil }
        let fileName = "shiori-\(fileDateFormatter.string(from: Date())).log"
        return logsDir.appendingPathComponent(fileName)
    }
    
    private init() {
        createLogsDirectoryIfNeeded()
        cleanupOldLogs()
    }
    
    // MARK: - Logging
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    func error(_ error: Error, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let message = context != nil ? "\(context!): \(error.localizedDescription)" : error.localizedDescription
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    func apiRequest(method: String, url: String, headers: [String: String]? = nil) {
        guard SettingsManager.shared.debugLoggingEnabled else { return }
        
        var sanitizedHeaders = headers ?? [:]
        sanitizedHeaders.removeValue(forKey: "Authorization")
        sanitizedHeaders.removeValue(forKey: "Cookie")
        sanitizedHeaders.removeValue(forKey: "X-Session-Id")
        
        let headersStr = sanitizedHeaders.isEmpty ? "" : " headers=\(sanitizedHeaders)"
        info("\(method) \(url)\(headersStr)")
    }
    
    func apiResponse(method: String, url: String, statusCode: Int, duration: TimeInterval) {
        guard SettingsManager.shared.debugLoggingEnabled else { return }
        let durationMs = Int(duration * 1000)
        info("\(method) \(url) -> \(statusCode) (\(durationMs)ms)")
    }
    
    // MARK: - Log File Management
    
    func exportLogs() -> URL? {
        guard let logsDir = logsDirectory else { return nil }
        
        let exportURL = logsDir.appendingPathComponent("shiori-debug-export.txt")
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDir, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "log" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 < date2
                }
            
            var combinedLogs = "Shiori Share Debug Log Export\n"
            combinedLogs += "Generated: \(dateFormatter.string(from: Date()))\n"
            combinedLogs += String(repeating: "=", count: 50) + "\n\n"
            
            for logFile in logFiles {
                if let content = try? String(contentsOf: logFile, encoding: .utf8) {
                    combinedLogs += "--- \(logFile.lastPathComponent) ---\n"
                    combinedLogs += content
                    combinedLogs += "\n\n"
                }
            }
            
            try combinedLogs.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            os_log("Failed to export logs: %{public}@", log: osLog, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    func clearLogs() {
        guard let logsDir = logsDirectory else { return }
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDir, includingPropertiesForKeys: nil)
            for file in logFiles {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            os_log("Failed to clear logs: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Private
    
    private enum LogLevel: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        
        var osLogType: OSLogType {
            switch self {
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
    }
    
    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        os_log("%{public}@", log: osLog, type: level.osLogType, message)
        
        guard SettingsManager.shared.debugLoggingEnabled else { return }
        
        let now = Date()
        let fileName = (file as NSString).lastPathComponent
        
        fileQueue.async { [self] in
            let timestamp = dateFormatter.string(from: now)
            let logLine = "[\(timestamp)] \(level.rawValue): \(message) (\(fileName):\(line))\n"
            appendToLogFile(logLine)
        }
    }
    
    private func appendToLogFile(_ content: String) {
        guard let logFile = currentLogFile else { return }
        
        do {
            if fileManager.fileExists(atPath: logFile.path) {
                let handle = try FileHandle(forWritingTo: logFile)
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = content.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            } else {
                try content.write(to: logFile, atomically: true, encoding: .utf8)
            }
        } catch {
            os_log("Failed to write to log file: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }
    
    private func createLogsDirectoryIfNeeded() {
        guard let logsDir = logsDirectory else { return }
        
        if !fileManager.fileExists(atPath: logsDir.path) {
            try? fileManager.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
    }
    
    private func cleanupOldLogs() {
        guard let logsDir = logsDirectory else { return }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -AppConstants.Timing.debugLogRetentionDays, to: Date()) ?? Date()
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDir, includingPropertiesForKeys: [.creationDateKey])
            
            for file in logFiles where file.pathExtension == "log" {
                if let creationDate = (try? file.resourceValues(forKeys: [.creationDateKey]).creationDate),
                   creationDate < cutoffDate {
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            os_log("Failed to cleanup old logs: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }
}
