import Foundation

extension Device {
    /// Creates a clone of the device with a modified name and reset dates.
    /// - Parameter date: The date to use for the new purchase, creation, and update timestamps.
    /// - Returns: A new `Device` instance representing the clone.
    public func cloned(with date: Date) -> Device {
        var clone = self // Create a mutable copy
        clone.id = nil // Ensure it's treated as a new device in the database
        clone.name = "\(self.name) (Copy)" // Append "(Copy)" to the name
        clone.purchaseDate = date // Set new purchase date
        clone.createdAt = date // Set new creation date
        clone.updatedAt = date // Set new update date
        return clone
    }
} 