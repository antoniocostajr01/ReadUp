//
//  BookCover.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//

import Foundation
import SwiftUI

enum BookCover: String, CaseIterable{
    case rodrick = "RodrickEOCara"
    case milAoMilhao = "DoMilAoMilhao"
    case _1984 = "1984"
    case hobbit = "OHobbit"
    
    var image: Image {
        Image(self.rawValue)
    }
}
