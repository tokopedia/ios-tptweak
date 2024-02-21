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

import Foundation

internal typealias TPTweak = TPTweakStore

// swiftformat:disable:next spaceInsideComments
/**
  # TPTweak

  TPTweak is FBTweak but written on Swift.

  # API
  ```
  TPTweakStore -> The Brain of TPTweak, all logic from storing value to reading value from persistant storage.
  TPTweakEntry -> A representation of Tweak Options, you create this to create Tweak option.
 ```

  ## TPTweakEntry
  ```swift
  struct TPTweakEntry {
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
   }
  ```
  As representation of tweak option, you need to provide `category`, `section` and `cell`.
  you also could provide `footer` as additional information(only last cell on section will have it's footer displayed).
  for `type`, you could choose from this option

  ```swift
  enum TPTweakEntryType {
      case `switch`(defaultValue: Bool)
      case action(() -> Void)
      case strings(item: [String], selected: String)
      case numbers(item: [Double], selected: Double)
  }
  ```

 ## How to Use
 First you need to define your entry, let's look example below
 ```swift
 extension TPTweakEntry {
     public static var baseURL: Self {
         TPTweakEntry(
             category: "Network",
             section: "Environment",
             cell: "Base URL",
             footer: "Require Restart to apply the effect",
             type: .strings(item: ["Production", "Staging"], selected: "Production")
         )
     }
 }
 ```
 we define an entry for `Base URL`

 ## Read/Set value
 from your entry, you can access `getValue(_:)` or `setValue(_:)`

 ```swift
 // read value
 TPTweakEntry.baseURL.getValue(String.self) // should return optional string

 // set value
 TPTweakEntry.baseURL.setValue("Staging") // return "Staging" if success
 ```
 *to use getValue, you need to spesify what type of value you want

 ## Registering to your App
 after creating your entry, you can call `register()` to use it on main app
 open `TPTweakDelegateWorker.swift`, and register your entry

 ```swift
 TPTweakEntry.baseURL.register()
 ```
 */
public enum TPTweakStore {
    /// all side effect logic, also for unit testing
    internal static var environment: TPTweakStoreEnvironment = .live
    internal static var entries: [String: TPTweakEntry] = [:]

    // MARK: - Interface

    /**
     Add your entry to `TPTweak`.

     by calling this function you will:
     - register your entry to be included on Tweak.
     - will smartly initialize the value on `provider` if this is the first time

     - Parameter entry: entry to add
     */
    internal static func add(_ entry: TPTweakEntry) {
        /// will only execute on debug mode
        guard environment.isDebugMode() else { return }

        let identifier = entry.getIdentifier()

        /// check if value exist on persistant storage, if not, set it.
        /// indicate no value exist before on provider
        if environment.provider().data(forKey: identifier) == nil {
            switch entry.type {
            case let .switch(defaultValue, _):
                set(defaultValue, identifier: identifier)
            case let .numbers(_, defaultValue, _):
                set(defaultValue, identifier: identifier)
            case let .strings(_, defaultValue, _):
                set(defaultValue, identifier: identifier)
            case .action:
                break
            }
        }

        // only append if unique
        if entries[entry.getIdentifier()] == nil {
            entries[entry.getIdentifier()] = entry
        }
    }

    /**
     read data from provider based on identifier

     - Parameters:
        - type: type of the value
        - identifier: identifier of the string, format shuld be `$category-$section-$cell`

     - Returns: optional, will return if value exist
     */
    internal static func read<ValueType: Decodable>(type: ValueType.Type, identifier: String) -> ValueType? {
        guard
            /// will only execute on debug mode
            environment.isDebugMode(),
            let rawData = environment.provider().data(forKey: identifier)
        else { return nil }

        if #available(iOS 13.0, *) {
            let unarchieve = try? JSONDecoder().decode(type, from: rawData)
            return unarchieve
        } else {
            /// for below ios 12.0
            /// encoding top level type like Bool, String, Int will cause encode error
            /// Swift.EncodingError.invalidValue(false, Swift.EncodingError.Context(codingPath: [], debugDescription: "Top-level Bool encoded as number property list fragment.", underlyingError: nil))
            /// so we wrap it to array to hack and fix the issue
            let unarchieve = try? JSONDecoder().decode([ValueType].self, from: rawData)
            return unarchieve?.first
        }
    }

    /**
     Reset everything on `provider`
     */
    internal static func resetAll(completion: (() -> Void)? = nil) {
        /// will only execute on debug mode
        guard environment.isDebugMode() else { return }

        /// deletion process could take several second, to prevent free, move execution to background thread
        DispatchQueue.global(qos: .background).async {
            for key in environment.provider().dictionaryRepresentation().keys where String(key).hasPrefix(TPTweakEntry.prefix) {
                remove(identifier: key)
            }

            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    /**
     remove based on identifier

     - Parameters:
        - identifier: identifier of the string, format shuld be `TPTweak:$category-$section-$cell`
     */
    internal static func remove(identifier: String) {
        /// will only execute on debug mode
        guard environment.isDebugMode() else { return }

        // remove from persistant storage
        environment.provider().removeObject(forKey: identifier)
        environment.provider().synchronize()

        // remove from entries
        entries.removeValue(forKey: identifier)
    }

    /**
     set data to provider

     - Parameters:
        - type: type of the value
        - identifier: identifier of the string, format shuld be `$category-$section-$cell`

     - Returns: value from `provider`, that you recently set, it should return your value if success
     */
    @discardableResult
    internal static func set<ValueType: Codable>(_ value: ValueType, identifier: String) -> ValueType? {
        /// will only execute on debug mode
        guard environment.isDebugMode() else { return nil }

        let encodedData: Data?
        if #available(iOS 13.0, *) {
            encodedData = try? JSONEncoder().encode(value)
        } else {
            /// for below ios 12
            /// encoding top level type like Bool, String, Int will cause encode error
            /// Swift.EncodingError.invalidValue(false, Swift.EncodingError.Context(codingPath: [], debugDescription: "Top-level Bool encoded as number property list fragment.", underlyingError: nil))
            /// so we wrap it to array to hack and fix the issue
            encodedData = try? JSONEncoder().encode([value])
        }

        guard let unwrapedEncodedData = encodedData else { return nil }
        environment.provider().set(unwrapedEncodedData, forKey: identifier)
        environment.provider().synchronize()

        // return recent set value, user could check this value for validation
        return read(type: type(of: value), identifier: identifier)
    }
}

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

internal struct TPTweakStoreEnvironment {
    internal var isDebugMode: () -> Bool
    internal var provider: () -> UserDefaults

    internal static var live: Self {
        TPTweakStoreEnvironment(
            isDebugMode: {
                #if DEBUG
                    return true
                #else
                    return false
                #endif
            },
            provider: {
                UserDefaults.standard
            }
        )
    }
}
