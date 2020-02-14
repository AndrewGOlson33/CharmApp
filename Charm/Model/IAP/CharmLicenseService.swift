//
//  CharmLicenseService.swift
//  Charm
//
//  Created by Daniel Pratt on 4/19/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

private let itcAccountSecret = "9208ee7185234a4cb966f1e8c27a6f21"

import Foundation

public enum Result<T> {
    case failure(CharmServiceError)
    case success(T)
}

func isDevelopmentEnvironment() -> Bool {
    guard let filePath = Bundle.main.path(forResource: "embedded", ofType:"mobileprovision") else {
        return false
    }
    do {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .ascii) else {
            return false
        }
        if string.contains("<key>aps-environment</key>\n\t\t<string>development</string>") {
            return true
        }
    } catch let error {
        print("~>There was an error: \(error)")
    }
    return false
}

public typealias LoadCompleted = (_ subscriptions: Result<Int> ) -> Void
public typealias UploadReceiptCompletion = (_ result: Result<(sessionId: String, currentSubscription: PaidSubscription?)>) -> Void

public typealias SessionId = String

public enum CharmServiceError: Error {
    case missingAccountSecret
    case invalidSession
    case noActiveSubscription
    case other(Error)
}

public class CharmService {
    
    public static let shared = CharmService()
    let simulatedStartDate: Date
    
    private var sessions = [SessionId: Session]()
    
    init() {
        let persistedDateKey = "_CharmLicenseStartDate"
        if let persistedDate = UserDefaults.standard.object(forKey: persistedDateKey) as? Date {
            simulatedStartDate = persistedDate
        } else {
            let date = Date().addingTimeInterval(-30) // 30 second difference to account for server/client drift.
            UserDefaults.standard.set(date, forKey: "_CharmLicenseStartDate")
            
            simulatedStartDate = date
        }
    }
    
    /// Trade receipt for session id
    public func upload(receipt data: Data, completion: @escaping UploadReceiptCompletion) {
        let body = [
            "receipt-data": data.base64EncodedString(),
            "password": itcAccountSecret
        ]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])
        
        let url = isDevelopmentEnvironment() ? URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")! : URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let error = error {
                completion(.failure(.other(error)))
            } else if let responseData = responseData {
                let json = try! JSONSerialization.jsonObject(with: responseData, options: []) as! Dictionary<String, Any>
                let session = Session(receiptData: data, parsedReceipt: json)
                self.sessions[session.id] = session
                let result = (sessionId: session.id, currentSubscription: session.currentSubscription)
                completion(.success(result))
            }
        }
        
        task.resume()
    }
    
    /// Use sessionId to get pro subscription
    public func paidSubscriptions(for sessionId: SessionId, completion: LoadCompleted?) {
        guard itcAccountSecret == "9208ee7185234a4cb966f1e8c27a6f21" else {
            completion?(.failure(.missingAccountSecret))
            return
        }
        
        guard let _ = sessions[sessionId] else {
            completion?(.failure(.invalidSession))
            return
        }
        
        let paidSubscriptions = paidSubcriptions(since: simulatedStartDate, for: sessionId)
        guard paidSubscriptions.count > 0 else {
            completion?(.failure(.noActiveSubscription))
            return
        }
        
        completion?(.success(1))
    }
    
    private func paidSubcriptions(since date: Date, for sessionId: SessionId) -> [PaidSubscription] {
        if let session = sessions[sessionId] {
            let subscriptions = session.paidSubscriptions.filter { $0.purchaseDate >= date }
            return subscriptions.sorted { $0.purchaseDate < $1.purchaseDate }
        } else {
            return []
        }
    }
}
