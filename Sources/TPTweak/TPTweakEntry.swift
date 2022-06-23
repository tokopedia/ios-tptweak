// Copyright: (c) 2022, Tokopedia
// GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

import Foundation

/**
 Entry type, pick your poison
 */
public enum TPTweakEntryType {
    case `switch`(defaultValue: Bool)
    case action(() -> Void)
    case strings(item: [String], selected: String)
    case numbers(item: [Double], selected: Double)
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

    /// Will only visible on second page / TPTweakPickerViewController
    public let footer: String?
    /// type of Entry
    public let type: TPTweakEntryType

    public init(
        category: String,
        section: String,
        cell: String,
        footer: String?,
        type: TPTweakEntryType
    ) {
        self.category = category
        self.section = section
        self.cell = cell
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
