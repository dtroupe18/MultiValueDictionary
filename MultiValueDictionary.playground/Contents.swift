import Foundation
import XCTest

protocol MultiValueDictionary : Sequence where Element == (Key, Value) {
  associatedtype Key
  associatedtype Value

  mutating func addElement(withKey: Key, andValue: Value) -> Bool
  func getValues(forKey: Key) -> AnySequence<Value>?

  mutating func removeElement(forKey: Key, andValue: Value) -> (Key, Value)?
  mutating func removeValues(forKey: Key) -> AnySequence<Value>?
}

struct MultiDictionary<KeyType: Hashable, ValueType: Hashable>: MultiValueDictionary {
  typealias Key = KeyType
  typealias Value = ValueType

  private var dict: [KeyType: [ValueType]] = [:]

  /// Total number of key value pairs in the dictionary. Each key can have multiple
  /// values so this count is equivalent to the number of items in all of the key arrays.
  public var count: Int {
    dict.values.reduce(0) { $0 + $1.count }
  }

  public var keys: Dictionary<KeyType, [ValueType]>.Keys {
    dict.keys
  }

  public var values: [ValueType] {
    dict.values.reduce([], +)
  }

  func makeIterator() -> AnyIterator<(KeyType, ValueType)> {
    var copy = dict

    return AnyIterator<(KeyType, ValueType)> {
      var dictInterator = copy.makeIterator()

      while let key = dictInterator.next() {
        var valueIterator = key.value.makeIterator()

        while let nextValue = valueIterator.next() {
          copy[key.key]?.removeFirst()

          return (key.key, nextValue)
        }
      }

      return nil
    }
  }

  mutating func addElement(withKey: KeyType, andValue: ValueType) -> Bool {
    if var array = dict[withKey] {
      array.append(andValue)
      dict[withKey] = array
    } else {
      dict[withKey] = [andValue]
    }

    return true
  }

  func getValues(forKey: KeyType) -> AnySequence<ValueType>? {
    if let values = dict[forKey] {
      return AnySequence(values)
    }

    return nil
  }

  mutating func removeElement(forKey: KeyType, andValue: ValueType) -> (KeyType, ValueType)? {
    guard var values = dict[forKey] else { return nil }

    guard let firstIndex = values.firstIndex(of: andValue) else { return nil }
    let value = values[firstIndex]

    values.remove(at: firstIndex)
    dict[forKey] = values

    return (forKey, value)
  }

  mutating func removeValues(forKey: KeyType) -> AnySequence<ValueType>? {
    if let values = dict[forKey] {
      dict[forKey] = nil
      return AnySequence(values)
    }

    return nil
  }
}

final class MultiDictionaryTests: XCTestCase {
  func testMultiValueDictionaryIterable() {
    let keys: [String] = ["Key-1", "Key-2"]
    let dictionary: [String: [Int]] = [
      keys[0]: [1, 2, 3],
      keys[1]: [4, 5, 6]
    ]

    var multi1 = MultiDictionary<String, Int>()
    XCTAssertTrue(multi1.keys.count == 0)
    XCTAssertTrue(multi1.values.count == 0)
    XCTAssertTrue(multi1.count == 0)

    multi1.addElement(withKey: "Key-1", andValue: 1)
    XCTAssertTrue(multi1.keys.count == 1)
    XCTAssertTrue(multi1.values.count == 1)
    XCTAssertTrue(multi1.count == 1)

    multi1.addElement(withKey: "Key-1", andValue: 2)
    XCTAssertTrue(multi1.keys.count == 1)
    XCTAssertTrue(multi1.values.count == 2)
    XCTAssertTrue(multi1.count == 2)

    multi1.addElement(withKey: "Key-1", andValue: 3)
    XCTAssertTrue(multi1.keys.count == 1)
    XCTAssertTrue(multi1.values.count == 3)
    XCTAssertTrue(multi1.count == 3)

    multi1.addElement(withKey: "Key-2", andValue: 4)
    XCTAssertTrue(multi1.keys.count == 2)
    XCTAssertTrue(multi1.values.count == 4)
    XCTAssertTrue(multi1.count == 4)

    multi1.addElement(withKey: "Key-2", andValue: 5)
    XCTAssertTrue(multi1.keys.count == 2)
    XCTAssertTrue(multi1.values.count == 5)
    XCTAssertTrue(multi1.count == 5)

    multi1.addElement(withKey: "Key-2", andValue: 6)
    XCTAssertTrue(multi1.keys.count == 2)
    XCTAssertTrue(multi1.values.count == 6)
    XCTAssertTrue(multi1.count == 6)

    let it = multi1.makeIterator()
    while let (key, value) = it.next() {
      XCTAssertTrue(dictionary[key]?.contains(value) == true)
      XCTAssertTrue(multi1.keys.contains(key))
    }

    for (key, value) in multi1 {
      XCTAssertTrue(dictionary[key]?.contains(value) == true)
      XCTAssertTrue(multi1.keys.contains(key))
    }

    let keys2: [String] = ["Key-1", "Key-2", "Key-3", "Key-4", "Key-5"]
    let values2: [String] = ["value1", "value2", "value3", "value4", "value5"]

    let dictionary2: [String: String] = [
      keys2[0]: values2[0],
      keys2[1]: values2[1],
      keys2[2]: values2[2],
      keys2[3]: values2[3],
      keys2[4]: values2[4]
    ]

    var multi2 = MultiDictionary<String, String>()
    XCTAssertTrue(multi2.keys.count == 0)
    XCTAssertTrue(multi2.values.count == 0)
    XCTAssertTrue(multi2.count == 0)

    multi2.addElement(withKey: keys2[0], andValue: values2[0])
    multi2.addElement(withKey: keys2[1], andValue: values2[1])
    multi2.addElement(withKey: keys2[2], andValue: values2[2])
    multi2.addElement(withKey: keys2[3], andValue: values2[3])
    multi2.addElement(withKey: keys2[4], andValue: values2[4])

    let it2 = multi2.makeIterator()
    while let (key, value) = it2.next() {
      XCTAssertTrue(dictionary2[key] == value)
      XCTAssertTrue(multi2.keys.contains(key))
    }

    for (key, value) in multi2 {
      XCTAssertTrue(dictionary2[key] == value)
      XCTAssertTrue(multi2.keys.contains(key))
    }
  }

  func testMultiValueDictionaryKeys() {
    var multi = MultiDictionary<String, String>()
    XCTAssertTrue(multi.keys.count == 0)

    multi.addElement(withKey: "k1", andValue: "v1")
    multi.addElement(withKey: "k1", andValue: "v2")
    multi.addElement(withKey: "k1", andValue: "v3")
    multi.addElement(withKey: "k1", andValue: "v4")
    multi.addElement(withKey: "k1", andValue: "v5")

    XCTAssertTrue(multi.keys.count == 1)

    multi.addElement(withKey: "k2", andValue: "v6")
    XCTAssertTrue(multi.keys.count == 2)
  }

  func testMultiValueDictionaryGetValues() {
    var multi = MultiDictionary<String, String>()
    multi.addElement(withKey: "k1", andValue: "v1")
    multi.addElement(withKey: "k1", andValue: "v2")
    multi.addElement(withKey: "k1", andValue: "v3")

    let k1Values = multi.getValues(forKey: "k1")

    let expectedValues = ["v1", "v2", "v3"]
    for val in expectedValues {
      XCTAssertTrue(k1Values?.contains(val) == true)
    }
  }

  func testMultiValueDictionaryRemoveElement() {
    var multi = MultiDictionary<String, String>()
    multi.addElement(withKey: "k1", andValue: "v1")
    multi.addElement(withKey: "k1", andValue: "v2")
    multi.addElement(withKey: "k1", andValue: "v3")

    multi.removeElement(forKey: "k1", andValue: "v2")

    let values = multi.values
    XCTAssertTrue(values.contains("v2") == false)
  }

  func testMultiValueDictionaryRemoveValues() {
    var multi = MultiDictionary<String, String>()
    multi.addElement(withKey: "k1", andValue: "v1")
    multi.addElement(withKey: "k1", andValue: "v2")
    multi.addElement(withKey: "k1", andValue: "v3")

    multi.addElement(withKey: "k2", andValue: "v4")
    multi.addElement(withKey: "k2", andValue: "v5")
    multi.addElement(withKey: "k2", andValue: "v6")

    multi.removeValues(forKey: "k1")

    let k1Values = multi.getValues(forKey: "k1")
    XCTAssertNil(k1Values)
  }
}

MultiDictionaryTests.defaultTestSuite.run()
