// Copyright: (c) 2022, Tokopedia
// GNU General Public License v3.0+ (see LICENSE or https://www.gnu.org/licenses/gpl-3.0.txt)

@testable
import TPTweak
import XCTest

internal final class TPTweakTests: XCTestCase {
    private let userDefault = UserDefaults(suiteName: "com.tokopedia.tptweaktests")!

    internal var debugEnvironment: TPTweakStoreEnvironment {
        TPTweakStoreEnvironment(
            isDebugMode: {
                true
            },
            provider: {
                self.userDefault
            }
        )
    }

    internal var releaseEnvironment: TPTweakStoreEnvironment {
        TPTweakStoreEnvironment(
            isDebugMode: {
                false
            },
            provider: { [unowned self] in
                self.userDefault
            }
        )
    }

    override internal func tearDown() {
        super.tearDown()

        // clear user default
        let dictionary = userDefault.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            userDefault.removeObject(forKey: key)
        }
    }

    internal func test_debug_previous_empty() {
        TPTweakStore.environment = debugEnvironment
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: nil,
            type: .switch(defaultValue: true)
        )
        dummyEntry.setValue(true) // because on debug, value should be saved
        XCTAssertEqual(dummyEntry.getValue(Bool.self), true) // because we are on debug mode, getValue should return true
    }

    internal func test_release_previous_empty() {
        TPTweakStore.environment = releaseEnvironment
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: nil,
            type: .switch(defaultValue: true)
        )
        dummyEntry.setValue(true) // should not be saved on release
        XCTAssertEqual(dummyEntry.getValue(Bool.self), nil) // because this is new value, and set is not success on release, value should be nil
    }

    internal func test_debug_previous_exist() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: nil,
            type: .switch(defaultValue: true)
        )

        mock_so_value_exist: do {
            TPTweakStore.environment = debugEnvironment
            dummyEntry.setValue(true) // because on debug, value should be saved
            XCTAssertEqual(dummyEntry.getValue(Bool.self), true) // because we are on debug mode, getValue should return true
        }

        TPTweakStore.environment = releaseEnvironment
        XCTAssertEqual(dummyEntry.getValue(Bool.self), nil) // even if value on user default exist, but because this is release, will return nil
    }

    internal func test_remove_entry() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: nil,
            type: .switch(defaultValue: true)
        )

        TPTweakStore.environment = debugEnvironment
        dummyEntry.register()
        XCTAssertEqual(dummyEntry.getValue(Bool.self), true)

        dummyEntry.remove()
        XCTAssertEqual(dummyEntry.getValue(Bool.self), nil)
    }
}
