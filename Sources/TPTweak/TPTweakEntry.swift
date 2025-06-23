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
import Foundation
import UIKit

/**
 Entry type, pick your poison
 */
public enum TPTweakEntryType {
    case `switch`(defaultValue: Bool, completion: ((Bool) -> Void)? = nil)
    case action(accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, () -> Void)
    case strings(item: [String], selected: String, completion: ((String) -> Void)? = nil)
    case numbers(item: [Double], selected: Double, completion: ((Double) -> Void)? = nil)
}

/**
 Representing Entry for Tweak.
 */
public struct TPTweakEntry {
    /// Category will be displayed on first page of TPTweak
    public let category: String
    /// Section is the grouping of `cell` on second page of TPTweak
    public let section: String
    /// Cell will be the name of cell on second page table of TPTweak
    public let cell: String
    /// icon on the left of the cell
    public let cellLeftIcon: UIImage?

    /// Will only visible on second page / TPTweakPickerViewController
    public let footer: String?
    
    /// type of Entry
    public let type: TPTweakEntryType
    
    public init(
        category: String,
        section: String,
        cell: String,
        cellLeftIcon: UIImage? = nil,
        footer: String? = nil,
        type: TPTweakEntryType
    ) {
        self.category = category
        self.section = section
        self.cell = cell
        self.cellLeftIcon = cellLeftIcon
        self.footer = footer
        self.type = type
    }
    
    /**
     Read current value of this entry on TPTweak

     example
     ```swift
     entry.getValue(Bool.self) // will return value if exist or nil if empty
     ```

     - Parameter type: type of value
     - Warning: Will always return nil on `RELEASE` mode
     - Returns: value on TPTweak if exist or nil if empty
     ```
     */
    public func getValue<T: Decodable>(_ type: T.Type) -> T? {
        TPTweakStore.read(type: type, identifier: getIdentifier())
    }

    /**
     set value for this entry on TPTweak

     example
     ```swift
     entry.setValue(true) // will return value if success or nil if failure
     ```

     - Parameter value: new value for this entry
     - Warning: Will not set new value and always return nil on `RELEASE` mode
     - Returns: value on TPTweak if success or nil if failure
     ```
     */
    @discardableResult
    public func setValue<T: Codable>(_ value: T) -> T? {
        TPTweakStore.set(value, identifier: getIdentifier())
    }

    /**
     remove entry from TPTweak

     example
     ```swift
     entry.remove()
     ```
     */
    public func remove() {
        TPTweakStore.remove(identifier: getIdentifier())
    }

    /**
     Register your Entry to `TPTweak`
     */
    public func register() {
        TPTweakStore.add(self)
    }
}

// internal entries
extension TPTweakEntry {
    internal static var favourite: TPTweakEntry {
        TPTweakEntry(category: "_tptweak", section: "internal", cell: "favourite", footer: nil, type: .action({}))
    }
    
    internal static var clearCache: TPTweakEntry {
        TPTweakEntry(
            category: "_tptweak",
            section: "Miscellaneous",
            cell: "Reset",
            footer: "This will reset all Tweaks to default value",
            type: .action(accessoryType: .none, {
                TPTweak.resetAll()
            })
        )
    }
    
    public static var _internal_tptweak_peepOpacity: TPTweakEntry {
        TPTweakEntry(
            category: "_tptweak",
            section: "Interaction",
            cell: "Hold Opacity",
            footer: "The opacity when you hold the navigation bar",
            type: .numbers(item: [0, 0.25, 0.5, 0.75, 1], selected: 0.25)
        )
    }
    
    public static var _internal_tptweak_layout: TPTweakEntry {
        TPTweakEntry(
            category: "_tptweak",
            section: "Layout",
            cell: "Layout",
            type: TPTweakEntryType.strings(
                item: TPTweakLayout.allCases.map(\.rawValue),
                selected: TPTweakLayout.group.rawValue,
                completion: nil
            )
        )
    }
    
    public static var _internal_tptweak_isMinimizable: TPTweakEntry {
        TPTweakEntry(
            category: "_tptweak",
            section: "Layout",
            cell: "Minimizable",
            type: TPTweakEntryType.switch(defaultValue: false, completion: nil)
        )
    }
}

// MARK: - indentifier helper

extension TPTweakEntry {
    /// Get identifier
    internal func getIdentifier() -> String {
        Self.createIdentifier(category: category, section: section, cell: cell)
    }

    /// prefix for identifier on UserDefault
    internal static let prefix = "TPTweak:"

    /// get formatted identifier from given parameter
    internal static func createIdentifier(category: String, section: String, cell: String) -> String {
        prefix + category + "-" + section + "-" + cell
    }
}

// MARK: - Favourite action

extension TPTweakEntry {
    /**
     check if current entry is favourite or not.
     */
    public var isFavourite: Bool {
        let favourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        return favourites.contains(where: { $0 == getIdentifier() })
    }
    
    /// flag this entry as favourite.
    public func setAsFavourite() {
        var currentFavourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        currentFavourites.insert(getIdentifier())
        
        TPTweakEntry.favourite.setValue(currentFavourites)
    }
    
    /// remove this entry from favourite list.
    public func removeFavourite() {
        var currentFavourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        currentFavourites.remove(getIdentifier())
        
        TPTweakEntry.favourite.setValue(currentFavourites)
    }
    
    internal static func isFavourite(identifier: String) -> Bool {
        TPTweakStore.entries[identifier]?.isFavourite ?? false
    }
    
    internal static func setAsFavourite(identifier: String) {
        TPTweakStore.entries[identifier]?.setAsFavourite()
    }
    
    internal static func removeFavourite(identifier: String) {
        TPTweakStore.entries[identifier]?.removeFavourite()
    }
}

// MARK: - Searchable

extension TPTweakEntry {
    /// generate metadata to improve search hit.
    internal func generateSearchMetadata() -> String {
        var metadata = ""
        
        metadata += category + " " + section + " " + cell
        
        if let footer = footer {
            metadata += " " + footer
        }
        
        switch type {
        case .action:
            metadata += " action closure"
        case let .numbers(items, selected,_):
            metadata += " numbers number int integer array"
            metadata += " " + items.map { String($0) }.joined(separator: ",")
            metadata += " " + String(selected)
        case let .strings(items, selected,_):
            metadata += " strings string array"
            metadata += " " + items.joined(separator: ",")
            metadata += " " + selected
        case let .switch(defaultValue,_):
            metadata += " switch bool boolean \(defaultValue)"
        }
        
        return metadata.lowercased()
    }
}
#endif
