//
//  APIClient.swift
//  CanvasKit
//
//  Created by Sam Soffes on 11/2/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation

open class APIClient: NetworkClient {
	
	// MARK: - Types

	enum Method: String {
		case GET
		case HEAD
		case POST
		case PUT
		case DELETE
		case TRACE
		case OPTIONS
		case CONNECT
		case PATCH
	}
	
	
	// MARK: - Properties

	open let accessToken: String
	open let baseURL: URL
	open let session: URLSession

	
	// MARK: - Initializers
	
	public init(accessToken: String, baseURL: URL = CanvasKit.baseURL as URL, session: URLSession = URLSession.shared) {
		self.accessToken = accessToken
		self.baseURL = baseURL
		self.session = session
	}


	// MARK: - Requests

	open func shouldComplete<T>(_ request: URLRequest, response: HTTPURLResponse?, data: Data?, error: NSError?, completion: ((Result<T>) -> Void)?) -> Bool {
		if let error = error {
			networkCompletionQueue.async {
				completion?(.failure(error.localizedFailureReason ?? "Error"))
			}
			return false
		}

		return true
	}


	// MARK: - Projects

	/// List projects.
	///
	/// - parameter completion: A function to call when the request finishes.
	open func listProjects(_ completion: @escaping (Result<[Project]>) -> Void) {
		request(path: "projects", completion: completion)
	}

	// MARK: - Canvases

	/// Show a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	open func showCanvas(_ id: String, completion: @escaping (Result<Canvas>) -> Void) {
		request(path: "canvases/\(id)", parameters: ["include": "project" as AnyObject], completion: completion)
	}

	/// Create a canvas.
	///
	/// - parameter projectID: The ID of the project to own the created canvas.
	/// - parameter content: Optional content formatted as CanvasNative for the new canvas.
	/// - parameter isPublicWritable: Boolean indicating if the new canvas should be publicly writable.
	/// - parameter completion: A function to call when the request finishes.
	open func createCanvas(_ projectID: String, content: String? = nil, isPublicWritable: Bool? = nil, completion: @escaping (Result<Canvas>) -> Void) {
		var attributes = JSONDictionary()

		if let content = content {
			attributes["native_content"] = content as AnyObject
		}

		if let isPublicWritable = isPublicWritable {
			attributes["is_public_writable"] = isPublicWritable as AnyObject
		}

		let params = [
			"data": [
				"type": "canvases",
				"attributes": attributes,
				"relationships": [
					"project": [
						"data": [
							"type": "projects",
							"id": projectID
						]
					]
				]
			],
			"include": "project"
		] as [String : Any]

		request(.POST, path: "canvases", parameters: params as JSONDictionary, completion: completion)
	}

	/// List canvases.
	///
	/// - parameter projectID: Limit the results to a given project.
	/// - parameter completion: A function to call when the request finishes.
	open func listCanvases(_ projectID: String? = nil, completion: @escaping (Result<[Canvas]>) -> Void) {
		var params: JSONDictionary = [
			"include": "project" as AnyObject
		]

		if let projectID = projectID {
			params["filter[org.id]"] = projectID as AnyObject
		}

		request(path: "canvases", parameters: params, completion: completion)
	}

	/// Search for canvases in an project.
	///
	/// - parameter projectID: The project ID.
	/// - parameter query: The search query.
	/// - parameter completion: A function to call when the request finishes.
	open func searchCanvases(_ projectID: String, query: String, completion: @escaping (Result<[Canvas]>) -> Void) {
		let params = [
			"query": query,
			"include": "project"
		]
		request(path: "orgs/\(projectID)/actions/search", parameters: params as JSONDictionary, completion: completion)
	}

	/// Destroy a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	open func destroyCanvas(_ id: String, completion: ((Result<Void>) -> Void)? = nil) {
		request(.DELETE, path: "canvases/\(id)", completion: completion)
	}

	/// Archive a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	open func archiveCanvas(_ id: String, completion: ((Result<Canvas>) -> Void)? = nil) {
		canvasAction("archive", id: id, completion: completion)
	}

	/// Unarchive a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	open func unarchiveCanvas(_ id: String, completion: ((Result<Canvas>) -> Void)? = nil) {
		canvasAction("unarchive", id: id, completion: completion)
	}

	/// Change public edits setting for a canvas.
	///
	/// - parameter id: The canvas ID.
	/// - parameter completion: A function to call when the request finishes.
	open func changePublicEdits(_ id: String, enabled: Bool, completion: ((Result<Canvas>) -> Void)? = nil) {
        
        let attrs: [String:AnyObject] = [ "is_public_writable": enabled as AnyObject]
        let d: [String: AnyObject] = [
            "attributes": attrs as AnyObject
        ]
        let params: JSONDictionary = [
			"data": d as AnyObject,
            "include": "project" as AnyObject
        ]
		request(.PATCH, path: "canvases/\(id)", parameters: params, completion: completion)
	}

	
	// MARK: - Private

	fileprivate func request(_ method: Method = .GET, path: String, parameters: JSONDictionary? = nil, contentType: String = "application/json; charset=utf-8", completion: ((Result<Void>) -> Void)?) {
		let request = buildRequest(method, path: path, parameters: parameters, contentType: contentType)
		sendRequest(request as URLRequest, completion: completion) { _, response, _ in
			print("response: \(String(describing: response))")
			guard let completion = completion else { return }
			networkCompletionQueue.async {
				completion(.success(()))
			}
		}
	}

	fileprivate func request<T: Resource>(_ method: Method = .GET, path: String, parameters: JSONDictionary? = nil, contentType: String = "application/json; charset=utf-8", completion: ((Result<[T]>) -> Void)?) {
		let request = buildRequest(method, path: path, parameters: parameters, contentType: contentType)
		sendRequest(request as URLRequest, completion: completion) { data, _, _ in
			guard let completion = completion else { return }
			guard let data = data,
				let json = try? JSONSerialization.jsonObject(with: data, options: []),
				let dictionary = json as? JSONDictionary
			else {
				networkCompletionQueue.async {
					completion(.failure("Invalid response"))
				}
				return
			}

			guard let values = ResourceSerialization.deserialize(dictionary: dictionary) as [T]? else {
				let errors = (dictionary["errors"] as? [JSONDictionary])?.flatMap { $0["detail"] as? String }
				let error = errors?.joined(separator: " ")

				networkCompletionQueue.async {
					completion(.failure(error ?? "Invalid response"))
				}
				return
			}

			networkCompletionQueue.async {
				completion(.success(values))
			}
		}
	}

	fileprivate func request<T: Resource>(_ method: Method = .GET, path: String, parameters: JSONDictionary? = nil, contentType: String = "application/json; charset=utf-8", completion: ((Result<T>) -> Void)?) {
		let request = buildRequest(method, path: path, parameters: parameters, contentType: contentType)
		sendRequest(request as URLRequest, completion: completion) { data, _, _ in
			guard let completion = completion else { return }
			guard let data = data,
				let json = try? JSONSerialization.jsonObject(with: data, options: []),
				let dictionary = json as? JSONDictionary
				else {
					networkCompletionQueue.async {
						completion(.failure("Invalid response"))
					}
					return
			}

			guard let value = ResourceSerialization.deserialize(dictionary: dictionary) as T? else {
				let errors = (dictionary["errors"] as? [JSONDictionary])?.flatMap { $0["detail"] as? String }
				let error = errors?.joined(separator: " ")

				networkCompletionQueue.async {
					completion(.failure(error ?? "Invalid response"))
				}
				return
			}

			networkCompletionQueue.async {
				completion(.success(value))
			}
		}
	}
	
	fileprivate func buildRequest(_ method: Method = .GET, path: String, parameters: JSONDictionary? = nil, contentType: String = "application/json; charset=utf-8") -> NSMutableURLRequest {
		// Create URL
		var url = baseURL.appendingPathComponent(path)

		// Add GET params
		if method == .GET {
			if let parameters = parameters, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
				var queryItems = [URLQueryItem]()
				for (name, value) in parameters {
					if let value = value as? String {
						queryItems.append(URLQueryItem(name: name, value: value))
					} else {
						print("[APIClient] Failed to GET encode a non string value: `\(value)`")
					}
				}
				components.queryItems = queryItems

				if let updatedURL = components.url {
					url = updatedURL
				}
			}
		}

		// Create request
		let request = NSMutableURLRequest(url: url)

		// Set HTTP method
		request.httpMethod = method.rawValue

		// Add content type
		request.setValue(contentType, forHTTPHeaderField: "Content-Type")

		// Add POST params
		if let parameters = parameters, method != .GET {
			request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
		}

		// Accept JSON
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

		// Add access token
		request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		
		return request
	}

	fileprivate func sendRequest<T>(_ request: URLRequest, completion: ((Result<T>) -> Void)?, callback: @escaping (_ data: Data?, _ response: HTTPURLResponse?, _ error: NSError?) -> Void) {
		session.dataTask(with: request, completionHandler: { data, res, error in
			let response = res as? HTTPURLResponse

			// We strongly capture self here on purpose so the client will last at least long enough for the
			// `shouldComplete` method to get called.
			guard self.shouldComplete(request, response: response, data: data, error: (error! as NSError), completion: completion) else { return }
			
			callback(data, response, error! as NSError)
		}) .resume()
	}

	fileprivate func canvasAction(_ name: String, id: String, completion: ((Result<Canvas>) -> Void)?) {
		let path = "canvases/\(id)/actions/\(name)"
		let params = ["include": "project"]
		request(.POST, path: path, parameters: params as JSONDictionary, completion: completion)
	}
}
