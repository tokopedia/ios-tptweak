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
 Selection picker for Array of String or number type
 */
internal final class TPTweakOptionsViewController<ValueType>: UIViewController, UITableViewDataSource, UITableViewDelegate where ValueType: Equatable {
    // MARK: - Interfaces

    internal var didChoose: ((ValueType) -> Void)?

    // MARK: - Values

    private let data: [Cell<ValueType>]
    private var selectedData: ValueType

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

    internal init(title: String, data: [Cell<ValueType>], defaultSelected: ValueType) {
        self.data = data
        selectedData = defaultSelected
        super.init(nibName: nil, bundle: nil)

        self.title = title

        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        }

        setupView()
    }

    override internal func viewDidLoad() {
        super.viewDidLoad()
        table.reloadData()
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

    internal func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        data.count
    }

    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell()
        }

        let cellData = data[indexPath.row]
        cell.textLabel?.text = cellData.name

        if cellData.value == selectedData {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        selectedData = data[indexPath.row].value
        didChoose?(selectedData)
    }
}

extension TPTweakOptionsViewController {
    internal struct Cell<ValueType> {
        internal let name: String
        internal let value: ValueType
    }
}
#endif
