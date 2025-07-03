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

//  FirebaseAnalyticsAdaptor.swift
//  Created by Adi on 10/24/22.
//
//  Copyright (c) 2022 Tech Artists Agency SRL
//

import Foundation
import OSLog

import TAAnalytics
import FirebaseCore
import FirebaseAnalytics

public protocol FirebaseParameterValue {}

extension String: FirebaseParameterValue {}
extension NSNumber: FirebaseParameterValue {}

/// Logs events & user properties via FirebaseAnalytics
public class FirebaseAnalyticsAdaptor: AnalyticsAdaptor, AnalyticsAdaptorWithReadOnlyUserPseudoID {

    public typealias T = FirebaseAnalytics.Analytics.Type
    
    private var userDefaults: UserDefaults?
    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private var currentInstallType: TAAnalyticsConfig.InstallType?
    
    /// - Parameter enabledInstallTypes: By default, Firebase is only enabled for app store builds
    public init(enabledInstallTypes: [TAAnalyticsConfig.InstallType] = TAAnalyticsConfig.InstallType.allCases) {
        self.enabledInstallTypes = enabledInstallTypes
    }
    
    // MARK: AnalyticsAdaptor
    
    public func startFor(installType: TAAnalyticsConfig.InstallType, userDefaults: UserDefaults, taAnalytics: TAAnalytics) async throws {
        guard self.enabledInstallTypes.contains(installType) else {
            throw InstallTypeError.invalidInstallType
        }
        
        self.userDefaults = userDefaults
        self.currentInstallType = installType
        
        FirebaseCore.FirebaseApp.configure()
    }

    public func track(trimmedEvent: EventAnalyticsModelTrimmed, params: [String : any AnalyticsBaseParameterValue]?) {
        // TODO: Change to debugger
        
        if self.currentInstallType == .Xcode {
            fatalErrorIfReservedEvent(trimmedEvent.rawValue)
        }

        let validParams = validEventParams(forEvent: trimmedEvent, params: params)
        FirebaseAnalytics.Analytics.logEvent(trimmedEvent.rawValue, parameters: validParams)
    }
    
    public func trim(event: EventAnalyticsModel) -> EventAnalyticsModelTrimmed {
        EventAnalyticsModelTrimmed(event.rawValue.ta_trim(toLength: 40, debugType: "event"))
    }
    
    public func trim(userProperty: UserPropertyAnalyticsModel) -> UserPropertyAnalyticsModelTrimmed {
        UserPropertyAnalyticsModelTrimmed(userProperty.rawValue.ta_trim(toLength: 24, debugType: "user property"))
    }
    
    public func set(trimmedUserProperty: UserPropertyAnalyticsModelTrimmed, to: String?) {
        // TODO: Change to debugger
        if self.currentInstallType == .Xcode {
            fatalErrorIfReservedUserProperty(trimmedUserProperty.rawValue)
        }
        FirebaseAnalytics.Analytics.setUserProperty(to, forName: trimmedUserProperty.rawValue)
    }
    
    public func set(userID: String?) {
        userDefaults?.set(userID, forKey: userDefaultsKeyFor(key: "userID"))
        FirebaseAnalytics.Analytics.setUserID(userID)
    }
    
    public func getUserID() -> String? {
        userDefaults?.object(forKey: userDefaultsKeyFor(key: "userID")) as? String
    }
    
    private func fatalErrorIfReservedEvent(_ eventRawValue: String) {
        if reservedFirebaseEvents.contains(eventRawValue) {
            // only check the event name during debug, to save on (a tiny bit) performance
            fatalError("using a reserved firebase event name '\(eventRawValue)'")
        }
    }
    
    private func validEventParams(forEvent trimmedEvent: EventAnalyticsModelTrimmed, params: [String: any AnalyticsBaseParameterValue]?) -> [String: Any]? {
        guard let params = params else { return nil }
        
        var newParams = [String: Any]()
        
        for (key, value) in params {
            if key.count > 40 || ((value as? String)?.count ?? 0) > 100 {
                let newKey = String(key.prefix(40))
                var newValue = value
                var newValueString = ""
                if let value = value as? String {
                    newValue = String(value.prefix(100))
                    newValueString = String(value.prefix(100))
                }
                
                newParams[newKey] = convert(parameter: newValue)
                
                TAAnalyticsLogger.log("Will trim parameters for event \(trimmedEvent.rawValue), key \(newKey), value \(newValueString)", level: .error)
            } else {
                newParams[key] = value
            }
        }
        return newParams
    }
    
    private func convert(parameter: any AnalyticsBaseParameterValue) -> Any {
        if let string = parameter as? String {
            return string
        }
        if let int = parameter as? Int {
            return NSNumber(integerLiteral: int)
        }
        if let float = parameter as? Float {
            return NSNumber(floatLiteral: Double(float))
        }
        if let double = parameter as? Double {
            return NSNumber(floatLiteral: double)
        }
        if let bool = parameter as? Bool {
            return NSNumber(booleanLiteral: bool)
        }
        fatalError("Unsupported base parameter type \(parameter)")
    }
    
    private func fatalErrorIfReservedUserProperty(_ userPropertyRawValue: String) {
        if reservedFirebaseUserProperties.contains(userPropertyRawValue) {
            // only check the event name during debug, to save on (a tiny bit) performance
            fatalError("using a reserved firebase user property '\(userPropertyRawValue)'")
        }
    }
    
    public var wrappedValue: FirebaseAnalytics.Analytics.Type {
        FirebaseAnalytics.Analytics.self
    }
    
    // MARK: AnalyticsAdaptorWithReadOnlyUserPseudoID
    
    public func getUserPseudoID() -> String? {
        FirebaseAnalytics.Analytics.appInstanceID()
    }
    
    // MARK: AnalyticsAdaptorWithReadWriteUserID

    private func userDefaultsKeyFor(key: String) -> String {
        return "\(TAAnalytics.userdefaultsKeyPrefix)_firebase_\(key)"
    }

    // MARK: - Reserved Names
    
    internal let reservedFirebaseUserProperties = ["first_open_time", "last_deep_link_referrer", "user_id"]
    
    internal let reservedFirebaseEvents = [
        "ad_activeview",
        "ad_click",
        "ad_exposure",
        "ad_query",
        "ad_reward",
        "adunit_exposure",
        "app_background",
        "app_clear_data",
        "app_exception",
        "app_remove",
        "app_store_refund",
        "app_store_subscription_cancel",
        "app_store_subscription_convert",
        "app_store_subscription_renew",
        "app_update",
        "app_upgrade",
        "dynamic_link_app_open",
        "dynamic_link_app_update",
        "dynamic_link_first_open",
        "error",
        "firebase_campaign",
        "first_open",
        "first_visit",
        "in_app_purchase",
        "notification_dismiss",
        "notification_foreground",
        "notification_open",
        "notification_receive",
        "os_update",
        "session_start",
        "session_start_with_rollout",
        "user_engagement",
    ]
}
