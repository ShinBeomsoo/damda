import Foundation

public struct SM2State {
    public var easeFactor: Double
    public var intervalDays: Int
    public var repetitionCount: Int
    public var lapseCount: Int
}

public enum SM2Scheduler {
    /// Review with SM-2 algorithm.
    /// - Parameters:
    ///   - state: current state
    ///   - quality: 0...5, where <3 is a failure
    /// - Returns: updated state after review
    public static func review(state: SM2State, quality: Int) -> SM2State {
        // Clamp quality to 0...5
        let q = max(0, min(5, quality))
        var next = state
        // Update Ease Factor first (tests expect EF change to affect interval multiplication)
        next.easeFactor = updatedEaseFactor(currentEF: state.easeFactor, quality: q)
        
        if q < 3 {
            // Failure: reset to learning
            next.repetitionCount = 0
            next.intervalDays = 1
            next.lapseCount = state.lapseCount + 1
            return next
        }
        
        // Success path
        next.repetitionCount = state.repetitionCount + 1
        if next.repetitionCount == 1 {
            next.intervalDays = 1
        } else if next.repetitionCount == 2 {
            next.intervalDays = 6
        } else {
            // Use updated EF for multiplication as per test expectation
            let multiplied = Double(state.intervalDays) * next.easeFactor
            next.intervalDays = Int(round(multiplied))
            if next.intervalDays < 1 { next.intervalDays = 1 }
        }
        return next
    }
    
    private static func updatedEaseFactor(currentEF: Double, quality: Int) -> Double {
        // SM-2 EF update formula
        let delta = 0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02)
        let ef = max(1.3, currentEF + delta)
        return ef
    }
}