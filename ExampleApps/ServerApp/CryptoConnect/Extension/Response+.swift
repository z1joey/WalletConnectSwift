//
//  Response+.swift
//  ServerApp
//
//  Created by Joey.Zhang@crypto.com on 2021/7/12.
//  Copyright © 2021 Gnosis. All rights reserved.
//

import WalletConnectSwift

// MARK: - Response
extension Response {
    static func signature<T: Encodable>(_ request: Request, signature: T) -> Response {
        return try! Response(url: request.url, value: signature, id: request.id!)
    }

    static func approve<T: Encodable>(_ request: Request, value: T) -> Response {
        return try! Response(url: request.url, value: value, id: request.id!)
    }
}
