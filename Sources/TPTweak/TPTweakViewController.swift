// Copyright 2022-2025 Tokopedia. All rights reserved.
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

#if canImport(UIKit)
import UIKit

public final class TPTweakWithNavigatationViewController: UINavigationController {
    
    // MARK: - Life Cycle
    
    public init(showDefaultDismissButton: Bool = true) {
        let tweakViewController = TPTweakViewController(showDefaultDismissButton: showDefaultDismissButton)
        
        if #available(iOS 13.0, *) {
            super.init(rootViewController: tweakViewController)
        } else {
            super.init(nibName: nil, bundle: nil)
            viewControllers = [tweakViewController]
        }
    
        if #available(iOS 12.0, *) {
            navigationBar.prefersLargeTitles = false
        }
        
        navigationBar.isTranslucent = false

        if #available(iOS 13.0, *) {
            navigationBar.tintColor = .systemBlue
            navigationBar.titleTextAttributes = [.foregroundColor: UIColor.label]
            navigationBar.barTintColor = .systemGroupedBackground
            navigationBar.backgroundColor = .systemGroupedBackground
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let title {
            viewControllers.first?.title = title
        }
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public final class TPTweakViewController: UIViewController {
    
    // MARK: - Values
    
    internal let showDefaultDismissButton: Bool
    
    private weak var viewController: UIViewController?
    private var currentLayout: TPTweakLayout
    private var currentIsMinimizable: Bool
    private var isBubbleSet: Bool = false
    
    private lazy var holdToPeepTapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(holdToPeep))
    
    // MARK: - Views
    
    internal lazy var doneBarButtonItem: UIBarButtonItem = {
        let button = {
            if #available(iOS 13.0, *) {
                return UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissSelf))
            } else {
                return UIBarButtonItem(title: "Close", style: .plain , target: self, action: #selector(dismissSelf))
            }
        }()
        button.tintColor = .gray
        
        return button
    }()

    private lazy var settingBarButtonItem: UIBarButtonItem = {
        let button = {
            if #available(iOS 13.0, *) {
                return UIBarButtonItem(image: UIImage(systemName: "gearshape.fill"), style: .plain, target: self, action: #selector(openSettings))
            } else {
                return UIBarButtonItem(title: "Settings", style: .plain , target: self, action: #selector(openSettings))
            }
        }()
        button.tintColor = .gray
        
        return button
    }()
    private lazy var favouriteBarButtonItem: UIBarButtonItem = {
        let button = {
            if #available(iOS 13.0, *) {
                return UIBarButtonItem(image: UIImage(systemName: "heart.fill"), style: .plain, target: self, action: #selector(openFavourite))
            } else {
                return UIBarButtonItem(title: "Favourite", style: .plain , target: self, action: #selector(openFavourite))
            }
        }()
        button.tintColor = .gray
        
        return button
    }()
    private lazy var closeSearchBarButtonItem: UIBarButtonItem = {
        let button = {
            if #available(iOS 13.0, *) {
                return UIBarButtonItem(image: UIImage(systemName: "arrow.backward"), style: .plain, target: self, action: #selector(closeSearch))
            } else {
                return UIBarButtonItem(title: "Cancel", style: .plain , target: self, action: #selector(closeSearch))
            }
        }()
        button.tintColor = .gray
        
        return button
    }()
    
    private lazy var searchResultViewController = TPTweakPickerViewController(data: [])
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchResultViewController)
        
        if #available(iOS 13.0, *) {
            searchController.showsSearchResultsController = true
        }
        
        searchController.searchResultsUpdater = searchResultViewController
        searchController.delegate = self
        searchController.searchBar.placeholder = " Search..."
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.isTranslucent = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        
       return searchController
    }()
    
    // MARK: - Life Cycle
    
    public init(showDefaultDismissButton: Bool = false) {
        self.currentLayout = Self.getLayout()
        self.currentIsMinimizable = Self.getIsMinimizableEnabled()
        self.showDefaultDismissButton = showDefaultDismissButton
        
        super.init(nibName: nil, bundle: nil)
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemGroupedBackground
        }
        
        title = "TPTweak"
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        // listen to minimize the view controller
        NotificationCenter.default.addObserver(
            forName: Self.minimizeNotificationCenterKey,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.minimize()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // update if design is changed from Settings page.
        setupViewController()
        
        // register navigation bar button
        setupNavigationBarButton()
        
        // setup bubble view
        setupBubbleIfNeccessary()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // make sure bubble and __tweakViewController not in limbo state
        if (isBeingDismissed || navigationController?.isBeingDismissed == true) {
            // if minimize, skip
            guard __tweakViewController == nil else { return }
            
            if isBubbleSet {
                Self.destroyBubble()
            }
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // sync size to child vc
        viewController?.view.frame = view.bounds
    }
    
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    private static func getLayout() -> TPTweakLayout {
        TPTweakLayout(rawValue: TPTweakEntry._internal_tptweak_layout.getValue(String.self) ?? TPTweakLayout.group.rawValue) ?? .group
    }
    
    private func setupViewController() {
        // layout value
        let layout = Self.getLayout()
        
        // user change the layout from the settings page.
        // remove current vc
        let userChangeLayout = viewController != nil && currentLayout != layout
        if let vc = viewController, userChangeLayout {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        
        // initial only
        guard viewController == nil || userChangeLayout else { return }
        
        let viewController: UIViewController
        switch layout {
        case .flatten:
            viewController = TPTweakPickerViewController(
                data: convertEntriesToPickerSection(entries: TPTweakStore.entries.map(\.value), flatten: true),
                isFavouritePage: false,
                showAlphabeticSection: true
            )
            self.viewController = viewController
        case .group:
            viewController = TPTweakGroupViewController()
            self.viewController = viewController
        }
        
        // add child
        self.addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        
        if userChangeLayout {
            // save changes, to detect it later
            currentLayout = layout
        }
    }
    
    private func setupNavigationBarButton() {
        if showDefaultDismissButton {
            navigationItem.leftBarButtonItems = [doneBarButtonItem]
        }
        
        navigationItem.rightBarButtonItems = [
            settingBarButtonItem,
            favouriteBarButtonItem
        ]
        
        // setup search
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = !(TPTweakEntry._internal_tptweak_always_show_search_bar.getValue(Bool.self) ?? false)
        
        // register gesture
        navigationController?.navigationBar.isUserInteractionEnabled = true
        navigationController?.navigationBar.addGestureRecognizer(holdToPeepTapRecognizer)
    }
    
    private func setupBubbleIfNeccessary() {
        func isModal() -> Bool {
            let presentingIsModal = presentingViewController != nil
            let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
            let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController
            
            return presentingIsModal || presentingIsNavigation || presentingIsTabBar
        }
        
        // minimize only works if TPTweakViewController is present and not pushed
        guard isModal() else {
            Self.destroyBubble()
            return
        }
        
        let isEnabled = Self.getIsMinimizableEnabled()
        let isMinimizableChanged = currentIsMinimizable != isEnabled
        
        if !isBubbleSet && isEnabled {
            Self.setupBubble()
            isBubbleSet = true
            currentIsMinimizable = isEnabled
        }
        
        if isMinimizableChanged {
            if isEnabled {
                Self.setupBubble()
                isBubbleSet = true
            } else {
                Self.destroyBubble()
                isBubbleSet = false
            }
            
            currentIsMinimizable = isEnabled
        }
    }
    
    // convert an array of TPTweakEntry to compatible data for TPTweakPickerViewController
    private func convertEntriesToPickerSection(
        entries: [TPTweakEntry],
        flatten: Bool,
        generateSearchMetadata: Bool = false
    ) -> [TPTweakPickerViewController.Section] {
        func _entryName(_ entry: TPTweakEntry) -> String {
            if flatten {
                var value = entry.category
                
                if !entry.section.isEmpty && entry.section != "" {
                    value += " - " + entry.section
                }
                
                return value
            } else {
                return entry.section
            }
        }
        
        var normalizedEntries = [String: [TPTweakEntry]]()
        
        entries
            .sorted(by: { _entryName($0) < _entryName($1) })
            .forEach { entry in
                let entryName = _entryName(entry)
                if normalizedEntries[entryName] == nil {
                    normalizedEntries[entryName] = []
                }

                normalizedEntries[entryName]?.append(entry)
            }

        let data: [TPTweakPickerViewController.Section] = normalizedEntries
            .sorted(by: { $0.key < $1.key })
            .map { key, value in
                var footers = [String]()
                var cells = [TPTweakPickerViewController.Cell]()

                for entry in value {
                    cells.append(TPTweakPickerViewController.Cell(
                        name: entry.cell,
                        identifer: entry.getIdentifier(),
                        type: entry.type,
                        leftIcon: entry.cellLeftIcon,
                        footer: entry.footer,
                        accessoryType: {
                            // custom accessory type only available for action type
                            if case let .action(accessoryType, _) = entry.type {
                                return accessoryType
                            } else {
                                return .disclosureIndicator
                            }
                        }(),
                        searchMetadata: entry.generateSearchMetadata()
                    ))

                    if let footer = entry.footer {
                        footers.append(footer)
                    }
                }

                return TPTweakPickerViewController.Section(name: key, footer: footers.last, cells: cells)
            }
        
        return data
    }
}

// MARK: - IBActions

extension TPTweakViewController {
    @objc private func dismissSelf() {
        self.dismiss(animated: true)
    }
    
    @objc private func openSettings() {
        let entries: [TPTweakEntry] = [
            ._internal_tptweak_layout,
            ._internal_tptweak_isMinimizable,
            ._internal_tptweak_always_show_search_bar,
            ._internal_tptweak_peepOpacity,
            .clearCache
        ]
        
        let data = convertEntriesToPickerSection(entries: entries, flatten: false)
        let viewController = TPTweakPickerViewController(data: data)
        viewController.title = "Settings"
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func openFavourite() {
        let favouriteEntries: [TPTweakEntry] = TPTweakStore.entries
            .lazy
            .filter { $0.value.isFavourite }
            .map(\.value)
        
        let data = convertEntriesToPickerSection(entries: favouriteEntries, flatten: false)
        let viewController = TPTweakPickerViewController(data: data, isFavouritePage: true)
        viewController.title = "Favourites"
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func closeSearch() {
        searchController.isActive = false
    }
    
    @objc private func holdToPeep(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            let opacity = TPTweakEntry._internal_tptweak_peepOpacity.getValue(Double.self) ?? 0.25

            navigationController?.navigationBar.alpha = opacity
            navigationController?.viewControllers.forEach({ vc in
                vc.view.alpha = opacity
            })
        } else if sender.state == .ended {
            navigationController?.navigationBar.alpha = 1
            navigationController?.viewControllers.forEach({ vc in
                vc.view.alpha = 1
            })
        }
    }
    
    private func minimize() {
        Self.minimizeTweaks(self.navigationController ?? self)
    }
}

// MARK: - minimizable

internal var __tweakViewController: UIViewController?
internal var __bubbleView: UIView?
internal var __setupNavigationSwizzle: Bool = false

extension TPTweakViewController {
    internal static var isMinimize: Bool {
        __tweakViewController != nil
    }
    
    private static func getIsMinimizableEnabled() -> Bool {
        TPTweakEntry._internal_tptweak_isMinimizable.getValue(Bool.self) ?? false
    }
    
    private static func swizzleNavigationIfNeccessary() {
        guard !__setupNavigationSwizzle else { return }
        __setupNavigationSwizzle = true
        
        func swizzle(fromClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
            guard let originalMethod = class_getInstanceMethod(fromClass, originalSelector),
                  let swizzledMethod = class_getInstanceMethod(fromClass, swizzledSelector) else {
                return
            }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        // set swizzle
        swizzle(fromClass: UINavigationController.self, originalSelector: #selector(UINavigationController.viewDidDisappear(_:)), swizzledSelector: #selector(UINavigationController.__viewDidDisappear(_:)))
    }
    
    private static func minimizeTweaks(_ reference: UIViewController) {
        __tweakViewController = reference
        
        let tweakView = reference.view!
        
        // animate minimize to bubble position
        UIView.animate(
            withDuration: 0.3,
            animations: {
                let bubblePosition = self.getBubblePosition()
                
                let scale = CGAffineTransform(scaleX: 0.1, y: 0.1)
                let move = CGAffineTransform(translationX: bubblePosition.x, y: bubblePosition.y)
                let hybrid = scale.concatenating(move)
                
                tweakView.transform = hybrid
                tweakView.alpha = 0.3
                tweakView.layoutIfNeeded()
            },
            completion: { _ in
                tweakView.alpha = 0
                reference.dismiss(animated: true)
            }
        )
    }
    
    @discardableResult
    private static func restoreTweaks() -> Bool {
        guard let tweakViewController = __tweakViewController else { return false }
        let tweakView = tweakViewController.view!
        
        tweakView.alpha = 0
        UIApplication.topViewController()?.present(tweakViewController, animated: true)
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                tweakView.transform = CGAffineTransform.identity
                tweakView.alpha = 1
            },
            completion: { _ in
                tweakView.layoutIfNeeded()
                __tweakViewController = nil
            }
        )
        
        return true
    }
    
    private static func getBubblePosition() -> CGPoint {
        let x = TPTweakStore.environment.provider().object(forKey: "panel_frame_x") as? CGFloat ?? 0
        let y = TPTweakStore.environment.provider().object(forKey: "panel_frame_y") as? CGFloat ?? 500
        
        return CGPoint(x: x, y: y)
    }
    
    private static func setBubblePosition(_ position: CGPoint) {
        TPTweakStore.environment.provider().setValue(position.x, forKey: "panel_frame_x")
        TPTweakStore.environment.provider().setValue(position.y, forKey: "panel_frame_y")
    }
    
    private static func setupBubble() {
        // if buble is created multiple time, make sure only the last one is valid
        if let previousBubble = __bubbleView {
            previousBubble.removeFromSuperview()
            __bubbleView = nil
        }
        
        // swizzle navigation for minimizable
        Self.swizzleNavigationIfNeccessary()
        
        let subview: UIView
        if #available(iOS 13.0, *) {
            let image = UIImageView(frame: .init(x: 0, y: 0, width: 50, height: 50))
            image.contentMode = .center
            image.image = UIImage(systemName: "arrow.down.right.and.arrow.up.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18))
            image.tintColor = .systemGray6
            subview = image
        } else {
            let label = UILabel(frame: .init(x: 0, y: 0, width: 50, height: 50))
            label.text = "T"
            label.textAlignment = .center
            subview = label
        }

        let lastPosition = getBubblePosition()
        let bubble = UIView(frame: .init(x: lastPosition.x, y: lastPosition.y, width: 50, height: 50))
        bubble.backgroundColor = .systemGray
        
        bubble.alpha = 0.9
        bubble.layer.cornerRadius = 25
        bubble.addSubview(subview)
        
        __bubbleView = bubble

        let pan = UIPanGestureRecognizer(target: self, action: #selector(panEvent))
        bubble.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent))
        bubble.addGestureRecognizer(tap)

        // show
        UIApplication.shared.keyWindow?.addSubview(bubble)
    }
    
    private static func destroyBubble() {
        UIView.animate(withDuration: 0.3) {
            __bubbleView?.alpha = 0
        } completion: { _ in
            __bubbleView?.removeFromSuperview()
            __bubbleView = nil
        }
    }
    
    internal static func destroyMinimizable() {
        __tweakViewController = nil
        destroyBubble()
    }
    
    @objc
    private static func panEvent(ges: UIPanGestureRecognizer) {
        if let view = ges.view {
            view.alpha = 0.3
            let point = ges.location(in: nil)
            let screenWidth = UIScreen.main.bounds.width
            if ges.state == .ended {
                view.alpha = 0.9
                view.center = .init(x:  point.x < screenWidth / 2 ? (25) : (screenWidth - 25), y: point.y)
                setBubblePosition(CGPoint(x: view.frame.origin.x, y: view.frame.origin.y))
            } else {
                view.center = point
            }
        }
    }
    
    private static let minimizeNotificationCenterKey = Notification.Name(rawValue: "com.TPTweak.minimizeNotificationCenterKey")

    @objc
    private static func tapEvent(ges: UITapGestureRecognizer) {
        let bubbleImageView = (__bubbleView?.subviews.first as? UIImageView)
        if isMinimize {
            // if restore is successfull
            if restoreTweaks() {
                // below iOS 13.0 will get blank page
                if #available(iOS 13.0, *) {
                    bubbleImageView?.image = UIImage(systemName: "arrow.down.right.and.arrow.up.left")
                }
                
                // reinit to make the bubble view on top of the UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let bubbleView = __bubbleView {
                        bubbleView.removeFromSuperview()
                        UIApplication.shared.keyWindow?.addSubview(bubbleView)
                    }
                }
            }
        } else {
            if #available(iOS 13.0, *) {
                bubbleImageView?.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
            }
            NotificationCenter.default.post(name: minimizeNotificationCenterKey, object: nil)
        }
    }
}

// MARK: - Search Delegate

extension TPTweakViewController: UISearchControllerDelegate {
    private func setupSearchNavigationBarItems() {
        navigationItem.leftBarButtonItems = [closeSearchBarButtonItem]
        navigationItem.rightBarButtonItems = []
    }
    
    public func presentSearchController(_ searchController: UISearchController) {
        setupSearchNavigationBarItems()
        
        // non blocking
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }
            let sections = self.convertEntriesToPickerSection(
                entries: TPTweakStore.entries.map(\.value),
                flatten: false
            )
            
            DispatchQueue.main.async {
                self.searchResultViewController.setData(data: sections)
            }
        }
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        setupNavigationBarButton()
    }
}
#endif
