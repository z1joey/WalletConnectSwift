//
//  CCRequest.swift
//  ServerApp
//
//  Created by Joey.Zhang@crypto.com on 2021/7/9.
//  Copyright © 2021 Gnosis. All rights reserved.
//

import UIKit
import Foundation
import WalletConnectSwift
import Web3

class CCRequestHandler: RequestHandler {
    weak var controller: UIViewController!
    weak var service: CryptoConnectService!

    func canHandle(request: Request) -> Bool {
        return false
    }

    // to override
    func handle(request: Request) {
        guard service != nil, controller != nil else {
            fatalError("Handler has to be registered")
        }
    }

    fileprivate func sign(_ request: Request, sign: @escaping () -> String) {
        service?.send(.signature(request, signature: sign()))
    }

    fileprivate func approve(_ request: Request, value: @escaping () -> String) {
        service?.send(.approve(request, value: value()))
    }

    fileprivate func askToSign(_ request: Request, message: String, sign: @escaping () -> String) {
        let onSign   = { self.sign(request, sign: { return sign() }) }
        let onCancel = { self.service.cancel(request) }

        onMainThread {
            UIAlertController.showShouldSign(from: self.controller, title: "Request to sign a message", message: message, onSign: onSign, onCancel: onCancel)
        }
     }
}

// MARK: - personal_sign
class PersonalSign: CCRequestHandler {
    override func canHandle(request: Request) -> Bool {
        return request.method == "personal_sign"
    }

    override func handle(request: Request) {
        super.handle(request: request)

        do {
            let messageBytes = try request.parameter(of: String.self, at: 0)
            let address = try request.parameter(of: String.self, at: 1)

            guard address == self.service.walletAddressHexString else {
                self.service.cancel(request)
                return
            }

            let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes

            askToSign(request, message: decodedMessage) {
                let personalMessageData = self.personalMessageData(messageData: Data(hex: messageBytes))
                let (v, r, s) = self.service.sign(.init(hex: personalMessageData.toHexString()))
                return "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16) // v in [0, 1]
            }
        } catch {
            self.service.send(.invalid(request))
        }
    }

    private func personalMessageData(messageData: Data) -> Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + String(messageData.count)).data(using: .ascii)!
        return prefixData + messageData
    }
}

// MARK: - eth_signTransaction
class SignTransaction: CCRequestHandler {
    override func canHandle(request: Request) -> Bool {
        return request.method == "eth_signTransaction"
    }

    override func handle(request: Request) {
        super.handle(request: request)

        do {
            let transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
            guard transaction.from?.hex(eip55: true) == self.service.walletAddressHexString else {
                self.service.cancel(request)
                return
            }

            askToSign(request, message: transaction.description) {
                let signedTx = self.service.sign(transaction)
                let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
                return r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
            }
        } catch {
            self.service.invalid(request)
        }
    }
}

// MARK: - eth_sendTransaction
class SendTransaction: CCRequestHandler {
    override func canHandle(request: Request) -> Bool {
        return request.method == "eth_sendTransaction"
    }

    override func handle(request: Request) {
        super.handle(request: request)

        do {
            let transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
            guard transaction.from?.hex(eip55: true) == self.service.walletAddressHexString else {
                self.service.cancel(request)
                return
            }

            let signedTx = self.service.sign(transaction)
            let web3 = Web3(rpcURL: "https://rpc-mainnet.matic.network")

            web3.eth.sendRawTransaction(transaction: signedTx) { [weak self] response in
                if let error = response.error {
                    print(error)
                    return
                }

                self?.askToSign(request, message: transaction.description) {
                    return (response.result?.hex())!
                }
            }
        } catch {
            self.service.invalid(request)
        }
    }
}

// MARK: - eth_sendTransaction
class GetTransactionNumber: CCRequestHandler {
    override func canHandle(request: Request) -> Bool {
        return request.method == "eth_getTransactionCount"
    }

    override func handle(request: Request) {
        super.handle(request: request)
        print(request.jsonString)
    }
}
