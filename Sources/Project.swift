//
//  Project.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//
import Foundation
import UIKit

public enum SerializationError: Error {
    case missingFile
    case invalidJson
    case missing(String)
    case invalid(String, Any)
}

public struct Project {

    
	// MARK: - Types

	public struct Color {
		public var red: Double
		public var green: Double
		public var blue: Double

		public var hex: String {
			return String(Int(red * 255), radix: 16) + String(Int(green * 255), radix: 16) + String(Int(blue * 255), radix: 16)
		}

		// From https://github.com/soffes/X
		public init?(hex string: String) {
			var hex = string as NSString

			// Remove `#` and `0x`
			if hex.hasPrefix("#") {
				hex = hex.substring(from: 1) as NSString
			} else if hex.hasPrefix("0x") {
				hex = hex.substring(from: 2) as NSString
			}

			// Invalid if not 3, 6, or 8 characters
			let length = hex.length
			if length != 3 && length != 6 && length != 8 {
				return nil
			}

			// Make the string 8 characters long for easier parsing
			if length == 3 {
				let r = hex.substring(with: NSRange(location: 0, length: 1))
				let g = hex.substring(with: NSRange(location: 1, length: 1))
				let b = hex.substring(with: NSRange(location: 2, length: 1))
                hex = "\(r)\(r)\(g)\(g)\(b)\(b)ff" as NSString
			} else if length == 6 {
				hex = String(hex) + "ff" as NSString
			}

			// Convert 2 character strings to CGFloats
			func hexValue(_ string: String) -> Double {
				let value = Double(strtoul(string, nil, 16))
				return value / 255
			}

			red = hexValue(hex.substring(with: NSRange(location: 0, length: 2)))
			green = hexValue(hex.substring(with: NSRange(location: 2, length: 2)))
			blue = hexValue(hex.substring(with: NSRange(location: 4, length: 2)))
		}
        
        var uiColor: UIColor {
            return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        }

	}


	// MARK: - Properties

	public let id: String
	public var name: String
	public let slug: String
    public let isPersonal: Bool
	public let membersCount: UInt
	public let color: Color?
    
    enum Keys {
        static let id = "id"
        static let name = "name"
        static let slug = "slug"
        static let membersCount = "members_count"
        static let isPersonal = "isPersonal"
        static let color = "color"
        
    }
}


extension Project: Resource {
	init(data: ResourceData) throws {
		id = data.id
		name = try data.decode(attribute: Keys.name)
		slug = try data.decode(attribute: Keys.slug)
		membersCount = try data.decode(attribute: Keys.membersCount)
        isPersonal = try data.decode(attribute: Keys.isPersonal)
		color = (data.attributes[Keys.color] as? String).flatMap(Color.init)
	}
}


extension Project: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		var dictionary: JSONDictionary = [
			Keys.id: id,
			Keys.name: name,
			Keys.slug: slug,
			Keys.isPersonal: isPersonal,
			Keys.membersCount: membersCount
		]

		if let color = color {
			dictionary[Keys.color] = color.hex
		}

		return dictionary
	}

	public init?(dictionary: JSONDictionary) {
		guard let id = dictionary[Keys.id] as? String,
			let name = dictionary[Keys.name] as? String,
			let slug = dictionary[Keys.slug] as? String,
			let membersCount = dictionary[Keys.membersCount] as? UInt,
            let isPersonal = dictionary[Keys.isPersonal] as? Bool

		else { return nil }

		self.id = id
		self.name = name
		self.slug = slug
		self.membersCount = membersCount
        self.isPersonal = isPersonal
		color = (dictionary[Keys.color] as? String).flatMap(Color.init)
	}
}

extension Project : JSONRepresentable {
    public func toJSON() -> [String: Any]? {
        return dictionary
    }
}

extension Project: Hashable {
	public var hashValue: Int {
		return id.hashValue
	}
}


public func ==(lhs: Project, rhs: Project) -> Bool {
	return lhs.id == rhs.id
}
