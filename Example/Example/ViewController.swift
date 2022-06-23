// Copyright: (c) 2022, Tokopedia
// GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

import TPTweak
import UIKit

class ViewController: UIViewController {
    let label: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "Shake the phone or use ⌘⌃z on simulator to open TPTweak"
        view.numberOfLines = 0
        view.textAlignment = .left
        
        return view
    }()
    
    let currentValueTitle: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "Current Value"
        view.numberOfLines = 0
        view.font = .boldSystemFont(ofSize: 14)
        view.textAlignment = .left
        
        return view
    }()
    
    let currentValueLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = ""
        view.numberOfLines = 0
        view.textAlignment = .left
        
        return view
    }()
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "View Controller"
        view.backgroundColor = .white
        
        setup_view: do {
            view.addSubview(label)
            view.addSubview(currentValueTitle)
            view.addSubview(currentValueLabel)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
                label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
                label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
                currentValueTitle.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 32),
                currentValueTitle.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
                currentValueTitle.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
                currentValueLabel.topAnchor.constraint(equalTo: currentValueTitle.bottomAnchor, constant: 8),
                currentValueLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
                currentValueLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            ])
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.setupValueText()
        }
    }
    
    func setupValueText() {
        currentValueLabel.text = """
        Language: \(TPTweakEntry.changeLanguage.getValue(String.self))
        Tracking status: \(TPTweakEntry.enableTracking.getValue(Bool.self))
        Tracking server location: \(TPTweakEntry.trackingServerLocation.getValue(String.self))
        Tracking max timeout: \(TPTweakEntry.trackingTimeout.getValue(Int.self))
        """
    }
}


UIViewController().navigationController?.pushViewController(<#T##viewController: UIViewController##UIViewController#>, animated: <#T##Bool#>)
