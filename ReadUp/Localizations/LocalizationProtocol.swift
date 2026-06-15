//
//  LocalizationProtocol.swift
//  ReadUp
//

import SwiftUI

public protocol LocalizationProtocol {
    var key: String.LocalizationValue { get }
}

public extension LocalizationProtocol {
    var string: String {
        String(localized: key, bundle: .main)
    }
}
