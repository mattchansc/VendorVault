//
//  FirebaseService.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let collectionName = "pokemonCards"
    
    @Published var cards: [PokemonCard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Save Card
    func saveCard(_ card: PokemonCard) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await db.collection(collectionName).addDocument(from: card)
            await loadCards() // Refresh the list
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save card: \(error.localizedDescription)"
            }
            throw error
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Load Cards
    func loadCards() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection(collectionName)
                .order(by: "dateAdded", descending: true)
                .getDocuments()
            
            let loadedCards = snapshot.documents.compactMap { document in
                try? document.data(as: PokemonCard.self)
            }
            
            await MainActor.run {
                self.cards = loadedCards
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load cards: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Delete Card
    func deleteCard(_ card: PokemonCard) async throws {
        guard let id = card.id else { 
            print("Error: Card ID is nil")
            throw NSError(domain: "CardError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Card ID is missing"])
        }
        
        print("Attempting to delete card with ID: \(id)")
        
        do {
            // Delete from Firebase first
            try await db.collection(collectionName).document(id).delete()
            print("Successfully deleted card from Firebase")
            
            // Then remove from local array
            await MainActor.run {
                let initialCount = self.cards.count
                self.cards.removeAll { $0.id == id }
                let finalCount = self.cards.count
                print("Removed card from local array. Count: \(initialCount) -> \(finalCount)")
            }
            
        } catch {
            print("Firebase delete error: \(error)")
            await MainActor.run {
                errorMessage = "Failed to delete card: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Update Card
    func updateCard(_ card: PokemonCard) async throws {
        guard let id = card.id else { return }
        
        do {
            try await db.collection(collectionName).document(id).setData(from: card)
            await loadCards() // Refresh the list
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update card: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Search Cards
    func searchCards(query: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection(collectionName)
                .whereField("pokemonName", isGreaterThanOrEqualTo: query)
                .whereField("pokemonName", isLessThan: query + "\u{f8ff}")
                .getDocuments()
            
            let searchedCards = snapshot.documents.compactMap { document in
                try? document.data(as: PokemonCard.self)
            }
            
            await MainActor.run {
                self.cards = searchedCards
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to search cards: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
} 