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

/**
 Page will show all TPTweak Category in group
 */
public final class TPTweakGroupViewController: UIViewController {
    
    // MARK: - Values

    private var data: [Row] = []

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
    
    // MARK: - Life Cycle

    public init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .white
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        
        data = fetchUserDefinedRows()

        table.reloadData()
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
}

extension TPTweakGroupViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
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

        let viewController = TPTweakPickerViewController(data: data, isFavouritePage: false)
        viewController.title = cell.name
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Tweaks"
    }
}

extension TPTweakGroupViewController {
    internal struct Row {
        internal let name: String
        internal let entries: [TPTweakEntry]
    }
}
#endif
