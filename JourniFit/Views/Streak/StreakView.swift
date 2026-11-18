import SwiftUI
import SwiftData
import Charts

/// Streak page in three parts:
/// 1. Week streak and this week's progress, side by side.
/// 2. A Sunday–Saturday chart of hours or volume. Swipe or tap < > to change week.
/// 3. Breakthroughs: exercises that beat their all-time best, newest first.
struct StreakView: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt)
    private var workouts: [Workout]
    @Query private var profiles: [UserProfile]
    @AppStorage("weeklyTarget") private var target = 3
    @State private var weekOffset = 0 // 0 = this week, -1 = last week
    @State private var editingTarget = false

    private var unit: String { profiles.first?.weightUnit == .kg ? "kg" : "lbs" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StreakCards(workouts: workouts, target: $target)
                    WeekChartCard(workouts: workouts, weekOffset: $weekOffset, unit: unit)
                    BreakthroughsCard(workouts: workouts, unit: unit)
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Streak")
        }
    }
}

/// Weeks run Sunday to Saturday on this page.
enum StreakCalendar {
    static let calendar: Calendar = {
        var c = Calendar.current
        c.firstWeekday = 1
        return c
    }()

    static func weekStart(_ date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func week(offset: Int) -> DateInterval {
        let start = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart(.now)) ?? weekStart(.now)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        return DateInterval(start: start, end: end)
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Part 1

/// Weekly streak: weeks in a row that hit the weekly workout target.
/// Rest days never break it. The current week only counts once it is hit.
private struct StreakCards: View {
    let workouts: [Workout]
    @Binding var target: Int

    private let calendar = StreakCalendar.calendar

    private var daysPerWeek: [Date: Int] {
        var days: [Date: Set<Date>] = [:]
        for w in workouts {
            days[StreakCalendar.weekStart(w.startedAt), default: []].insert(calendar.startOfDay(for: w.startedAt))
        }
        return days.mapValues(\.count)
    }

    private var thisWeek: Date { StreakCalendar.weekStart(.now) }
    private func hit(_ week: Date, _ d: [Date: Int]) -> Bool { (d[week] ?? 0) >= target }
    private func previous(_ week: Date) -> Date {
        calendar.date(byAdding: .weekOfYear, value: -1, to: week) ?? week
    }

    var body: some View {
        let d = daysPerWeek
        let current: Int = {
            var week = hit(thisWeek, d) ? thisWeek : previous(thisWeek)
            var count = 0
            while hit(week, d) { count += 1; week = previous(week) }
            return count
        }()
        let best: Int = {
            guard let first = workouts.first?.startedAt else { return 0 }
            var week = StreakCalendar.weekStart(first), run = 0, best = 0
            while week <= thisWeek {
                run = hit(week, d) ? run + 1 : 0
                best = max(best, run)
                week = calendar.date(byAdding: .weekOfYear, value: 1, to: week) ?? thisWeek.addingTimeInterval(1)
            }
            return best
        }()
        let days = d[thisWeek] ?? 0

        HStack(alignment: .top, spacing: 12) {
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Week streak").font(.subheadline.bold()).foregroundStyle(Theme.muted)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(current > 0 ? Theme.primary : Theme.muted.opacity(0.4))
                        Text("\(current)").font(.system(size: 40, weight: .bold, design: .rounded))
                    }
                    Text(current == 1 ? "week" : "weeks").font(.caption).foregroundStyle(Theme.muted)
                    Text("Best: \(best)").font(.caption.bold()).foregroundStyle(Theme.primary)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This week").font(.subheadline.bold()).foregroundStyle(Theme.muted)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(days)").font(.system(size: 40, weight: .bold, design: .rounded))
                        Text("/\(target) days").font(.subheadline).foregroundStyle(Theme.muted)
                    }
                    WeekDots(week: thisWeek, workouts: workouts)
                    Stepper("Target", value: $target, in: 1...7)
                        .labelsHidden()
                        .scaleEffect(0.8, anchor: .leading)
                        .frame(height: 28)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Seven dots for the week. Filled = worked out that day.
private struct WeekDots: View {
    let week: Date
    let workouts: [Workout]

    var body: some View {
        let calendar = StreakCalendar.calendar
        let worked = Set(workouts.map { calendar.startOfDay(for: $0.startedAt) })
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { i in
                let day = calendar.date(byAdding: .day, value: i, to: week) ?? week
                VStack(spacing: 2) {
                    Circle()
                        .fill(worked.contains(day) ? Theme.primary : Theme.primary.opacity(0.12))
                        .frame(width: 12, height: 12)
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2).foregroundStyle(Theme.muted)
                }
            }
        }
    }
}

// MARK: - Part 2

private enum ChartMetric: String, CaseIterable, Identifiable {
    case hours = "Hours", volume = "Volume"
    var id: String { rawValue }
}

private struct WeekChartCard: View {
    let workouts: [Workout]
    @Binding var weekOffset: Int
    let unit: String
    @AppStorage("streakChartMetric") private var metricRaw = ChartMetric.hours.rawValue

    private var metric: ChartMetric { ChartMetric(rawValue: metricRaw) ?? .hours }
    private var week: DateInterval { StreakCalendar.week(offset: weekOffset) }

    private func value(_ w: Workout) -> Double {
        switch metric {
        case .hours: w.duration / 60 // minutes
        case .volume: w.volume
        }
    }

    private var days: [(day: Date, value: Double)] {
        let cal = StreakCalendar.calendar
        return (0..<7).map { i in
            let day = cal.date(byAdding: .day, value: i, to: week.start) ?? week.start
            let total = workouts.filter { cal.isDate($0.startedAt, inSameDayAs: day) }.reduce(0) { $0 + value($1) }
            return (day, total)
        }
    }

    private func format(_ v: Double) -> String {
        switch metric {
        case .hours:
            let m = Int(v.rounded())
            return m >= 60 ? "\(m / 60) h \(m % 60) min" : "\(m) min"
        case .volume: return "\(v.formatted(.number.precision(.fractionLength(0)))) \(unit)"
        }
    }

    private var weekLabel: String {
        if weekOffset == 0 { return "this week" }
        if weekOffset == -1 { return "last week" }
        let end = week.end.addingTimeInterval(-1)
        return "\(week.start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var body: some View {
        let data = days
        let total = data.reduce(0) { $0 + $1.value }
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button { withAnimation { weekOffset -= 1 } } label: {
                        Image(systemName: "chevron.left").padding(6)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(format(total)).font(.title3.bold()).foregroundStyle(Theme.text)
                        Text(weekLabel).font(.caption).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Button { withAnimation { weekOffset += 1 } } label: {
                        Image(systemName: "chevron.right").padding(6)
                    }
                    .disabled(weekOffset >= 0)
                }
                .foregroundStyle(Theme.primary)
                .buttonStyle(.plain)

                Chart(data, id: \.day) { item in
                    BarMark(x: .value("Day", item.day.formatted(.dateTime.weekday(.abbreviated))),
                            y: .value(metric.rawValue, metric == .hours ? item.value / 60 : item.value))
                        .foregroundStyle(Theme.primary.gradient)
                        .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { v in
                        AxisGridLine().foregroundStyle(Theme.muted.opacity(0.2))
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text(metric == .hours ? "\(d.formatted()) h" : d.formatted(.number.notation(.compactName)))
                            }
                        }
                    }
                }
                .frame(height: 170)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 30).onEnded { g in
                    withAnimation {
                        if g.translation.width > 0 { weekOffset -= 1 }
                        else if weekOffset < 0 { weekOffset += 1 }
                    }
                })

                HStack(spacing: 8) {
                    ForEach(ChartMetric.allCases) { m in
                        Button { metricRaw = m.rawValue } label: {
                            Text(m.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .foregroundStyle(metric == m ? .white : Theme.text)
                                .background(metric == m ? Theme.primary : Theme.muted.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Part 3

/// An exercise that beat its all-time best: more weight with the same or more reps,
/// or more reps at the same weight. Compares the top set of each workout
/// with the best top set from all earlier workouts.
struct Breakthrough: Identifiable {
    let exerciseID: String
    let date: Date
    let before: (weight: Double, reps: Int)
    let after: (weight: Double, reps: Int)
    var id: String { exerciseID }

    /// Heaviest done set, most reps at that weight.
    static func topSet(_ item: WorkoutExercise) -> (weight: Double, reps: Int)? {
        let done = item.sortedSets.filter(\.done)
        guard let w = done.map(\.weight).max() else { return nil }
        let reps = done.filter { $0.weight == w }.map(\.reps).max() ?? 0
        return (w, reps)
    }

    /// Breakthroughs in the interval, one per exercise (the latest).
    static func list(in week: DateInterval, workouts: [Workout]) -> [Breakthrough] {
        var best: [String: (weight: Double, reps: Int)] = [:] // all-time best so far
        var found: [String: Breakthrough] = [:]
        for w in workouts.sorted(by: { $0.startedAt < $1.startedAt }) {
            guard w.startedAt < week.end else { break }
            for item in w.sortedExercises {
                guard let top = topSet(item) else { continue }
                guard let prev = best[item.exerciseID] else {
                    best[item.exerciseID] = top // first time: sets the record
                    continue
                }
                let heavier = top.weight > prev.weight && top.reps >= prev.reps
                let moreReps = top.weight == prev.weight && top.reps > prev.reps
                if heavier || moreReps {
                    best[item.exerciseID] = top
                    if week.contains(w.startedAt) {
                        found[item.exerciseID] = Breakthrough(exerciseID: item.exerciseID, date: w.startedAt,
                                                              before: prev, after: top)
                    }
                }
            }
        }
        return found.values.sorted { $0.date > $1.date }
    }
}

private struct BreakthroughsCard: View {
    let workouts: [Workout]
    let unit: String
    private let limit = 20

    private func w(_ v: Double) -> String { "\(v.formatted()) \(unit)" }

    var body: some View {
        let items = Array(Breakthrough.list(in: DateInterval(start: .distantPast, end: .distantFuture), workouts: workouts).prefix(limit))
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill").foregroundStyle(Theme.primary)
                    Text("Breakthroughs").font(.headline).foregroundStyle(Theme.text)
                    Spacer()
                }

                if items.isEmpty {
                    Text("No breakthroughs yet. Add a little weight or one more rep to beat your best.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                } else {
                    ForEach(items) { b in
                        let ex = ExerciseLibrary.shared.exercise(id: b.exerciseID)
                        HStack(spacing: 12) {
                            if let ex {
                                ExerciseImage(exercise: ex).frame(width: 40, height: 40).clipShape(Circle())
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ex?.name ?? "Exercise").font(.subheadline.bold()).foregroundStyle(Theme.text)
                                Text("\(w(b.before.weight)) × \(b.before.reps)  →  \(w(b.after.weight)) × \(b.after.reps)")
                                    .font(.caption).foregroundStyle(Theme.muted)
                                Text(b.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.caption2).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text(badge(b))
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(.white)
                                .background(Theme.primary, in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private func badge(_ b: Breakthrough) -> String {
        if b.after.weight > b.before.weight {
            return "+\((b.after.weight - b.before.weight).formatted()) \(unit)"
        }
        let r = b.after.reps - b.before.reps
        return "+\(r) \(r == 1 ? "rep" : "reps")"
    }
}
