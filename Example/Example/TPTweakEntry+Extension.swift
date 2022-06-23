// Copyright: (c) 2022, Tokopedia
// GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

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
