// Copyright: (c) 2022, Tokopedia
// GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

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
