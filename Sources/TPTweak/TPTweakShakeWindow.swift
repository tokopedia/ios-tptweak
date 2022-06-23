// Copyright: (c) 2022, Tokopedia
// GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

#if canImport(UIKit)
import UIKit

/**
 Replace app window, to use shake feature for TPTweak
 */
public class TPTweakShakeWindow: UIWindow {
    // MARK: - Interface

    public var shakeEnabled: Bool = true

    // MARK: - Values

    private var shaking = false
    private var active = false

    private var shouldPresentTweaks: Bool {
        #if DEBUG && TARGET_IPHONE_SIMULATOR
            return true
        #elseif DEBUG
            return shakeEnabled && shaking && active
        #else
            return false
        #endif
    }

    // MARK: - Life Cylce

    override public init(frame: CGRect) {
        super.init(frame: frame)

        active = true
        shakeEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActiveWithNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActiveWithNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        shaking = true

        guard shouldPresentTweaks == true else { return }
        presentTweaks()

        super.motionBegan(motion, with: event)
    }

    override public func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        shaking = false

        super.motionEnded(motion, with: event)
    }

    // MARK: - Function

    @objc
    private func applicationWillResignActiveWithNotification() {
        active = false
    }

    @objc
    private func applicationDidBecomeActiveWithNotification() {
        active = true
    }

    private func presentTweaks() {
        var visibleViewController = rootViewController

        if visibleViewController?.presentedViewController != nil {
            visibleViewController = visibleViewController?.presentedViewController
        }

        // prevent double-presenting the tweaks view controller
        guard (visibleViewController is TPTweakWithNavigatationViewController) == false else { return }

        let viewController = TPTweakWithNavigatationViewController()
        visibleViewController?.present(viewController, animated: true, completion: nil)
    }
}
#endif
