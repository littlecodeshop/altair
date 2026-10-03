// Altair 8800 front panel assembled from the PNGs exported by
// blender/export_assets.py.  Add to your Xcode target:
//   - AltairLowPoly.xcassets and/or AltairRealistic.xcassets
//   - AltairLayoutLowPoly.swift / AltairLayoutRealistic.swift (generated)
//   - this file
//
// Every element PNG is a square canvas centred on its mounting point, with its
// shadow already baked in, all at the same scale as the plate.  So placing one
// is just: frame(canvas) + position(center), both multiplied by the zoom `k`.

import SwiftUI

struct AltairElement: Identifiable {
    enum Kind { case led, toggle }
    let name: String          // "A15", "D0", "MEMR", "power", "ctrl0" ...
    let kind: Kind
    let center: CGPoint       // points, from the plate image's top-left
    var id: String { name }
}

struct AltairPanelStyle {
    let assetPrefix: String   // "lowpoly" or "real"
    let plateSize: CGSize
    let ledCanvas: CGFloat
    let switchCanvas: CGFloat
    let elements: [AltairElement]
}

enum ToggleState { case up, neutral, down }

struct AltairPanelView: View {
    let style: AltairPanelStyle
    var isLit: (String) -> Bool = { _ in false }
    var toggleState: (String) -> ToggleState = { _ in .down }
    var onToggleTap: (String) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / style.plateSize.width       // zoom factor
            ZStack(alignment: .topLeading) {
                Image("\(style.assetPrefix)_front_plate")
                    .resizable()
                    .frame(width: style.plateSize.width * k,
                           height: style.plateSize.height * k)
                ForEach(style.elements) { e in
                    element(e, k: k)
                        .position(x: e.center.x * k, y: e.center.y * k)
                }
            }
        }
        .aspectRatio(style.plateSize, contentMode: .fit)
    }

    @ViewBuilder
    private func element(_ e: AltairElement, k: CGFloat) -> some View {
        switch e.kind {
        case .led:
            let on = isLit(e.name)
            Image("\(style.assetPrefix)_led_\(on ? "on" : "off")")
                .resizable()
                .frame(width: style.ledCanvas * k, height: style.ledCanvas * k)
                // the glow on the panel isn't in the PNG: add it here
                .shadow(color: on ? .red.opacity(0.9) : .clear, radius: 5 * k)
        case .toggle:
            Image("\(style.assetPrefix)_switch_\(assetSuffix(toggleState(e.name)))")
                .resizable()
                .frame(width: style.switchCanvas * k, height: style.switchCanvas * k)
                .contentShape(Rectangle().inset(by: style.switchCanvas * k * 0.3))
                .onTapGesture { onToggleTap(e.name) }
        }
    }
}

private func assetSuffix(_ state: ToggleState) -> String {
    switch state {
    case .up: return "up"
    case .neutral: return "neutral"
    case .down: return "down"
    }
}

// MARK: - Demo: address switches drive the address LEDs

struct AltairPanelDemo: View {
    @State private var address: UInt16 = 0b0000_0001_1100_1010
    var style: AltairPanelStyle = .lowPoly

    var body: some View {
        AltairPanelView(
            style: style,
            isLit: { name in
                guard name.first == "A", let bit = Int(name.dropFirst()) else { return false }
                return address >> bit & 1 == 1
            },
            toggleState: { name in
                if name == "power" { return .up }
                guard name.first == "A", let bit = Int(name.dropFirst()) else { return .neutral }
                return address >> bit & 1 == 1 ? .up : .down
            },
            onToggleTap: { name in
                guard name.first == "A", let bit = Int(name.dropFirst()) else { return }
                address ^= 1 << bit
            }
        )
        .padding()
    }
}

#Preview { AltairPanelDemo() }
