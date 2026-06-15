//
//  Localization+Genre.swift
//  ReadUp
//
//  Created by Antonio Costa on 14/06/26.
//

import Foundation

public extension Localization{
    
    
    enum Genre: LocalizationProtocol {
        case fantasy, scienceFiction, romance, mystery, thriller, horror, history, philosophy, poetry, biography, selfHelp, science, business, comics, design
        
        public var key: String.LocalizationValue {
            switch self {
            case .fantasy: "Fantasy"
            case .scienceFiction: "Science Fiction"
            case .romance: "Romance"
            case .mystery: "Mystery"
            case .thriller: "Thriller"
            case .horror: "Horror"
            case .history: "History"
            case .philosophy: "Philosophy"
            case .poetry: "Poetry"
            case .biography: "Biography"
            case .selfHelp: "Self-Help"
            case .science: "Science"
            case .business: "Business"
            case .comics: "Comics"
            case .design: "Design"
            }
        }
    }
}
