//
//  CryptoConnectService.swift
//  ServerApp
//
//  Created by Joey.Zhang@crypto.com on 2021/7/8.
//  Copyright © 2021 Gnosis. All rights reserved.
//

import UIKit
import Web3
import WalletConnectSwift

public final class CryptoConnectService {
    static var shared = CryptoConnectService()

    private var session: Session!
    private let sessionKey = "sessionKey"

    private var server: Server!
    private var privateKey: EthereumPrivateKey!

    /// failed to connect to WCURL
    public var didFailToConnectURL  : ((WCURL) -> Void)?

    /// to start a session, pass Session.WalletInfo as parameter to the closure
    public var shouldStartSession   : ((Session, @escaping (Session.WalletInfo) -> Void) -> Void)?

    /// connected to a session
    public var didConnectSession    : ((Session) -> Void)?

    /// disconnected from a session
    public var didDisconnectSession : ((Session) -> Void)?

    public var walletAddressHexString: String {
        return privateKey.address.hex(eip55: true)
    }

    public weak var delegate: ServerDelegate? {
        get {
            return server.delegate
        }
    }

    init() {
        server = Server(delegate: self)      
        privateKey = try! EthereumPrivateKey(
            privateKey: .init(hex: "BD9F406A928238E9500E4C7276F77E6D15118D62CC6B65B5A39C442BE6F1262F"))
    }

    func sign(_ message: Bytes) -> (v: UInt, r: Bytes, s: Bytes) {
        return try! privateKey.sign(message: message)
    }

    func sign(_ transaction: EthereumTransaction) -> EthereumSignedTransaction {
        return try! transaction.sign(with: privateKey, chainId: 1)
    }

    func register(_ handler: CCRequestHandler, for viewController: UIViewController) {
        handler.service = self
        handler.controller = viewController
        server.register(handler: handler)
    }

    func unregister(handler: CCRequestHandler) {
        handler.service = nil
        handler.controller = nil
        server.unregister(handler: handler)
    }

    func connect(to code: String) {
        if let url = WCURL(code) {
            try? server.connect(to: url)
        }
    }

    func reconnect() {
        if let oldSessionObject = UserDefaults.standard.object(forKey: sessionKey) as? Data,
           let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
            try? server.reconnect(to: session)
        }
    }

    func disconnect() {
        try? server.disconnect(from: session)
    }

    func send(_ response: Response) {
        server.send(response)
    }

    func cancel(_ request: Request) {
        server.send(.reject(request))
    }

    func invalid(_ request: Request) {
        server.send(.invalid(request))
    }
}

extension CryptoConnectService: ServerDelegate {
    public func server(_ server: Server, didFailToConnect url: WCURL) {
        didFailToConnectURL?(url)
    }

    public func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        shouldStartSession?(session, completion)
    }

    public func server(_ server: Server, didConnect session: Session) {
        print("didConnect")
        self.session = session
        let sessionData = try! JSONEncoder().encode(session)
        UserDefaults.standard.set(sessionData, forKey: sessionKey)

        didConnectSession?(session)
    }

    public func server(_ server: Server, didDisconnect session: Session) {
        UserDefaults.standard.removeObject(forKey: sessionKey)

        didDisconnectSession?(session)
    }
}
