//
//  Account.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation
import ISO8601
import CloudKit

public struct Account {

	// MARK: - Properties

	public let id: String
    public let recordName: String?
	public let accessToken: String
	public let email: String
	public let verifiedAt: NSDate?
	public let user: User
}


// Account actually serializes and deserializes as AccessToken which is hidden from the consumer.
extension Account: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		var account: JSONDictionary = [
			"email": email as AnyObject,
			"user": user.dictionary as AnyObject
		]

		if let verifiedAt = verifiedAt?.iso8601String() {
			account["verified_at"] = verifiedAt as AnyObject
		}

		return [
			"access_token": accessToken as AnyObject,
			"account": account as AnyObject
		]
	}

	public init?(dictionary: JSONDictionary) {
		guard let accessToken = dictionary["access_token"] as? String,
			let accountDictionary = dictionary["account"] as? JSONDictionary,
			let email = accountDictionary["email"] as? String,
			let userDictionary = accountDictionary["user"] as? JSONDictionary,
			let user = User(dictionary: userDictionary)
		else { return nil }

		id = user.id
		self.accessToken = accessToken
		self.user = user
		self.email = email
		verifiedAt = (accountDictionary["verified_at"] as? String).flatMap { NSDate(iso8601String: $0) }
        self.recordName = nil
	}
    
    public init?(recordName: String, username: String) {
        id = "temporary-id"
        self.recordName = recordName
        self.accessToken = "temporary-token"
        self.email = "temporary-email"
        self.verifiedAt = NSDate()
        self.user = User(id: recordName, username: username, avatarURL: nil)
    }
}


extension Account: Resource {
	init(data: ResourceData) throws {
		id = data.id
		accessToken = (try data.decode(relationship: "verification_access_token") as AccessToken).token
		email = try data.decode(attribute: "email")
		verifiedAt = data.decode(attribute: "verified_at")

		let username: String = try data.decode(attribute: "username")
		let avatarURL: String = try data.decode(attribute: "avatar_url")
		user = User(id: id, username: username, avatarURL: URL(string: avatarURL)!)
        self.recordName = nil
	}
}
