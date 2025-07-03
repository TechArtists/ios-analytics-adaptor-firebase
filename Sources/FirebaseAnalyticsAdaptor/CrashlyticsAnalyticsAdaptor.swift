/*
MIT License

Copyright (c) 2025 Tech Artists Agency

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

//  CrashlyticsAnalyticsAdaptor.swift
//  Created by Adi on 10/24/22.
//
//  Copyright (c) 2022 Tech Artists Agency SRL
//

import Foundation
import TAAnalytics
import FirebaseCrashlytics
import FirebaseCore

/// Sends messages to Crashlytics about analytics event & user properties.
public class CrashlyticsAnalyticsAdaptor: AnalyticsAdaptor, AnalyticsAdaptorWithWriteOnlyUserID  {
    
    public typealias T = Crashlytics
    
    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private let isRedacted: Bool
    
    // MARK: AnalyticsAdaptor
    
    /// - Parameters:
    ///   - isRedacted: if parameter & user property values should be redacted
    public init( enabledInstallTypes: [TAAnalyticsConfig.InstallType] = TAAnalyticsConfig.InstallType.allCases, isRedacted: Bool = true) {
        self.isRedacted = isRedacted
        self.enabledInstallTypes = enabledInstallTypes
    }
    
    public func startFor(installType: TAAnalyticsConfig.InstallType, userDefaults: UserDefaults, taAnalytics: TAAnalytics) async throws {
        if !self.enabledInstallTypes.contains(installType) {
            throw InstallTypeError.invalidInstallType
        }
        
        FirebaseCore.FirebaseApp.configure()
    }
    
    public func track(trimmedEvent: EventAnalyticsModelTrimmed, params: [String : any AnalyticsBaseParameterValue]?) {
        let debugString = OSLogAnalyticsAdaptor().debugStringForLog(eventRawValue: trimmedEvent.rawValue, params: params, privacyRedacted: isRedacted)
        Crashlytics.crashlytics().log(debugString)
    }
    
    public func set(trimmedUserProperty: UserPropertyAnalyticsModelTrimmed, to: String?) {
        let debugString = OSLogAnalyticsAdaptor().debugStringForSet(userPropertyRawValue: trimmedUserProperty.rawValue, to: to, privacyRedacted: isRedacted)
        Crashlytics.crashlytics().log(debugString)
        Crashlytics.crashlytics().setValue(to, forKey: trimmedUserProperty.rawValue)
    }
    
    public func trim(event: EventAnalyticsModel) -> EventAnalyticsModelTrimmed {
        EventAnalyticsModelTrimmed(event.rawValue.ta_trim(toLength: 40, debugType: "event"))
    }
    
    public func trim(userProperty: UserPropertyAnalyticsModel) -> UserPropertyAnalyticsModelTrimmed {
        UserPropertyAnalyticsModelTrimmed(userProperty.rawValue.ta_trim(toLength: 24, debugType: "user property"))
    }
    
    public var wrappedValue: T {
        Crashlytics.crashlytics()
    }
    
    // MARK: AnalyticsAdaptorWithWriteOnlyUserID
    
    public func set(userID: String?) {
        Crashlytics.crashlytics().setUserID(userID)
    }
}
