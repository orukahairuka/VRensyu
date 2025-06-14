//
//  Utils.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/06/14.
//

import Foundation
import UIKit

extension UIDevice {
    static var persistentID: String {
        let key = "persistentUUID"
        if let uuid = UserDefaults.standard.string(forKey: key) {
            return uuid
        } else {
            let newUUID = UUID().uuidString
            UserDefaults.standard.set(newUUID, forKey: key)
            return newUUID
        }
    }
}
