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

@UIApplicationMain
internal final class AppDelegate: UIResponder, UIApplicationDelegate {
    internal var window: UIWindow?

    internal func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // register TPTweakShakeWindow to enable openning TPTweak from shaking the device
        window = TPTweakShakeWindow(frame: UIScreen.main.bounds)
        
        // register TPTweak Entry
        TPTweakEntry.enableTracking.register()
        TPTweakEntry.trackingTimeout.register()
        TPTweakEntry.trackingHistory.register()
        TPTweakEntry.trackingServerLocation.register()
        TPTweakEntry.trackingUsingLocale.register()
        TPTweakEntry.changeLanguage.register()

        let viewController = ViewController()
        let nav = UINavigationController(rootViewController: viewController)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.backgroundColor = .red

        window?.rootViewController = nav
        window?.makeKeyAndVisible()

        return true
    }
}
