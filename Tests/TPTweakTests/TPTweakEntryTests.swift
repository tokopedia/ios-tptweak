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
@testable
import TPTweak
import XCTest

internal final class TPTweakEntryTests: XCTestCase {
    internal func test_switch_search_metadata() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: "footer",
            type: .switch(defaultValue: true)
        )
        
        let expectedMetaData = "foo bar baz footer switch bool boolean true"
        XCTAssertEqual(dummyEntry.generateSearchMetadata(), expectedMetaData)
    }
    
    internal func test_strings_search_metadata() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: "footer",
            type: .strings(item: ["A", "B", "C"], selected: "C")
        )
        
        let expectedMetaData = "foo bar baz footer strings string array a,b,c c"
        XCTAssertEqual(dummyEntry.generateSearchMetadata(), expectedMetaData)
    }
    
    internal func test_numbers_search_metadata() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: "footer",
            type: .numbers(item: [1, 2, 3], selected: 2)
        )
        
        let expectedMetaData = "foo bar baz footer numbers number int integer array 1.0,2.0,3.0 2.0"
        XCTAssertEqual(dummyEntry.generateSearchMetadata(), expectedMetaData)
    }
    
    internal func test_actions_search_metadata() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: "footer",
            type: .action {}
        )
        
        let expectedMetaData = "foo bar baz footer action closure"
        XCTAssertEqual(dummyEntry.generateSearchMetadata(), expectedMetaData)
    }
    
    internal func test_set_favourite() {
        // mock favourite empty
        TPTweakEntry.favourite.setValue([String]())
        
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: "footer",
            type: .action {}
        )
        
        dummyEntry.setAsFavourite()
        
        let favourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        XCTAssertTrue(favourites.contains(where: { $0 == dummyEntry.getIdentifier() }))
    }
    
    internal func test_remove_favourite() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: "footer",
            type: .action {}
        )
        
        // mock favourite
        TPTweakEntry.favourite.setValue([dummyEntry.getIdentifier()])
        
        dummyEntry.removeFavourite()
        
        let favourites = TPTweakEntry.favourite.getValue(Set<String>.self) ?? []
        XCTAssertFalse(favourites.contains(where: { $0 == dummyEntry.getIdentifier() }))
    }
    
    internal func test_identifier() {
        let dummyEntry = TPTweakEntry(
            category: "foo",
            section: "bar",
            cell: "baz",
            footer: "footer",
            type: .action {}
        )
        
        let expected = "TPTweak:foo-bar-baz"
        XCTAssertEqual(dummyEntry.getIdentifier(), expected)
    }
}
#endif
