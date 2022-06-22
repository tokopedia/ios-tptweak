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

#if canImport(UIKit)
import UIKit

/**
 Detail page of TPTweak
 */
internal final class TPTweakPickerViewController: UIViewController {
    // MARK: - Values

    private var data: [Section] = []

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

    internal init(data: [Section]) {
        self.data = data
        super.init(nibName: nil, bundle: nil)

        title = "Tokopedia Tweaks"
        view.backgroundColor = .white

        setupView()
    }

    override internal func viewDidLoad() {
        super.viewDidLoad()
        table.reloadData()
    }

    override internal func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationItem.largeTitleDisplayMode = .never
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
}

extension TPTweakPickerViewController: UITableViewDataSource, UITableViewDelegate {
    internal func numberOfSections(in _: UITableView) -> Int {
        data.count
    }

    internal func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        data[section].cells.count
    }

    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard var cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell(style: .value1, reuseIdentifier: "cell")
        }

        let cellData = data[indexPath.section].cells[indexPath.row]

        switch cellData.type {
        case .action:
            cell.textLabel?.text = cellData.name
            cell.accessoryType = .disclosureIndicator
        case .switch:
            let switcher = UISwitch()
            switcher.isOn = TPTweakStore.read(type: Bool.self, identifier: cellData.identifer) ?? false
            switcher.isUserInteractionEnabled = false

            cell.textLabel?.text = cellData.name
            cell.accessoryView = switcher
        case let .strings(_, defaultValue):
            let currentValue = TPTweakStore.read(type: String.self, identifier: cellData.identifer) ?? defaultValue

            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell.detailTextLabel?.text = currentValue
            cell.textLabel?.text = cellData.name
            cell.accessoryType = .disclosureIndicator
        case let .numbers(_, defaultValue):
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
        case let .action(closure):
            closure()
        case .switch:
            var value = TPTweakStore.read(type: Bool.self, identifier: cellData.identifer) ?? false
            value.toggle()

            TPTweakStore.set(value, identifier: cellData.identifer)
            tableView.reloadRows(at: [indexPath], with: .automatic) // to update cell value after action
        case let .numbers(item, defaultValue):
            let viewController = TPTweakOptionsViewController(
                title: cellData.name,
                data: item.map { TPTweakOptionsViewController<Double>.Cell(name: String($0), value: $0) },
                defaultSelected: TPTweakStore.read(type: Double.self, identifier: cellData.identifer) ?? defaultValue
            )

            viewController.didChoose = { [weak tableView, weak navigationController, weak self] newValue in
                TPTweakStore.set(newValue, identifier: cellData.identifer)
                tableView?.reloadRows(at: [indexPath], with: .automatic) // to update cell value after action

                if let self = self {
                    navigationController?.popToViewController(self, animated: true) // back to picker
                }
            }

            navigationController?.pushViewController(viewController, animated: true)
        case let .strings(item, defaultValue):
            let viewController = TPTweakOptionsViewController(
                title: cellData.name,
                data: item.map { TPTweakOptionsViewController<String>.Cell(name: $0, value: $0) },
                defaultSelected: TPTweakStore.read(type: String.self, identifier: cellData.identifer) ?? defaultValue
            )

            viewController.didChoose = { [weak tableView, weak navigationController, weak self] newValue in
                TPTweakStore.set(newValue, identifier: cellData.identifer)
                tableView?.reloadRows(at: [indexPath], with: .automatic) // to update cell value after action

                if let self = self {
                    navigationController?.popToViewController(self, animated: true) // back to picker
                }
            }

            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension TPTweakPickerViewController {
    internal struct Section {
        internal let name: String
        internal let footer: String?
        internal let cells: [Cell]
    }

    internal struct Cell {
        internal let name: String
        internal let identifer: String
        internal let type: TPTweakEntryType
    }
}
#endif
