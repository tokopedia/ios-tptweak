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

public final class TPTweakWithNavigatationViewController: UINavigationController {
    public init() {
        if #available(iOS 13.0, *) {
            super.init(rootViewController: TPTweakViewController())
        } else {
            super.init(nibName: nil, bundle: nil)
            viewControllers = [TPTweakViewController()]
        }

        navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
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
}

/**
 Page will show all TPTweak Category
 */
public final class TPTweakViewController: UIViewController {
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

    private lazy var doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
    private lazy var resetBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetAll))

    // MARK: - Life Cycle

    public init() {
        super.init(nibName: nil, bundle: nil)

        title = "Tokopedia Tweaks"
        view.backgroundColor = .white

        setupView()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        fetchData()
        table.reloadData()

        navigationItem.leftBarButtonItem = doneBarButtonItem
        navigationItem.rightBarButtonItem = resetBarButtonItem
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

    private func fetchData() {
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

        data = rows
    }

    @objc
    private func dismissSelf() {
        dismiss(animated: true)
    }

    @objc
    private func resetAll() {
        func showLoading() -> UIViewController {
            let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)

            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.gray
            loadingIndicator.startAnimating()

            alert.view.addSubview(loadingIndicator)
            present(alert, animated: true, completion: nil)
            return alert
        }

        let confirmationDialog = UIAlertController(title: "Are you Sure", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
            let loading = showLoading()

            TPTweak.resetAll {
                loading.dismiss(animated: true)
            }
        }

        confirmationDialog.addAction(confirmAction)
        confirmationDialog.addAction(cancelAction)

        present(confirmationDialog, animated: true)
    }
}

extension TPTweakViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
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
        var normalizedEntries = [String: [TPTweakEntry]]()

        cell.entries
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
                    cells.append(TPTweakPickerViewController.Cell(name: entry.cell, identifer: entry.getIdentifier(), type: entry.type))

                    if let footer = entry.footer {
                        footers.append(footer)
                    }
                }

                return TPTweakPickerViewController.Section(name: key, footer: footers.last, cells: cells)
            }

        let viewController = TPTweakPickerViewController(data: data)
        viewController.title = cell.name
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension TPTweakViewController {
    internal struct Row {
        internal let name: String
        internal let entries: [TPTweakEntry]
    }
}
#endif
