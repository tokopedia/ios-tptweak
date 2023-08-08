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
        
        Tracking locale is active: \(TPTweakEntry.trackingUsingLocale.getValue(Bool.self))
        Tracking locale identifer: \((UserDefaults.standard.value(forKey: "tracker_locale") as? String) ?? "no locale")
        """
    }
}
