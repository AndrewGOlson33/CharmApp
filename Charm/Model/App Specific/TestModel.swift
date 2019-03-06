//
//  TestModel.swift
//  Charm
//
//  Created by Daniel Pratt on 3/6/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import CodableFirebase

struct User: Codable {
    
    let age: Int
    let job: String
    let name: String
    
}
