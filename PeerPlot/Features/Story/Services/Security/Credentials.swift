//
//  Credentials.swift
//  PeerPlot
//
//  Created by Ravi Shankar on 10/04/25.
//

import Foundation

/// Provides security credentials for P2P connections
/// Note: This implementation is for demonstration purposes only
class Credentials {
    
    /// Asynchronously provides identity and CA certificate
    /// - Parameter async: Callback that receives the identity and CA certificate
    static func async(_ async: @escaping (SecIdentity, SecCertificate) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            async(identity, ca)
        }
    }
    
    // NOTE: To simplify the demo this pulls the client identity from a file
    // embedded in the app. In a realworld use-case the identity would likely
    // be managed using Keychain Services.
    private static let identity: SecIdentity = {
        guard let url = Bundle.main.url(forResource: "client_identity",
                                     withExtension: "p12") else {
            fatalError("Missing client identity certificate in bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            var result: CFArray?
            let options: [String: Any] = [kSecImportExportPassphrase as String: ""]
            // NOTE: This method cannot be called on the main thread. That is why
            // the get function is async.
            let status = SecPKCS12Import(data as CFData, options as NSDictionary, &result)
            let items = result as! [[String: Any]]
            let item = items.first!
            let identity = item[kSecImportItemIdentity as String] as! SecIdentity
            
            return identity
        } catch {
            fatalError("Failed to load certificate: \(error)")
        }
    }()
    
    private static let ca: SecCertificate = {
        guard let url = Bundle.main.url(forResource: "ca_cert", withExtension: "der") else {
            fatalError("Missing CA certificate in bundle")
        }
        
        do {
            let data = try Data(contentsOf: url)
            guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
                fatalError("Failed to create certificate from data")
            }
            return certificate
        } catch {
            fatalError("Failed to load CA certificate: \(error)")
        }
    }()
}
