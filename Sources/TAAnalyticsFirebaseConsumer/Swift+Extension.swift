//
//  Swift+Extension.swift
//  TAAnalyticsFirebaseConsumer
//
//  Created by Robert Tataru on 16.01.2025.
//
import Foundation
import OSLog


internal let LOGGER = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "TAAnalyticsFirebaseConsumer")

extension String {

    /// Same as `String(describing:)` but without the `Optional()` part printing
    /// It will be `"nil"` when nil.
    init(describingOptional optional: Any?) {
        switch optional {
        case .none:
            self.init("nil")
        case let .some(value):
            self.init(describing: value)
        }
    }
    
    /// - Parameters:
    ///   - length: the length it needs to be trimmed to
    ///   - debugType: what to write in the error log if it's being trimmed
    internal func ta_trim(toLength length: Int, debugType: String) -> String {
        if self.count > length {
            let trimmedString = String(self.prefix(length))
            os_log("Trimming %{public}@ to length %ld ('%{public}@' -> '%{public}@'",
                   log: LOGGER,
                   type: .error,
                   debugType, length, self, trimmedString)
            return trimmedString
        }
        return self
    }
    
}
