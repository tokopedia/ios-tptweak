// Copyright 2022 Tokopedia. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import TPTweak
import UIKit

extension TPTweakEntry {
    static let enableTracking = TPTweakEntry(
        category: "Tracking",
        section: "Tracking",
        cell: "Enable Tracking",
        footer: "Turn this on to enable tracking",
        type: .switch(defaultValue: true)
    )
    
    static let trackingTimeout = TPTweakEntry(
        category: "Tracking",
        section: "Timeout",
        cell: "Max Timeout",
        footer: "Passing this value will timeout tracking request",
        type: .numbers(item: [10, 15, 20], selected: 10)
    )
    
    static let trackingHistory = TPTweakEntry(
        category: "Tracking",
        section: "Tracking",
        cell: "History",
        footer: nil,
        type: .action({
            guard let topViewController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? TPTweakWithNavigatationViewController else {
                fatalError("no view controller")
            }
            
            topViewController.pushViewController(TrackingHistoryViewController(), animated: true)
        })
    )
    
    static let trackingServerLocation = TPTweakEntry(
        category: "Tracking",
        section: "Server",
        cell: "Location",
        footer: "Server to send tracking adta",
        type: .strings(item: ["US", "UK", "SG"], selected: "SG")
    )
    
    static let changeLanguage = TPTweakEntry(
        category: "Apperance",
        section: "Language",
        cell: "Language",
        footer: "Change app's language",
        type: .strings(item: ["English", "Spanish", "Indonesia"], selected: "English")
    )
}
