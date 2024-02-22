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

/**
 Detail page of TPTweak
 */
internal final class TPTweakPickerViewController: UIViewController {
    // MARK: - Values
    private var searchKeyword: String? = nil
    private var _data: [Section] = []
    private var data: [Section] {
        get {
            // if keyword does not exist, use full data
            guard let searchKeyword = searchKeyword, searchKeyword != "" else {
                return _data
            }
            
            // filter section based on if cell name contain keyword or not
            var filteredData = [Section]()
            
            for section in _data {
                let newCells = section.cells.filter { $0.name.lowercased().contains(searchKeyword) }
                
                // skip if this section's cell does not have any matching cell
                if newCells.isEmpty { continue }
                
                let newSection = Section(
                    name: section.name,
                    footer: newCells.last(where: { $0.footer != nil })?.footer, // use footer from last cell in newCells that contan any footer.
                    cells: newCells
                )
                filteredData.append(newSection)
            }
            
            return filteredData
        }
        
        set {
            _data = newValue
        }
    }
    private let isFavouritePage: Bool

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
        view.keyboardDismissMode = .onDrag
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        return view
    }()

    // MARK: - Life Cycle

    internal init(data: [Section], isFavouritePage: Bool = false) {
        self.isFavouritePage = isFavouritePage
        super.init(nibName: nil, bundle: nil)
        
        self.data = data
        title = "TPTweaks"
        view.backgroundColor = .white

        setupView()
    }

    override internal func viewDidLoad() {
        super.viewDidLoad()
        table.reloadData()
    }

    override internal func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 12.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationController?.navigationItem.largeTitleDisplayMode = .never
        }
    }

    internal required init?(coder _: NSCoder) {
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
    
    internal func setData(data: [Section]) {
        self.data = data
        self.table.reloadData()
    }
    
    private func openDetail(viewController: UIViewController) {
        if searchKeyword != nil, searchKeyword != "" {
            let navigationController = UINavigationController(rootViewController: viewController)
            self.present(navigationController, animated: true)
        } else {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func closeDetail(viewController: UIViewController) {
        if searchKeyword != nil, searchKeyword != "" {
            viewController.dismiss(animated: true)
        } else {
            navigationController?.popToViewController(self, animated: true)
        }
    }
    
    internal static func isFavourite(identifier: String) -> Bool {
        let favourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        return favourites.contains(where: { $0 == identifier })
    }
    
    private func setFavourite(identifier: String) {
        var favourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        favourites.insert(identifier)
        
        TPTweakEntry.favourite.setValue(favourites)
        table.reloadData()
    }
    
    private func removeFavourite(identifier: String) {
        var favourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        favourites.remove(identifier)
        
        TPTweakEntry.favourite.setValue(favourites)
        
        // update data
        for (offset, section) in zip(_data.indices, _data) {
            for (rowOffset, row) in zip(section.cells.indices, section.cells) where row.identifer == identifier {
                // create new cell without the removed favourite
                var newCells = section.cells
                newCells.removeAll(where: { $0.identifer == identifier })
                
                if newCells.isEmpty {
                    // if section does not have any cells, remove section
                    _data.removeAll(where: { $0.name == section.name })
                } else {
                    // update section with new cells
                    guard let index = _data.firstIndex(where: { $0.name == section.name && $0.footer == section.footer }) else { continue }
                    _data[index].cells = newCells
                }
            }
        }
        
        table.reloadData()
    }
    
    private func createFavouriteSwipeButton(identifier: String) -> UIContextualAction {
        if Self.isFavourite(identifier: identifier) {
            let action = UIContextualAction(style: .normal, title: "Remove Favourite") { [weak self] _, _, success in
                self?.removeFavourite(identifier: identifier)
                success(true)
            }
            
            if #available(iOS 13.0, *) {
                action.image = UIImage(systemName: "heart.slash")
            }
            
            action.backgroundColor = .systemRed
            
            return action
        } else {
            let action = UIContextualAction(style: .normal, title: "Favourite") { [weak self] _, _, success in
                self?.setFavourite(identifier: identifier)
                success(true)
            }
            
            if #available(iOS 13.0, *) {
                action.image = UIImage(systemName: "heart")
            }
            
            action.backgroundColor = .systemBlue
            
            return action
        }
    }
    
    @available(iOS 13.0, *)
    private func createContextualMenu(identifier: String) -> UIAction {
        if Self.isFavourite(identifier: identifier) {
            return UIAction(
                title: "Unfavourite",
                image: UIImage(systemName: "heart.slash"),
                identifier: nil,
                attributes: .destructive
            ) { [weak self] _ in
                self?.removeFavourite(identifier: identifier)
            }
        } else {
            return UIAction(
                title: "Favourite",
                image: UIImage(systemName: "heart"),
                identifier: nil
            ) { [weak self] _ in
                self?.setFavourite(identifier: identifier)
            }
        }
    }
}

extension TPTweakPickerViewController: UITableViewDataSource, UITableViewDelegate {
    internal func numberOfSections(in _: UITableView) -> Int {
        let count = data.count
        
        // handling empty state
        if count == 0 && isFavouritePage {
            let emptyLabel = UILabel(frame: .zero)
            emptyLabel.text = "You can Favorite a Tweaks by swipe or long press on the cell"
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            emptyLabel.font = .boldSystemFont(ofSize: 16)
            
            self.table.backgroundView = emptyLabel
        } else {
            self.table.backgroundView = nil
        }
        
        return count
    }

    internal func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        data[section].cells.count
    }

    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard var cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell(style: .value1, reuseIdentifier: "cell")
        }

        let cellData = data[indexPath.section].cells[indexPath.row]
        cell.imageView?.image = cellData.leftIcon
        
        switch cellData.type {
        case .action:
            cell.textLabel?.text = cellData.name
            cell.detailTextLabel?.text = nil
            // custom accessoryType only available for action type
            cell.accessoryType = cellData.accessoryType
        case .switch:
            let switcher = UISwitch()
            switcher.isOn = TPTweakStore.read(type: Bool.self, identifier: cellData.identifer) ?? false
            switcher.isUserInteractionEnabled = false

            cell.textLabel?.text = cellData.name
            cell.detailTextLabel?.text = nil
            cell.accessoryView = switcher
        case let .strings(_, defaultValue, _):
            let currentValue = TPTweakStore.read(type: String.self, identifier: cellData.identifer) ?? defaultValue

            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell.detailTextLabel?.text = currentValue
            cell.textLabel?.text = cellData.name
            cell.accessoryType = .disclosureIndicator
        case let .numbers(_, defaultValue, _):
            let currentValue = TPTweakStore.read(type: Double.self, identifier: cellData.identifer) ?? defaultValue

            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell.detailTextLabel?.text = String(currentValue)
            cell.textLabel?.text = cellData.name
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    internal func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        data[section].name.uppercased()
    }

    internal func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        if #available(iOS 13.0, *) {
            return data[section].footer
        } else {
            return nil
        }
    }

    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cellData = data[indexPath.section].cells[indexPath.row]
        switch cellData.type {
        case let .action(_, completion):
            completion()
        case let .switch(_, completion):
            var value = TPTweakStore.read(type: Bool.self, identifier: cellData.identifer) ?? false
            value.toggle()

            TPTweakStore.set(value, identifier: cellData.identifer)
            tableView.reloadRows(at: [indexPath], with: .none) // to update cell value after action
            completion?(value)
        case let .numbers(item, defaultValue, completion):
            let viewController = TPTweakOptionsViewController(
                title: cellData.name,
                data: item.map { TPTweakOptionsViewController<Double>.Cell(name: String($0), value: $0) },
                defaultSelected: TPTweakStore.read(type: Double.self, identifier: cellData.identifer) ?? defaultValue
            )

            viewController.didChoose = { [weak tableView, weak self] newValue in
                TPTweakStore.set(newValue, identifier: cellData.identifer)
                tableView?.reloadRows(at: [indexPath], with: .automatic) // to update cell value after action
                completion?(newValue)

                if let self = self {
                    self.closeDetail(viewController: viewController) // back to picker
                }
            }

            openDetail(viewController: viewController)
        case let .strings(item, defaultValue, completion):
            let viewController = TPTweakOptionsViewController(
                title: cellData.name,
                data: item.map { TPTweakOptionsViewController<String>.Cell(name: $0, value: $0) },
                defaultSelected: TPTweakStore.read(type: String.self, identifier: cellData.identifer) ?? defaultValue
            )

            viewController.didChoose = { [weak tableView, weak self] newValue in
                TPTweakStore.set(newValue, identifier: cellData.identifer)
                tableView?.reloadRows(at: [indexPath], with: .automatic) // to update cell value after action
                completion?(newValue)
                
                if let self = self {
                    self.closeDetail(viewController: viewController) // back to picker
                }
            }

            openDetail(viewController: viewController)
        }
    }
    
    internal func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cellData = data[indexPath.section].cells[indexPath.row]
        let action = createFavouriteSwipeButton(identifier: cellData.identifer)
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    internal func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cellData = data[indexPath.section].cells[indexPath.row]
        let action = createFavouriteSwipeButton(identifier: cellData.identifer)
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let cellData = data[indexPath.section].cells[indexPath.row]
        
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: { _ in
                return UIMenu(title: "", children: [self.createContextualMenu(identifier: cellData.identifer)])
            }
        )
    }
}

extension TPTweakPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchKeyword = searchController.searchBar.text?.lowercased()
        table.reloadData()
    }
}


extension TPTweakPickerViewController {
    internal struct Section {
        internal let name: String
        internal let footer: String?
        internal var cells: [Cell]
    }

    internal struct Cell {
        internal let name: String
        internal let identifer: String
        internal let type: TPTweakEntryType
        internal let leftIcon: UIImage?
        internal let footer: String?
        internal let accessoryType: UITableViewCell.AccessoryType
    }
}
#endif
