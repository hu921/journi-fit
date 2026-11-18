import SwiftUI

/// Front and back body figures. Muscles worked in a workout are filled in
/// journi orange: darker means more sets. Main muscles count a full set,
/// helper muscles count half a set.
struct MuscleMapView: View {
    let scores: [String: Double] // muscle name -> sets

    init(workout: Workout) {
        scores = MuscleMapView.scores(for: workout)
    }

    static func scores(for workout: Workout) -> [String: Double] {
        var result: [String: Double] = [:]
        for item in workout.sortedExercises {
            guard let ex = item.exercise else { continue }
            let sets = Double(item.sortedSets.filter(\.done).count)
            guard sets > 0 else { continue }
            for m in ex.primaryMuscles { result[m, default: 0] += sets }
            for m in ex.secondaryMuscles { result[m, default: 0] += sets / 2 }
        }
        return result
    }

    private var maxScore: Double { scores.values.max() ?? 1 }

    /// Muscles sorted by sets, most first.
    private var ranked: [(name: String, sets: Double)] {
        scores.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                figure(BodyFigure.front, label: "Front")
                figure(BodyFigure.back, label: "Back")
            }
            .frame(maxWidth: .infinity)

            // Legend
            HStack(spacing: 6) {
                Text("Less").font(.caption2).foregroundStyle(Theme.muted)
                ForEach([0.3, 0.55, 0.8, 1.0], id: \.self) { o in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.primary.opacity(o))
                        .frame(width: 18, height: 10)
                }
                Text("More sets").font(.caption2).foregroundStyle(Theme.muted)
            }

            // Muscle list
            FlowChips(items: ranked.map { item in
                let sets = item.sets.rounded() == item.sets
                    ? "\(Int(item.sets))" : item.sets.formatted(.number.precision(.fractionLength(1)))
                return (item.name.capitalized, sets, opacity(for: item.name))
            })
        }
        .padding(.vertical, 8)
    }

    private func opacity(for muscle: String) -> Double {
        guard let s = scores[muscle], s > 0 else { return 0 }
        return 0.3 + 0.7 * (s / maxScore)
    }

    private func figure(_ regions: [BodyRegion], label: String) -> some View {
        VStack(spacing: 6) {
            Canvas { ctx, size in
                let scale = min(size.width / 100, size.height / 200)
                let dx = (size.width - 100 * scale) / 2
                func path(_ r: CGRect) -> Path {
                    let rect = CGRect(x: dx + r.minX * scale, y: r.minY * scale,
                                      width: r.width * scale, height: r.height * scale)
                    return Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 2)
                }
                // Body base
                for r in BodyFigure.silhouette {
                    ctx.fill(path(r), with: .color(BodyFigure.skin))
                }
                // Muscles
                for region in regions {
                    let o = region.muscles.map(opacity(for:)).max() ?? 0
                    for r in region.rects {
                        let p = path(r)
                        ctx.fill(p, with: .color(BodyFigure.muscle))
                        if o > 0 { ctx.fill(p, with: .color(Theme.primary.opacity(o))) }
                        ctx.stroke(p, with: .color(.white.opacity(0.9)), lineWidth: 1)
                    }
                }
            }
            .frame(width: 120, height: 240)
            .accessibilityHidden(true)

            Text(label).font(.caption.bold()).foregroundStyle(Theme.muted)
        }
    }
}

struct BodyRegion {
    let muscles: [String]
    let rects: [CGRect]
}

/// Simple rounded shapes on a 100 × 200 grid, drawn in journi Fit's soft style.
enum BodyFigure {
    static let skin = Color(hex: 0xF1E8DC)
    static let muscle = Color(hex: 0xE4D8C8)

    private static func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    /// Shared outline: head, torso, arms, legs, hands, feet.
    static let silhouette: [CGRect] = [
        r(39, 0, 22, 25),                         // head
        r(44, 20, 12, 14),                        // neck
        r(26, 29, 48, 22),                        // shoulders line
        r(30, 32, 40, 62),                        // torso
        r(30, 84, 40, 24),                        // hips
        r(21, 34, 12, 40), r(67, 34, 12, 40),     // upper arms
        r(17, 68, 12, 34), r(71, 68, 12, 34),     // forearms
        r(16, 100, 12, 14), r(72, 100, 12, 14),   // hands
        r(31, 100, 18, 52), r(51, 100, 18, 52),   // thighs
        r(33, 146, 14, 44), r(53, 146, 14, 44),   // lower legs
        r(31, 186, 17, 10), r(52, 186, 17, 10),   // feet
    ]

    static let front: [BodyRegion] = [
        BodyRegion(muscles: ["neck"], rects: [r(45, 23, 10, 9)]),
        BodyRegion(muscles: ["traps"], rects: [r(34, 29, 10, 6), r(56, 29, 10, 6)]),
        BodyRegion(muscles: ["shoulders"], rects: [r(22, 31, 14, 16), r(64, 31, 14, 16)]),
        BodyRegion(muscles: ["chest"], rects: [r(35, 34, 15, 16), r(50, 34, 15, 16)]),
        BodyRegion(muscles: ["biceps"], rects: [r(22, 47, 11, 21), r(67, 47, 11, 21)]),
        BodyRegion(muscles: ["forearms"], rects: [r(18, 70, 10, 28), r(72, 70, 10, 28)]),
        BodyRegion(muscles: ["abdominals"], rects: [r(41, 52, 18, 34)]),
        BodyRegion(muscles: ["abductors"], rects: [r(30, 90, 6, 18), r(64, 90, 6, 18)]),
        BodyRegion(muscles: ["quadriceps"], rects: [r(32, 106, 14, 40), r(54, 106, 14, 40)]),
        BodyRegion(muscles: ["adductors"], rects: [r(46, 104, 8, 24)]),
        BodyRegion(muscles: ["calves"], rects: [r(35, 152, 10, 32), r(55, 152, 10, 32)]),
    ]

    static let back: [BodyRegion] = [
        BodyRegion(muscles: ["neck"], rects: [r(45, 21, 10, 8)]),
        BodyRegion(muscles: ["traps"], rects: [r(37, 27, 26, 14)]),
        BodyRegion(muscles: ["shoulders"], rects: [r(22, 31, 14, 16), r(64, 31, 14, 16)]),
        BodyRegion(muscles: ["middle back"], rects: [r(42, 41, 16, 20)]),
        BodyRegion(muscles: ["lats"], rects: [r(31, 42, 11, 32), r(58, 42, 11, 32)]),
        BodyRegion(muscles: ["lower back"], rects: [r(42, 62, 16, 22)]),
        BodyRegion(muscles: ["triceps"], rects: [r(22, 47, 11, 21), r(67, 47, 11, 21)]),
        BodyRegion(muscles: ["forearms"], rects: [r(18, 70, 10, 28), r(72, 70, 10, 28)]),
        BodyRegion(muscles: ["glutes"], rects: [r(32, 86, 17, 20), r(51, 86, 17, 20)]),
        BodyRegion(muscles: ["abductors"], rects: [r(29, 88, 4, 16), r(67, 88, 4, 16)]),
        BodyRegion(muscles: ["hamstrings"], rects: [r(32, 108, 15, 38), r(53, 108, 15, 38)]),
        BodyRegion(muscles: ["calves"], rects: [r(34, 150, 12, 32), r(54, 150, 12, 32)]),
    ]
}

/// Muscle names with set counts, wrapping onto new lines.
private struct FlowChips: View {
    let items: [(name: String, sets: String, opacity: Double)]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.name) { item in
                HStack(spacing: 6) {
                    Circle().fill(Theme.primary.opacity(item.opacity)).frame(width: 8, height: 8)
                    Text(item.name).font(.caption.bold()).foregroundStyle(Theme.text)
                    Text(item.sets == "1" ? "1 set" : "\(item.sets) sets")
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.background, in: Capsule())
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowH = max(rowH, size.height)
        }
        return CGSize(width: proposal.width ?? maxX, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
