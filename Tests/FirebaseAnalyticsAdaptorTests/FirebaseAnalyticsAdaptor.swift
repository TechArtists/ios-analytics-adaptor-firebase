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

import XCTest
@testable import FirebaseAnalyticsAdaptor

final class FirebaseAnalyticsAdaptorTests: XCTestCase {
    func testTrimmedUserPropertyValueLeavesShortValuesUntouched() {
        let adaptor = FirebaseAnalyticsAdaptor(shouldStartFirebase: false)

        XCTAssertEqual(adaptor.trimmedUserPropertyValue("feature_tour"), "feature_tour")
        XCTAssertNil(adaptor.trimmedUserPropertyValue(nil))
    }

    func testTrimmedUserPropertyValueCapsFirebaseValuesAt36Characters() {
        let adaptor = FirebaseAnalyticsAdaptor(shouldStartFirebase: false)
        let longValue = String(repeating: "A", count: 40)

        XCTAssertEqual(
            adaptor.trimmedUserPropertyValue(longValue),
            String(longValue.prefix(firebaseUserPropertyValueMaxLength))
        )
        XCTAssertEqual(
            adaptor.trimmedUserPropertyValue(longValue)?.count,
            firebaseUserPropertyValueMaxLength
        )
    }

    /// The case that motivated the fix: a real campaign name overruns 36 characters, and Firebase
    /// drops the whole property rather than truncating, so GA4 loses attribution entirely.
    func testTrimmedUserPropertyValueKeepsALongCampaignNameUsable() {
        let adaptor = FirebaseAnalyticsAdaptor(shouldStartFirebase: false)
        let campaign = "asa_us_brand_exact_iphone_2026q3_launch"

        XCTAssertEqual(
            adaptor.trimmedUserPropertyValue(campaign),
            "asa_us_brand_exact_iphone_2026q3_lau"
        )
    }
}
