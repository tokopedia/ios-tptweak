// Copyright 2022-2024 Tokopedia. All rights reserved.
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

internal var __tweakViewController: TPTweakWithNavigatationViewController?
internal var __realViewController: UIViewController?
internal var __bubbleView: UIView?

public final class TPTweakWithNavigatationViewController: UINavigationController {
    internal var tweakViewController: TPTweakViewController = TPTweakViewController()
    
    public init() {
        if #available(iOS 13.0, *) {
            super.init(rootViewController: tweakViewController)
        } else {
            super.init(nibName: nil, bundle: nil)
            viewControllers = [tweakViewController]
        }

        if #available(iOS 12.0, *) {
            navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
        }
        
        navigationBar.isTranslucent = false
        navigationBar.sizeToFit()

        if #available(iOS 13.0, *) {
            navigationBar.tintColor = .systemBlue
            navigationBar.titleTextAttributes = [.foregroundColor: UIColor.label]
            navigationBar.barTintColor = .systemGroupedBackground
            navigationBar.backgroundColor = .systemGroupedBackground
        }
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        
        /// automatically add minimizable on every children if enable
        if let tptweakviewController = __tweakViewController,
            viewController != tptweakviewController.tweakViewController,
            tptweakviewController.tweakViewController.minimizable
        {
            if (viewController.navigationItem.rightBarButtonItems?.count ?? 0) > 0 {
                viewController.navigationItem.rightBarButtonItems?.append(tptweakviewController.tweakViewController.minimizeBarButtonItem)
            } else {
                viewController.navigationItem.rightBarButtonItems = [
                    tptweakviewController.tweakViewController.minimizeBarButtonItem
                ]
            }
            
            
        }
    }
}

/**
 Page will show all TPTweak Category
 */
public final class TPTweakViewController: UIViewController {
    // MARK: - Interfaces
    
    /// enable this true if you want to use `TPTweakViewController.presentMinimizableTweaks()`
    public var minimizable: Bool = false
    
    // MARK: - Values

    private var data: [Row] = []
    private var didSetUpHoldToPeepRecognizer = false

    // MARK: - Views

    private lazy var table: UITableView = {
        let view = UITableView(frame: .zero, style: {
            if #available(iOS 13.0, *) {
                return .insetGrouped
            } else {
                // Fallback on earlier versions
                return .plain
            }
        }())

        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        return view
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
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        
       return searchController
    }()
    
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
    
    /// expose to reuse on other VC
    internal lazy var minimizeBarButtonItem: UIBarButtonItem = {
        let button = {
            if #available(iOS 13.0, *) {
                return UIBarButtonItem(image: UIImage(systemName: "arrow.down.right.and.arrow.up.left"), style: .plain, target: self, action: #selector(minimize))
            } else {
                return UIBarButtonItem(title: "Minimize", style: .plain , target: self, action: #selector(minimize))
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
    
    private lazy var holdToPeepTapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(holdToPeep))
    
    // MARK: - Life Cycle

    public init() {
        super.init(nibName: nil, bundle: nil)

        title = "TPTweaks"
        view.backgroundColor = .white
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        
        data = fetchUserDefinedRows()
        searchResultViewController.setData(data: [])
        
        setupDefaultNavigationBarItems()
        
        table.reloadData()
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupDefaultNavigationBarItems()
        
        if !didSetUpHoldToPeepRecognizer {
            navigationController?.navigationBar.isUserInteractionEnabled = true
            navigationController?.navigationBar.addGestureRecognizer(holdToPeepTapRecognizer)
            didSetUpHoldToPeepRecognizer = true
        }
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Function

    private func setupView() {
        view.addSubview(table)

        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupDefaultNavigationBarItems() {
        navigationItem.leftBarButtonItems = [doneBarButtonItem]
        
        if minimizable {
            navigationItem.leftBarButtonItems?.append(minimizeBarButtonItem)
        }
        
        navigationItem.rightBarButtonItems = [settingBarButtonItem, favouriteBarButtonItem]
    }
    
    private func setupSearchNavigationBarItems() {
        navigationItem.leftBarButtonItems = [closeSearchBarButtonItem]
        navigationItem.rightBarButtonItems = []
    }

    private func fetchUserDefinedRows() -> [Row] {
        var normalizedEntries = [String: [TPTweakEntry]]()

        TPTweakStore.entries
            .forEach { entry in
                if normalizedEntries[entry.value.category] == nil {
                    normalizedEntries[entry.value.category] = []
                }

                normalizedEntries[entry.value.category]?.append(entry.value)
            }

        let rows = normalizedEntries
            .lazy
            .sorted(by: { $0.key < $1.key }) // sort ascending based on category name
            .map { key, value in
                Row(name: key, entries: value)
            }

        return rows
    }
    
    private func convertRowToSection(row: Row) -> [TPTweakPickerViewController.Section] {
        var normalizedEntries = [String: [TPTweakEntry]]()
        
        row.entries
            .sorted(by: { $0.cell < $1.cell })
            .forEach { entry in
                if normalizedEntries[entry.section] == nil {
                    normalizedEntries[entry.section] = []
                }

                normalizedEntries[entry.section]?.append(entry)
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
                        }()
                    ))

                    if let footer = entry.footer {
                        footers.append(footer)
                    }
                }

                return TPTweakPickerViewController.Section(name: key, footer: footers.last, cells: cells)
            }
        
        return data
    }
    
    @objc
    private func dismissSelf() {
        if minimizable {
            guard let tweakViewController = __tweakViewController else { return }
            let tweakView = tweakViewController.view!
            
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    let scale = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    tweakView.transform = scale
                    tweakView.alpha = 0.3
                    tweakView.layoutIfNeeded()
                },
                completion: { _ in
                    tweakView.alpha = 0
                    let window = UIApplication.shared.keyWindow
                    window?.rootViewController = __realViewController
                    
                    __realViewController = nil
                    __tweakViewController = nil
                }
            )
        } else {
            self.dismiss(animated: true)
        }
    }
    
    static func topMostController() -> UIViewController? {
        guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController else {
            return nil
        }

        var topController = rootViewController

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }

        return topController
    }
    
    @objc
    private func closeSearch() {
        searchController.isActive = false
    }
    
    @objc
    private func openSettings() {
        let entries: [TPTweakEntry] = [
            .peepOpacity,
            .clearCache
        ]
        
        let data = convertRowToSection(row: Row(name: "", entries: entries))
        let viewController = TPTweakPickerViewController(data: data)
        viewController.title = "Settings"
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc
    private func holdToPeep(_ sender: UILongPressGestureRecognizer) {
        // only avalable if not minimizable
        guard minimizable == false else { return }
        
        if (sender.state == .began) {
            let opacity = TPTweakEntry.peepOpacity.getValue(Double.self) ?? 0.25
            
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
                                                                      
    @objc
    private func openFavourite() {
        var favouriteEntries = [TPTweakEntry]()
        for row in data {
            favouriteEntries += row.entries.filter { TPTweakPickerViewController.isFavourite(identifier: $0.getIdentifier()) }
        }
        
        let data = convertRowToSection(row: Row(name: "", entries: favouriteEntries))
        let favouriteViewController = TPTweakPickerViewController(data: data)
        favouriteViewController.title = "Favourites"
        self.navigationController?.pushViewController(favouriteViewController, animated: true)
    }
    
    @objc
    private func minimize() {
        Self.minimize()
    }
}

extension TPTweakViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = data.count
        
        if count <= 0 {
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            emptyLabel.text = "No Data"
            emptyLabel.textAlignment = NSTextAlignment.center
            self.table.backgroundView = emptyLabel
        } else {
            self.table.backgroundView = nil
        }
        
        return count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = data[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = data[indexPath.row]
        let data = convertRowToSection(row: cell)

        let viewController = TPTweakPickerViewController(data: data)
        viewController.title = cell.name
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Tweaks"
    }
}

extension TPTweakViewController: UISearchControllerDelegate {
    public func presentSearchController(_ searchController: UISearchController) {
        setupSearchNavigationBarItems()
        
        var sections = [TPTweakPickerViewController.Section]()
        
        for row in data {
            sections.append(contentsOf: convertRowToSection(row: row))
        }
        
        searchResultViewController.setData(data: sections)
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        setupDefaultNavigationBarItems()
    }
}

extension TPTweakViewController {
    internal struct Row {
        internal let name: String
        internal let entries: [TPTweakEntry]
    }
}

// minimizable
extension TPTweakViewController {
    /// run this command to show TPTweakViewController that have minimizable capability
    public static func presentMinimizableTweaks() {
        let window = UIApplication.shared.keyWindow
        __realViewController = window?.rootViewController
        window?.rootViewController = nil
        
        let tweakViewController = TPTweakWithNavigatationViewController()
        tweakViewController.tweakViewController.minimizable = true
        __tweakViewController = tweakViewController
        window?.rootViewController = tweakViewController
        
        let tweakView = tweakViewController.view!
        tweakView.alpha = 0
        
        UIView.animate(
            withDuration: 0,
            animations: {
                let scale = CGAffineTransform(scaleX: 0.8, y: 0.8)
                tweakView.transform = scale
                tweakView.layoutIfNeeded()
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.3,
                    animations: {
                        tweakView.alpha = 1
                        tweakView.transform = CGAffineTransform.identity
                        tweakView.layoutIfNeeded()
                    }
                )
            }
        )
    }
    
    @objc
    internal static func minimize() {
        guard 
            let tweakViewController = __tweakViewController,
            let realViewController = __realViewController
        else { return }
        let tweakView = tweakViewController.view!
        
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
                let window = UIApplication.shared.keyWindow
                window?.rootViewController = realViewController
                
                setupBubble()
            }
        )
    }
    
    @objc
    private static func restoreTweaks() {
        guard let tweakViewController = __tweakViewController else { return }
        let tweakView = tweakViewController.view!
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                __bubbleView?.alpha = 0
                tweakView.transform = CGAffineTransform.identity
                tweakView.alpha = 1
            },
            completion: { _ in
                __bubbleView?.alpha = 0
                __bubbleView?.removeFromSuperview()
                __bubbleView = nil
                
                let window = UIApplication.shared.keyWindow
                window?.rootViewController = tweakViewController
            }
        )
    }
}

// bubble view
extension TPTweakViewController {
    private static func getBubblePosition() -> CGPoint {
        let x = UserDefaults.standard.object(forKey: "panel_frame_x") as? CGFloat ?? 0
        let y = UserDefaults.standard.object(forKey: "panel_frame_y") as? CGFloat ?? 500
        
        return CGPoint(x: x, y: y)
    }
    
    private static func getVisibleViewController() -> UIViewController? {
        var visibleViewController = UIApplication.shared.keyWindow?.rootViewController

        if visibleViewController?.presentedViewController != nil {
            visibleViewController = visibleViewController?.presentedViewController
        }

        // prevent double-presenting the tweaks view controller
        guard let visibleViewController = visibleViewController, (visibleViewController is TPTweakWithNavigatationViewController) == false else { return nil }
        return visibleViewController
    }
    
    private static func setupBubble() {
        guard let visibleViewController = getVisibleViewController() else { return }
        
        let subview: UIView
        if #available(iOS 13.0, *) {
            let image = UIImageView(frame: .init(x: 0, y: 0, width: 50, height: 50))
            image.contentMode = .center
            image.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18))
            image.tintColor = .white
            subview = image
        } else {
            let label = UILabel(frame: .init(x: 0, y: 0, width: 50, height: 50))
            label.text = "T"
            label.textAlignment = .center
            subview = label
        }

        let lastPosition = getBubblePosition()
        let bubble = UIView(frame: .init(x: lastPosition.x, y: lastPosition.y, width: 50, height: 50))
        if #available(iOS 13.0, *) {
            bubble.backgroundColor = .secondarySystemBackground
        } else {
            bubble.backgroundColor = .gray
        }
        bubble.alpha = 0.9
        bubble.layer.cornerRadius = 25
        bubble.addSubview(subview)
        
        __bubbleView = bubble

        let pan = UIPanGestureRecognizer(target: self, action: #selector(panEvent))
        bubble.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent))
        bubble.addGestureRecognizer(tap)

        // show
        visibleViewController.view.addSubview(bubble)
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
                UserDefaults.standard.setValue(view.frame.origin.x, forKey: "panel_frame_x")
                UserDefaults.standard.setValue(view.frame.origin.y, forKey: "panel_frame_y")
            } else {
                view.center = point
            }
        }
    }

    @objc
    private static func tapEvent(ges: UITapGestureRecognizer) {
        restoreTweaks()
    }
}
#endif
