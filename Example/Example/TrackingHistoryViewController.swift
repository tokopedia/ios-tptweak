// Copyright: (c) 2022, Tokopedia
// GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

import UIKit

class TrackingHistoryViewController: UIViewController {
    let label: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "Tracking History View Controller"
        view.numberOfLines = 0
        view.textAlignment = .center
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tracking History"
        view.backgroundColor = .white
        
        setup_view: do {
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
                label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
}

