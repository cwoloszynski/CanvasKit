//
//  JSONSupport.swift
//  TeamCanvas
//
//  Created by Charlie Woloszynski on 6/27/17.
//  Copyright © 2017 Handheld Media, LLC. All rights reserved.
//

import Foundation

protocol JSONRepresentable {
    func toJSON() -> JSONDictionary?
}

