//
//  Organization.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

public struct Organization {

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
	}


	// MARK: - Properties

	public let id: String
	public let name: String
	public let slug: String
	public let membersCount: UInt
	public let color: Color?
}


extension Organization: Resource {
	init(data: ResourceData) throws {
		id = data.id
		name = try data.decode(attribute: "name")
		slug = try data.decode(attribute: "slug")
		membersCount = try data.decode(attribute: "members_count")
		color = (data.attributes["color"] as? String).flatMap(Color.init)
	}
}


extension Organization: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		var dictionary: JSONDictionary = [
			"id": id as AnyObject,
			"name": name as AnyObject,
			"slug": slug as AnyObject,
			"members_count": membersCount as AnyObject
		]

		if let color = color {
			dictionary["color"] = color.hex as AnyObject
		}

		return dictionary
	}

	public init?(dictionary: JSONDictionary) {
		guard let id = dictionary["id"] as? String,
			let name = dictionary["name"] as? String,
			let slug = dictionary["slug"] as? String,
			let membersCount = dictionary["members_count"] as? UInt
		else { return nil }

		self.id = id
		self.name = name
		self.slug = slug
		self.membersCount = membersCount
		color = (dictionary["color"] as? String).flatMap(Color.init)
	}
}


extension Organization: Hashable {
	public var hashValue: Int {
		return id.hashValue
	}
}


public func ==(lhs: Organization, rhs: Organization) -> Bool {
	return lhs.id == rhs.id
}
