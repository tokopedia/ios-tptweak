# TPTweak

TPTweak is a debugging tool to help adjust your iOS app on the fly without recompile.
inspired by facebook's [Tweak](https://github.com/facebookarchive/Tweaks), TPTweak is fully written in swift, and with simpler API.

|Example of TPTweak|Selecting options of string|Selecting options of number|Search|
|----|----|----|----|
|![](assets/tptweak_home.png)|![](assets/tptweak_string_selection_example.png)|![](assets/tptweak_number_selection_example.png)|![Simulator Screenshot - iPhone 14 Pro - 2023-08-29 at 16 57 39](https://github.com/tokopedia/ios-tptweak/assets/16457495/02dbd7d6-0fa3-4a44-85b0-dfc52501b3b6)|


|Set Favourite by swipe|Set Favourite by long press|Favourite Page|
|----|----|----|
|![Simulator Screenshot - iPhone 14 Pro - 2023-08-29 at 19 07 10](https://github.com/tokopedia/ios-tptweak/assets/16457495/1580305b-1667-4005-ab61-ff03ff419bd8)|![Simulator Screenshot - iPhone 14 Pro - 2023-08-29 at 19 16 06](https://github.com/tokopedia/ios-tptweak/assets/16457495/a8be171b-fcf7-4923-9c2f-bca646f39919)|![Simulator Screenshot - iPhone 14 Pro - 2023-08-29 at 19 07 04](https://github.com/tokopedia/ios-tptweak/assets/16457495/5562f00e-22e7-4ab3-8a6d-237dbcfa596c)|

# Installation
## Swift Package Manager
With xcode, add this URL
```
https://github.com/tokopedia/ios-tptweak
```

or manually add to your `Package.swift`
```swift
.package(url: "https://github.com/tokopedia/ios-tptweak", from: "2.0.0"),
```

# Cocoapods
add this to your `Podfile`
```
pod 'TPTweak', '~> 2.0.0'
```

# Nomenclature
`TPTweakEntry` = Representation of option on TPTweak

`TPTweakStore` = Brain of TPTweak, all logic of storing, reading and mutating value of TPTweak.
# TPTweakEntry
TPTweakEntry will represent a option on TPTweak.

```swift
TPTweakEntry(
    category: "Tracking",
    section: "Tracking",
    cell: "Enable Tracking",
    footer: "Turn this on to enable tracking",
    type: .switch(defaultValue: true)
)
```
- category: will be a cell on the first page
- section: will be a group of section on the second page
- cell: will be the name of the cell inside the section
- footer: add footer on the end of the section.(if multiply detected, will use the last one)
- type: the type of cell you want to use

### TPTweakEntry type
**Switch**

![](assets/switch.png)
Using this type, you can create a cell with a UISwitch to enable/disable an option.You could also supply default value, if no value detected.

```swift
.switch(defaultValue: true)
```


You could also add `closure: ((Bool) -> Void)?` that will run **after** the value is changed.

```swift
.switch(defaultValue: true, closure: { isToggledOn in
    UserDefaults.standard.set(isToggledOn, forKey: "myvalue_is_on")
})
```

**Strings**

![](assets/strings.png)
Using this type, you can create a selection of strings.When user tap the options, it will automatically open the selection.

```swift
.strings(item: ["US", "UK", "SG"], selected: "SG")
```

**Numbers**

![](assets/numbers.png)
Using this type, you can create a selectio of numbers.When user tap the options, it will automatically open the selection.

```swift
.numbers(item: [10, 15, 20], selected: 10)
```

**Action**

![](assets/action.png)
Using this type, it gives you the flexibility to do everything. with given `closure`, you can for example, open custom page you create, or executing a `UserDefaults`, or more.

```swift
.action({
    UserDefaults.standard.set(true, forKey: "clear_cache")
    Cache.clear()
})
```

# How to Use

## Creating your TPTweakEntry
first you need to create your entry, we recommend to create an extension and put every entry definition as a static.

```swift
import TPTweak

extension TPTweakEntry {
    static let enableTracking = TPTweakEntry(
        category: "Tracking",
        section: "Tracking",
        cell: "Enable Tracking",
        footer: "Turn this on to enable tracking",
        type: .switch(defaultValue: true)
    )
}
```
## Registering your TPTweakEntry
once you create your entry, you need to register it to TPTweak so it will show up on TPTweak page. This can be achieved by calling `register()` on each entry.

You can call it whenever you want, but we suggest to put it on your `AppDelegate`'s `internal func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?)`

```swift
internal func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // register TPTweak Entry
        TPTweakEntry.enableTracking.register()
    }
```

## Openning TPTweak page

openning TPTweak is achievable by openning `TPTweakViewController`. but the easier way is to replace your `UIWindow` with `TPTweakShakeWindow`.

### Manual
```swift
// without nav
let viewController = TPTweakViewController()
self.navigationController?.pushViewController(viewController, animated: true)

// with nav
let tptweakWithNav = TPTweakWithNavigatationViewController()
self.present(tptweakWithNav)
```

### Shake (Recommended)
```swift
@UIApplicationMain
internal final class AppDelegate: UIResponder, UIApplicationDelegate {
    internal var window: UIWindow?

    internal func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // register TPTweakShakeWindow to enable openning TPTweak from shaking the device
        window = TPTweakShakeWindow(frame: UIScreen.main.bounds)
        ...
    }
}

```

## Use TPTweak Value
Once your TPTweakEntry is set, you can get and set a value from it.

### Read value
```
// will return true or false based on latest value changed on TPTweak
let isTrackingEnable = TPTweakEntry.enableTracking.getValue(Bool.self) 
```

### Set value
if you want to set the value manually programmatically
```
TPTweakEntry.enableTracking.setValue(true)
```

## Use custom UserDefaults provider
you can change the UserDefaults with modifying the TPTweakStore environment
```swift
TPTweakStore.environment.provider = {
    UserDefaults(suiteName: "group.com.example")!
}
```

## Use custom isDebugMode logic
you can configure when to enable TPTweak value by adjusting TPTweakStore environment
```swift
TPTweakStore.environment.isDebugMode = {
    #if DEBUG || IN_HOUSE 
        return true
    #else
        return false
    #endif
}
```

# License
```
 Copyright 2022-2024 Tokopedia. All rights reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
```


