//
//  CardModel.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import Foundation
import FirebaseFirestore

struct PokemonCard: Identifiable, Codable {
    @DocumentID var id: String?
    let cardName: String
    let pokemonName: String
    let setName: String
    let setNumber: String
    let condition: String
    let language: String
    let itemType: String
    let acquisitionPrice: Double
    let dateAdded: Date
    let cardImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardName
        case pokemonName
        case setName
        case setNumber
        case condition
        case language
        case itemType
        case acquisitionPrice
        case dateAdded
        case cardImageURL
    }
}

// Extension to create a card from form data
extension PokemonCard {
    static func createFromForm(
        cardName: String,
        pokemonName: String,
        setName: String,
        setNumber: String,
        condition: String,
        language: String,
        itemType: String,
        acquisitionPrice: String,
        cardImageURL: String? = nil
    ) -> PokemonCard? {
        guard let price = Double(acquisitionPrice) else { return nil }
        
        return PokemonCard(
            cardName: cardName,
            pokemonName: pokemonName,
            setName: setName,
            setNumber: setNumber,
            condition: condition,
            language: language,
            itemType: itemType,
            acquisitionPrice: price,
            dateAdded: Date(),
            cardImageURL: cardImageURL
        )
    }
} 