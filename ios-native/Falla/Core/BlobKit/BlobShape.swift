// BlobShape.swift
// Falla - iOS 26 Fortune Telling App
// Elastic blob shape with physics-based deformation

import SwiftUI

// MARK: - Blob Shape
/// Animatable blob shape with stretch and drag deformation
struct BlobShape: Shape {
    // MARK: - Properties
    var stretchFactor: CGFloat = 1.0
    var dragOffset: CGPoint = .zero
    var bouncePhase: CGFloat = 0
    
    // MARK: - Animatable Data
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>> {
        get {
            AnimatablePair(
                stretchFactor,
                AnimatablePair(
                    dragOffset.x,
                    AnimatablePair(dragOffset.y, bouncePhase)
                )
            )
        }
        set {
            stretchFactor = newValue.first
            dragOffset.x = newValue.second.first
            dragOffset.y = newValue.second.second.first
            bouncePhase = newValue.second.second.second
        }
    }
    
    // MARK: - Path
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2
        
        // Apply deformation based on drag
        let dragMagnitude = sqrt(dragOffset.x * dragOffset.x + dragOffset.y * dragOffset.y)
        let dragAngle = atan2(dragOffset.y, dragOffset.x)
        
        // Number of control points for smooth blob
        let pointCount = 8
        var points: [CGPoint] = []
        
        for i in 0..<pointCount {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(pointCount))
            
            // Base radius with stretch deformation
            var radius = baseRadius
            
            // Apply stretch factor
            let stretchAngle = angle
            let stretchInfluence = cos(stretchAngle) * (stretchFactor - 1.0)
            radius *= (1.0 + stretchInfluence * 0.3)
            
            // Apply drag deformation
            if dragMagnitude > 0 {
                let dragInfluence = cos(angle - dragAngle)
                radius += dragInfluence * dragMagnitude * 0.1
            }
            
            // Apply bounce wobble
            if bouncePhase > 0 {
                let wobble = sin(angle * 3 + bouncePhase * .pi * 4) * bouncePhase * 5
                radius += wobble
            }
            
            // Clamp radius
            radius = max(baseRadius * 0.7, min(baseRadius * 1.4, radius))
            
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            points.append(CGPoint(x: x, y: y))
        }
        
        // Create smooth blob using cubic bezier curves
        if let firstPoint = points.first {
            path.move(to: firstPoint)
            
            for i in 0..<points.count {
                let p0 = points[(i - 1 + points.count) % points.count]
                let p1 = points[i]
                let p2 = points[(i + 1) % points.count]
                let p3 = points[(i + 2) % points.count]
                
                // Catmull-Rom to Bezier conversion
                let tension: CGFloat = 0.5
                let cp1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) * tension / 3,
                    y: p1.y + (p2.y - p0.y) * tension / 3
                )
                let cp2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) * tension / 3,
                    y: p2.y - (p3.y - p1.y) * tension / 3
                )
                
                path.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Blob View
/// View wrapper for animated blob
struct BlobView: View {
    @Binding var stretchFactor: CGFloat
    @Binding var dragOffset: CGPoint
    @Binding var bouncePhase: CGFloat
    
    let fillColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    
    init(
        stretchFactor: Binding<CGFloat> = .constant(1.0),
        dragOffset: Binding<CGPoint> = .constant(.zero),
        bouncePhase: Binding<CGFloat> = .constant(0),
        fillColor: Color = .white.opacity(0.1),
        strokeColor: Color = .white.opacity(0.2),
        strokeWidth: CGFloat = 1
    ) {
        self._stretchFactor = stretchFactor
        self._dragOffset = dragOffset
        self._bouncePhase = bouncePhase
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        BlobShape(stretchFactor: stretchFactor, dragOffset: dragOffset, bouncePhase: bouncePhase)
            .fill(fillColor)
            .overlay {
                BlobShape(stretchFactor: stretchFactor, dragOffset: dragOffset, bouncePhase: bouncePhase)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            }
    }
}

// MARK: - Elastic Pill Shape
/// Pill shape that can stretch and deform elastically
struct ElasticPillShape: Shape {
    var stretchX: CGFloat = 1.0
    var stretchY: CGFloat = 1.0
    var cornerRadius: CGFloat = 0.5 // 0.5 = full pill
    
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(stretchX, AnimatablePair(stretchY, cornerRadius)) }
        set {
            stretchX = newValue.first
            stretchY = newValue.second.first
            cornerRadius = newValue.second.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let stretchedWidth = rect.width * stretchX
        let stretchedHeight = rect.height * stretchY
        
        let stretchedRect = CGRect(
            x: rect.midX - stretchedWidth / 2,
            y: rect.midY - stretchedHeight / 2,
            width: stretchedWidth,
            height: stretchedHeight
        )
        
        let radius = min(stretchedHeight * cornerRadius, stretchedWidth * cornerRadius)
        return RoundedRectangle(cornerRadius: radius).path(in: stretchedRect)
    }
}

// MARK: - Preview
#Preview {
    struct BlobPreview: View {
        @State private var stretchFactor: CGFloat = 1.0
        @State private var dragOffset: CGPoint = .zero
        @State private var bouncePhase: CGFloat = 0
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    BlobView(
                        stretchFactor: $stretchFactor,
                        dragOffset: $dragOffset,
                        bouncePhase: $bouncePhase,
                        fillColor: .blue.opacity(0.3),
                        strokeColor: .blue.opacity(0.5),
                        strokeWidth: 2
                    )
                    .frame(width: 150, height: 150)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = CGPoint(x: value.translation.width, y: value.translation.height)
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                                    dragOffset = .zero
                                    bouncePhase = 1.0
                                }
                                withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                                    bouncePhase = 0
                                }
                            }
                    )
                    
                    HStack {
                        Button("Stretch") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                stretchFactor = 1.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    stretchFactor = 1.0
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Bounce") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                                bouncePhase = 1.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    bouncePhase = 0
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
    
    return BlobPreview()
}
