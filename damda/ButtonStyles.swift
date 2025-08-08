import SwiftUI

struct HoverButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let hoverColor: Color
    let textColor: Color
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? hoverColor : backgroundColor)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct TimerButtonStyle: ButtonStyle {
    let isActive: Bool
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pretendard(14, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 80)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color(hex: "FF6B6B") : (isHovered ? Color(hex: "F57C51") : Color(hex: "E06552")))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.1 : (isHovered ? 0.3 : 0.2)), 
                   radius: configuration.isPressed ? 2 : (isHovered ? 6 : 4), 
                   x: 0, 
                   y: configuration.isPressed ? 1 : (isHovered ? 3 : 2))
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct NavigationButtonStyle: ButtonStyle {
    let isSelected: Bool
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
            .opacity(configuration.isPressed ? 0.8 : (isHovered ? 0.9 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
} 