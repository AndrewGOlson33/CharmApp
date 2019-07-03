//
//  Subscription.swift
//  Charm
//
//  Created by Daniel Pratt on 4/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import Foundation
import StoreKit

private var formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.formatterBehavior = .behavior10_4
    
    return formatter
}()

struct Subscription {
    let product: SKProduct
    let formattedPrice: String
    
    var priceDetail: String {
        return formattedPrice + "/Month"
    }
    
    init(product: SKProduct) {
        self.product = product
        
        if formatter.locale != self.product.priceLocale {
            formatter.locale = self.product.priceLocale
        }
        
        formattedPrice = formatter.string(from: product.price) ?? "\(product.price)"
    }
}
