//
//  Canvas.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation
import ISO8601

public struct Canvas {

    public enum Keys {
        public static let ProjectId = "projectId"
        public static let Id = "id"
        public static let IsWritable = "isWritable"
        public static let IsPublicWritable = "isPublicWritable"
        public static let UpdatedAt = "updatedAt"
        public static let Title = "title"
        public static let Summary = "summary"
        public static let NativeVersion = "nativeVersion"
        public static let ArchivedAt = "archivedAt"
    }
    
    
	// MARK: - Properties

	public let id: String
	public let projectId: String
	public let isWritable: Bool
	public let isPublicWritable: Bool
	public var title: String
	public let summary: String
	public let nativeVersion: String
	public let updatedAt: NSDate
	public let archivedAt: NSDate?

	public var isEmpty: Bool {
		return summary.isEmpty
	}

	public var url: URL? {
		return URL(string: "https://usecanvas.com/\(projectId)/-/\(id)")
	}
}


extension Canvas: Resource {
	init(data: ResourceData) throws {
		id = data.id
		projectId = try data.decode(relationship: Keys.ProjectId)
		isWritable = try data.decode(attribute: Keys.IsWritable)
		isPublicWritable = try data.decode(attribute: Keys.IsPublicWritable)
		updatedAt = try data.decode(attribute: Keys.UpdatedAt)
		title = try data.decode(attribute: Keys.Title)
		summary = try data.decode(attribute: Keys.Summary)
		nativeVersion = try data.decode(attribute: Keys.NativeVersion)
		archivedAt = data.decode(attribute: Keys.ArchivedAt)
	}
}


extension Canvas: JSONSerializable, JSONDeserializable {
	public var dictionary: JSONDictionary {
		var dictionary: [String: Any] = [
			Keys.Id: id,
			Keys.ProjectId: projectId,
			Keys.IsWritable: isWritable,
			Keys.IsPublicWritable: isPublicWritable ,
			Keys.UpdatedAt: updatedAt.iso8601String()!,
			Keys.Title: title,
			Keys.Summary: summary,
			Keys.NativeVersion: nativeVersion
		]

		if let archivedAt = archivedAt {
			dictionary[Keys.ArchivedAt] = archivedAt.iso8601String() as AnyObject
		}

		return dictionary
	}

	public init?(dictionary: JSONDictionary) {
		guard let id = dictionary[Keys.Id] as? String,
			let projectId = dictionary[Keys.ProjectId] as? String,
			let isWritable = dictionary[Keys.IsWritable] as? Bool,
			let isPublicWritable = dictionary[Keys.IsPublicWritable] as? Bool,
			let updatedAtString = dictionary[Keys.UpdatedAt] as? String,
			let updatedAt = NSDate(iso8601String: updatedAtString),
			let title = dictionary[Keys.Title] as? String,
			let summary = dictionary[Keys.Summary] as? String,
			let nativeVersion = dictionary[Keys.NativeVersion] as? String
		else { return nil }

		self.id = id
        self.projectId = projectId
		self.isWritable = isWritable
		self.isPublicWritable = isPublicWritable
		self.title = title
		self.summary = summary
		self.nativeVersion = nativeVersion
		self.updatedAt = updatedAt

		let archivedAtString = dictionary[Keys.ArchivedAt] as? String
		archivedAt = archivedAtString.flatMap { NSDate(iso8601String: $0) }
	}
}


extension Canvas: Hashable {
	public var hashValue: Int {
		return id.hashValue
	}
}

extension Canvas : JSONRepresentable {

    public func toJSON() -> [String: Any]? {
        return dictionary
    }
}

public func ==(lhs: Canvas, rhs: Canvas) -> Bool {
	return lhs.id == rhs.id
}

