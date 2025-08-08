import SwiftUI

struct CardTransitionModifier: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

struct SlideTransitionModifier: ViewModifier {
    let isVisible: Bool
    let direction: SlideDirection
    
    enum SlideDirection {
        case left, right, up, down
    }
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.4), value: isVisible)
    }
    
    private var offset: CGSize {
        guard !isVisible else { return .zero }
        
        switch direction {
        case .left:
            return CGSize(width: -50, height: 0)
        case .right:
            return CGSize(width: 50, height: 0)
        case .up:
            return CGSize(width: 0, height: -30)
        case .down:
            return CGSize(width: 0, height: 30)
        }
    }
}

extension View {
    func cardTransition(isVisible: Bool) -> some View {
        modifier(CardTransitionModifier(isVisible: isVisible))
    }
    
    func slideTransition(isVisible: Bool, direction: SlideTransitionModifier.SlideDirection = .up) -> some View {
        modifier(SlideTransitionModifier(isVisible: isVisible, direction: direction))
    }
} 