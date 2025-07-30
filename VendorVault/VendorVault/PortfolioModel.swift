//
//  PortfolioModel.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import Foundation
import FirebaseFirestore

struct Portfolio: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let type: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case type
        case createdAt
        case updatedAt
    }
}

// Extension to create a portfolio from form data
extension Portfolio {
    static func createFromForm(
        name: String,
        description: String,
        type: String
    ) -> Portfolio {
        let now = Date()
        return Portfolio(
            name: name,
            description: description,
            type: type,
            createdAt: now,
            updatedAt: now
        )
    }
} 