//
//  User.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/11/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

public struct User {
	
	// MARK: - Properties
	
	public let ID: String
	public let username: String
}


extension User: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		return [
			"id": ID,
			"username": username
		]
	}
	
	public init?(dictionary: JSONDictionary) {
		guard let ID = dictionary["id"] as? String,
			username = dictionary["username"] as? String
		else { return nil }
		
		self.ID = ID
		self.username = username
	}
}

