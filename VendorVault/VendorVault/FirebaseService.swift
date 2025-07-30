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
        
        // Ensure we have a portfolio to work with
        if currentPortfolioId == nil {
            print("📝 No current portfolio, loading portfolios first")
            await loadPortfolios()
            
            // Wait a moment for portfolio loading/creation to complete
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        guard let portfolioId = currentPortfolioId else {
            print("❌ Still no portfolio available after loading")
            throw NSError(domain: "PortfolioError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No portfolio available"])
        }
        
        print("💾 Saving card: \(card.cardName) to portfolio: \(portfolioId)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            let docRef = try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .document(portfolioId)
                .collection("cards")
                .addDocument(from: card)
            
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
        
        // If no portfolio is selected, try to load portfolios first
        if currentPortfolioId == nil {
            print("📝 No portfolio selected, loading portfolios first")
            await loadPortfolios()
            
            // Wait a moment for the portfolio creation to complete
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        guard let portfolioId = currentPortfolioId else {
            print("❌ Still no portfolio available after loading")
            await MainActor.run {
                self.cards = []
                self.isLoading = false
            }
            return
        }
        
        print("🔍 Loading cards for user ID: \(userId), portfolio ID: \(portfolioId)")
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .document(portfolioId)
                .collection("cards")
                .order(by: "dateAdded", descending: true)
                .getDocuments()
            
            let loadedCards = snapshot.documents.compactMap { document in
                try? document.data(as: PokemonCard.self)
            }
            
            print("📄 Found \(loadedCards.count) cards in portfolio")
            
            await MainActor.run {
                self.cards = loadedCards
                self.isLoading = false
            }
        } catch {
            print("❌ Failed to load cards: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load cards: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func deleteCard(_ card: PokemonCard) async throws {
        guard let userId = currentUserId,
              let portfolioId = currentPortfolioId,
              let cardId = card.id else {
            print("❌ Error: Missing user ID, portfolio ID, or card ID")
            throw NSError(domain: "CardError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required IDs"])
        }
        
        print("🗑️ Attempting to delete card with ID: \(cardId)")
        
        do {
            // Delete from Firebase first
            try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .document(portfolioId)
                .collection("cards")
                .document(cardId)
                .delete()
            
            print("✅ Successfully deleted card from Firebase")
            
            // Then remove from local array
            await MainActor.run {
                let initialCount = self.cards.count
                self.cards.removeAll { $0.id == cardId }
                let finalCount = self.cards.count
                print("📊 Removed card from local array. Count: \(initialCount) -> \(finalCount)")
            }
        } catch {
            print("❌ Failed to delete card: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateCard(_ card: PokemonCard) async throws {
        guard let userId = currentUserId,
              let portfolioId = currentPortfolioId,
              let cardId = card.id else {
            return
        }
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("portfolios")
                .document(portfolioId)
                .collection("cards")
                .document(cardId)
                .setData(from: card)
            
            await loadCards() // Refresh the list
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update card: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func searchCards(query: String) async {
        guard let userId = currentUserId,
              let portfolioId = currentPortfolioId else {
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
                .collection("portfolios")
                .document(portfolioId)
                .collection("cards")
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