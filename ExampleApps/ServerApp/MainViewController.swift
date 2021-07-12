//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import Web3
import WalletConnectSwift

class MainViewController: UIViewController {
    @IBOutlet weak var walletAddressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var scanQRCodeButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!

    var scannerController: ScannerViewController?

    var service: CryptoConnectService!

    override func viewDidLoad() {
        super.viewDidLoad()
        service = CryptoConnectService.shared
        service.register(PersonalSign(), for: self)
        service.register(SignTransaction(), for: self)
        service.register(SendTransaction(), for: self)

        walletAddressLabel.text = service.walletAddressHexString
        statusLabel.text = "Disconnected"

        service.shouldStartSession = { [weak self] session, completion in
            guard let self = self else { return }

            let walletMeta = Session.ClientMeta(name: "Test Wallet", description: nil, icons: [], url: URL(string: "https://safe.gnosis.io")!)
            let walletInfo = Session.WalletInfo(approved: true, accounts: [self.service.walletAddressHexString], chainId: 4, peerId: UUID().uuidString, peerMeta: walletMeta)

            onMainThread {
                UIAlertController.showShouldStart(from: self, clientName: session.dAppInfo.peerMeta.name, onStart: {
                    completion(walletInfo)
                }, onClose: {
                    completion(Session.WalletInfo(approved: false, accounts: [], chainId: 4, peerId: "", peerMeta: walletMeta))
                    self.scanQRCodeButton.isEnabled = true
                })
            }
        }

        service.didDisconnectSession = { _ in
            onMainThread {
                self.scanQRCodeButton.isEnabled = true
                self.scanQRCodeButton.isHidden = false
                self.disconnectButton.isHidden = true
                self.statusLabel.text = "Disconnected"
            }
        }

        service.didConnectSession = { session in
            onMainThread {
                self.scanQRCodeButton.isHidden = true
                self.disconnectButton.isHidden = false
                self.statusLabel.text = "Connected to \(session.dAppInfo.peerMeta.name)"
            }
        }

        service.didFailToConnectURL = { _ in
            onMainThread {
                UIAlertController.showFailedToConnect(from: self)
            }
        }
    }

    @IBAction func scan(_ sender: Any) {
        scannerController = ScannerViewController.create(delegate: self)
        present(scannerController!, animated: true)
    }

    @IBAction func disconnect(_ sender: Any) {
        service.disconnect()
    }
}

extension MainViewController: ScannerViewControllerDelegate {
    func didScan(_ code: String) {
        service.connect(to: code)

        //scanQRCodeButton.isEnabled = false
        scannerController?.dismiss(animated: true)
    }
}
