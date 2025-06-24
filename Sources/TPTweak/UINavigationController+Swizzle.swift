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

extension UINavigationController {
    @objc internal func __viewDidDisappear(_ animated: Bool) {
        // destroy bubble when TPTweakController is being dismissed inside UINavigationController.
        if viewControllers.contains(where: { $0 is TPTweakViewController }) && !TPTweakViewController.isMinimize {
            TPTweakViewController.destroyMinimizable()
        }
        
        __viewDidDisappear(animated)
    }
}

#endif
