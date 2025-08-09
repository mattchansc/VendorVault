//
//  FirebaseService.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    
    // Published properties
    @Published var portfolios: [Portfolio] = []
    @Published var cards: [PokemonCard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Current user and portfolio
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    private var currentPortfolioId: String?
    
    // MARK: - User Aggregates (users/<uid> doc)
    private func ensureUserAggregateDocExists() async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        let docRef = db.collection("users").document(userId)
        let snapshot = try await docRef.getDocument()
        if !snapshot.exists {
            try await docRef.setData([
                "Total Card Cost": 0.0,
                "Total Revenue": 0.0,
                "Cost": 0.0
            ])
        }
    }
    
    // MARK: - Card completeness helper
    private func computeIsComplete(card: PokemonCard, numericSetNumber: Int) -> Bool {
        let requiredStrings: [String] = [
            card.cardName,
            card.pokemonName,
            card.setName,
            card.setNumber,
            card.condition,
            card.language,
            card.itemType
        ]
        let stringsOk = requiredStrings.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let setNumberOk = numericSetNumber > 0
        // acquisitionPrice and dateAdded are always present in model; treat them as complete
        return stringsOk && setNumberOk
    }
    
    // MARK: - Portfolio Management
    
    func createDefaultPortfolio() async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔄 Creating default portfolio for user: \(userId)")
        
        let defaultPortfolio = Portfolio.createFromForm(
            name: "Pokemon Cards",
            description: "My Pokemon card collection",
            type: "Pokemon"
        )
        
        do {
            let docRef = try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .addDocument(from: defaultPortfolio)
            
            print("✅ Successfully created default portfolio with ID: \(docRef.documentID)")
            
            await MainActor.run {
                self.currentPortfolioId = docRef.documentID
                
                // Add the new portfolio to the local array
                var updatedPortfolio = defaultPortfolio
                updatedPortfolio.id = docRef.documentID
                self.portfolios.insert(updatedPortfolio, at: 0)
            }
            
            print("🎯 Default portfolio created and set as current")
        } catch {
            print("❌ Failed to create default portfolio: \(error.localizedDescription)")
            throw error
        }
    }
    
    func selectPortfolio(_ portfolioId: String) async {
        print("🔄 Selecting portfolio: \(portfolioId)")
        await MainActor.run {
            self.currentPortfolioId = portfolioId
        }
    }
    
    func createPortfolio(_ portfolio: Portfolio) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔄 Creating portfolio: \(portfolio.name) for user: \(userId)")
        
        do {
            let docRef = try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .addDocument(from: portfolio)
            
            print("✅ Successfully created portfolio with ID: \(docRef.documentID)")
            
            await MainActor.run {
                // Add the new portfolio to the local array
                var updatedPortfolio = portfolio
                updatedPortfolio.id = docRef.documentID
                self.portfolios.insert(updatedPortfolio, at: 0)
                
                // Set as current portfolio
                self.currentPortfolioId = docRef.documentID
            }
            
            print("🎯 Portfolio created and set as current")
        } catch {
            print("❌ Failed to create portfolio: \(error.localizedDescription)")
            throw error
        }
    }
    
    func loadPortfolios() async {
        guard let userId = currentUserId else {
            await MainActor.run {
                self.portfolios = []
                self.isLoading = false
            }
            return
        }
        
        print("🔍 Loading portfolios for user ID: \(userId)")
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .order(by: "createdAt", descending: true)
                .limit(to: 1) // Only get the first portfolio
                .getDocuments()
            
            let loadedPortfolios = snapshot.documents.compactMap { document in
                try? document.data(as: Portfolio.self)
            }
            
            print("📄 Found \(loadedPortfolios.count) portfolios")
            
            await MainActor.run {
                self.portfolios = loadedPortfolios
                self.isLoading = false
                
                // If no portfolios exist, create a default one
                if loadedPortfolios.isEmpty {
                    print("📝 No portfolios found, creating default portfolio")
                    Task {
                        try await self.createDefaultPortfolio()
                    }
                } else {
                    // Set current portfolio to the first (and only) one
                    if let firstPortfolio = loadedPortfolios.first {
                        self.currentPortfolioId = firstPortfolio.id
                        print("🎯 Set current portfolio to: \(firstPortfolio.name)")
                    }
                    
                    // Clean up any duplicate portfolios
                    if loadedPortfolios.count > 1 {
                        print("⚠️ Found multiple portfolios, cleaning up duplicates")
                        Task {
                            await self.cleanupDuplicatePortfolios()
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to load portfolios: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load portfolios: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Card Management
    
    func saveCard(_ card: PokemonCard) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Ensure required user aggregate doc exists for the requested schema
        try await ensureUserAggregateDocExists()
        
        print("💾 Saving card (no portfolio): \(card.cardName)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Convert setNumber to numeric to match schema and write directly to users/<uid>/cards
            let numericSetNumber: Int = {
                let digits = card.setNumber.filter { $0.isNumber }
                return Int(digits) ?? 0
            }()
            
            let isComplete = computeIsComplete(card: card, numericSetNumber: numericSetNumber)
            
            let cardData: [String: Any] = [
                "acquisitionPrice": card.acquisitionPrice,
                "cardName": card.cardName,
                "Condition": card.condition,
                "dateAdded": Timestamp(date: card.dateAdded),
                "itemType": card.itemType,
                "Language": card.language,
                "pokemonName": card.pokemonName,
                "setName": card.setName,
                "setNumber": numericSetNumber,
                "isComplete": isComplete
            ]
            
            let docRef = try await db.collection("users")
                .document(userId)
                .collection("cards")
                .addDocument(data: cardData)
            
            // Update user aggregates
            try await db.collection("users").document(userId).setData([
                "Total Card Cost": FieldValue.increment(card.acquisitionPrice),
                "Cost": FieldValue.increment(card.acquisitionPrice)
            ], merge: true)
            
            print("✅ Successfully saved card with ID: \(docRef.documentID)")
            
            await loadCards() // Refresh the list
        } catch {
            print("❌ Failed to save card: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to save card: \(error.localizedDescription)"
            }
            throw error
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Portfolio Cleanup
    
    func cleanupDuplicatePortfolios() async {
        guard let userId = currentUserId else { return }
        
        print("🧹 Cleaning up duplicate portfolios for user: \(userId)")
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let portfolios = snapshot.documents.compactMap { document in
                try? document.data(as: Portfolio.self)
            }
            
            print("📄 Found \(portfolios.count) portfolios")
            
            // If we have more than one portfolio, keep only the first one
            if portfolios.count > 1 {
                print("⚠️ Found multiple portfolios, keeping only the first one")
                
                // Keep the first portfolio (most recent)
                let portfolioToKeep = portfolios.first!
                
                // Delete all other portfolios
                for portfolio in portfolios.dropFirst() {
                    if let portfolioId = portfolio.id {
                        print("🗑️ Deleting duplicate portfolio: \(portfolio.name) (\(portfolioId))")
                        
                        // Delete the portfolio document (this will also delete all cards in it)
                        try await db.collection("users")
                            .document(userId)
                            .collection("portfolios")
                            .document(portfolioId)
                            .delete()
                    }
                }
                
                // Update local state
                await MainActor.run {
                    self.portfolios = [portfolioToKeep]
                    self.currentPortfolioId = portfolioToKeep.id
                }
                
                print("✅ Portfolio cleanup completed")
            }
        } catch {
            print("❌ Failed to cleanup portfolios: \(error.localizedDescription)")
        }
    }
    
    func loadCards() async {
        guard let userId = currentUserId else {
            await MainActor.run {
                self.cards = []
                self.isLoading = false
            }
            return
        }
        
        print("🔍 Loading cards for user ID: \(userId) (no portfolio)")
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("cards")
                .order(by: "dateAdded", descending: true)
                .getDocuments()
            
            let loadedCards: [PokemonCard] = snapshot.documents.compactMap { document in
                let data = document.data()
                let acquisitionPrice = data["acquisitionPrice"] as? Double ?? 0.0
                let cardName = data["cardName"] as? String ?? ""
                let condition = data["Condition"] as? String ?? ""
                let timestamp = data["dateAdded"] as? Timestamp ?? Timestamp(date: Date())
                let itemType = data["itemType"] as? String ?? ""
                let language = data["Language"] as? String ?? ""
                let pokemonName = data["pokemonName"] as? String ?? ""
                let setName = data["setName"] as? String ?? ""
                let setNumberNumeric = data["setNumber"] as? Int ?? 0
                let setNumber = String(setNumberNumeric)
                let _ = data["isComplete"] as? Bool ?? false
                
                var card = PokemonCard(
                    cardName: cardName,
                    pokemonName: pokemonName,
                    setName: setName,
                    setNumber: setNumber,
                    condition: condition,
                    language: language,
                    itemType: itemType,
                    acquisitionPrice: acquisitionPrice,
                    dateAdded: timestamp.dateValue(),
                    cardImageURL: nil
                )
                card.id = document.documentID
                return card
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
    
    func deleteCard(_ card: PokemonCard) async throws {
        guard let userId = currentUserId,
              let cardId = card.id else {
            print("❌ Error: Missing user ID or card ID")
            throw NSError(domain: "CardError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required IDs"])
        }
        
        print("🗑️ Attempting to delete card with ID: \(cardId) (no portfolio)")
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("cards")
                .document(cardId)
                .delete()
            
            await MainActor.run {
                self.cards.removeAll { $0.id == cardId }
            }
        } catch {
            print("❌ Failed to delete card: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateCard(_ card: PokemonCard) async throws {
        guard let userId = currentUserId,
              let cardId = card.id else {
            return
        }
        
        // Maintain numeric setNumber in Firestore
        let numericSetNumber: Int = {
            let digits = card.setNumber.filter { $0.isNumber }
            return Int(digits) ?? 0
        }()
        
        let isComplete = computeIsComplete(card: card, numericSetNumber: numericSetNumber)
        
        let cardData: [String: Any] = [
            "acquisitionPrice": card.acquisitionPrice,
            "cardName": card.cardName,
            "Condition": card.condition,
            "dateAdded": Timestamp(date: card.dateAdded),
            "itemType": card.itemType,
            "Language": card.language,
            "pokemonName": card.pokemonName,
            "setName": card.setName,
            "setNumber": numericSetNumber,
            "isComplete": isComplete
        ]
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("cards")
                .document(cardId)
                .setData(cardData, merge: true)
            
            await loadCards()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update card: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func searchCards(query: String) async {
        guard let userId = currentUserId else {
            await MainActor.run {
                self.cards = []
                self.isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("cards")
                .whereField("pokemonName", isGreaterThanOrEqualTo: query)
                .whereField("pokemonName", isLessThan: query + "\u{f8ff}")
                .getDocuments()
            
            let searchedCards: [PokemonCard] = snapshot.documents.compactMap { document in
                let data = document.data()
                let acquisitionPrice = data["acquisitionPrice"] as? Double ?? 0.0
                let cardName = data["cardName"] as? String ?? ""
                let condition = data["Condition"] as? String ?? ""
                let timestamp = data["dateAdded"] as? Timestamp ?? Timestamp(date: Date())
                let itemType = data["itemType"] as? String ?? ""
                let language = data["Language"] as? String ?? ""
                let pokemonName = data["pokemonName"] as? String ?? ""
                let setName = data["setName"] as? String ?? ""
                let setNumberNumeric = data["setNumber"] as? Int ?? 0
                let setNumber = String(setNumberNumeric)
                let _ = data["isComplete"] as? Bool ?? false
                
                var card = PokemonCard(
                    cardName: cardName,
                    pokemonName: pokemonName,
                    setName: setName,
                    setNumber: setNumber,
                    condition: condition,
                    language: language,
                    itemType: itemType,
                    acquisitionPrice: acquisitionPrice,
                    dateAdded: timestamp.dateValue(),
                    cardImageURL: nil
                )
                card.id = document.documentID
                return card
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
    
    // MARK: - Portfolio Selection
    
    func selectPortfolio(_ portfolio: Portfolio) {
        currentPortfolioId = portfolio.id
        print("🎯 Selected portfolio: \(portfolio.name)")
        
        // Load cards for the selected portfolio
        Task {
            await loadCards()
        }
    }
} 