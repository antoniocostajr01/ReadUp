//
//  File.swift
//  ReadUp
//
//  Created by Antonio Costa on 26/05/26.
//

import Foundation
import Playgrounds
import FoundationModels

#Playground {
    let session = LanguageModelSession()
    let prompt = "What are the colors of the rainbow?"
    

    let response = try await session.respond(to: prompt)
    
    
}
