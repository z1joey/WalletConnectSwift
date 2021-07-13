//
//  EthereumTransaction+.swift
//  ServerApp
//
//  Created by Joey.Zhang@crypto.com on 2021/7/12.
//  Copyright © 2021 Gnosis. All rights reserved.
//

import Web3

extension EthereumTransaction {
    var description: String {
        return """
        to: \(String(describing: to?.hex(eip55: true))),
        value: \(String(describing: value?.hex())),
        gasPrice: \(String(describing: gasPrice?.hex())),
        gas: \(String(describing: gas?.hex())),
        data: \(data.hex()),
        nonce: \(String(describing: nonce?.hex()))
        """
    }
}
