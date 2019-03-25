//
//  Extensions.swift
//  Charm
//
//  Created by Daniel Pratt on 3/25/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    // Return the same string, but with the first letter capitalized
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        
        var result = self
        
        let substr1 = String(self[startIndex]).uppercased()
        result.replaceSubrange(...startIndex, with: substr1)
        
        return result
    }
    
}
