//
//  AuthorizationClient.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/13/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation

/// This client is used to create and verify an account.
public struct AuthorizationClient: NetworkClient {

	// MARK: - Properties

	public let clientID: String
	fileprivate let clientSecret: String
	public let baseURL: URL
	public let session: URLSession


	// MARK: - Initializers

	public init(clientID: String, clientSecret: String, baseURL: URL = CanvasKit.baseURL as URL, session: URLSession = URLSession.shared) {
		self.clientID = clientID
		self.clientSecret = clientSecret
		self.baseURL = baseURL
		self.session = session
	}
	
	
	// MARK: - Creating an Account
	
	public func createAccount(_ email: String, username: String, password: String, completion: @escaping (Result<Void>) -> Void) {
		let params = [
			"data": [
				"type": "account",
				"attributes": [
					"email": email,
					"password": password,
					"username": username
				]
			]
		]

		let request = self.request("account", parameters: params as JSONDictionary)
		session.dataTask(with: request, completionHandler: { responseData, response, error in
			guard let responseData = responseData,
				let json = try? JSONSerialization.jsonObject(with: responseData, options: []),
				let dictionary = json as? JSONDictionary
			else {
				networkCompletionQueue.async {
					completion(.failure("Invalid response."))
				}
				return
			}

			if let status = (response as? HTTPURLResponse)?.statusCode, status == 201 {
				networkCompletionQueue.async {
                    // FIXME: This line is troublesome with a return type of void
                    // completion?(.success)
				}
				return
			}

			networkCompletionQueue.async {
				completion(.failure(self.parseErrors(dictionary) ?? "Invalid response."))
			}
		}) .resume()
	}
	
	public func verifyAccount(_ token: String, completion: @escaping (Result<Account>) -> Void) {
		let params = [
			"data": [
				"type": "account",
				"attributes": [
					"verification_token": token
				]
			]
		]

		let request = self.request("account/actions/verify", parameters: params as JSONDictionary)
		session.dataTask(with: request, completionHandler: { responseData, response, error in
			guard let responseData = responseData,
				let json = try? JSONSerialization.jsonObject(with: responseData, options: []),
				let dictionary = json as? JSONDictionary
			else {
				networkCompletionQueue.async {
					completion(.failure("Invalid response."))
				}
				return
			}

			if let account: Account = ResourceSerialization.deserialize(dictionary: dictionary) {
				networkCompletionQueue.async {
					completion(.success(account))
				}
				return
			}

			networkCompletionQueue.async {
				completion(.failure(self.parseErrors(dictionary) ?? "Invalid response."))
			}
		}) .resume()
	}


	// MARK: - Private

	fileprivate func request(_ path: String, parameters: JSONDictionary) -> URLRequest {
		let request = NSMutableURLRequest(url: baseURL.appendingPathComponent(path))
		request.httpMethod = "POST"
		request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

		// Add the client authorization
		if let authorization = authorizationHeader(clientID, password: clientSecret) {
			request.setValue(authorization, forHTTPHeaderField: "Client-Authorization")
		}

		return request as URLRequest
	}

	fileprivate func authorizationHeader(_ username: String, password: String) -> String? {
		guard let data = "\(username):\(password)".data(using: String.Encoding.utf8)
		else { return nil }

		let base64 = data.base64EncodedString(options: [])
		return "Basic \(base64)"
	}

	fileprivate func parseErrors(_ dictionary: JSONDictionary) -> String? {
		guard let errors = dictionary["errors"] as? [JSONDictionary] else { return nil }
		var errorMessages = [String]()

		for container in errors {
			guard let meta = container["meta"] as? JSONDictionary else { continue }

			for (key, values) in meta {
				guard let values = values as? [String] else { continue }

				for value in values {
					errorMessages.append("\(key.capitalized) \(value).")
				}
			}
		}

		guard !errorMessages.isEmpty else { return nil }

		return errorMessages.joined(separator: " ")
	}
}
