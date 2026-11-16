import SwiftUI
import SwiftData

/// Weekly streak: weeks in a row that hit the weekly workout target.
/// Rest days never break it. The current week only counts once it is hit.
struct StreakView: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt)
    private var workouts: [Workout]
    @AppStorage("weeklyTarget") private var target = 3

    private let calendar = Calendar.current

    private func weekStart(_ date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// Workout days per week (several workouts on one day count once).
    private var daysPerWeek: [Date: Int] {
        var days: [Date: Set<Date>] = [:]
        for w in workouts {
            days[weekStart(w.startedAt), default: []].insert(calendar.startOfDay(for: w.startedAt))
        }
        return days.mapValues(\.count)
    }

    private var thisWeek: Date { weekStart(.now) }

    private func hit(_ week: Date) -> Bool { (daysPerWeek[week] ?? 0) >= target }

    private func previous(_ week: Date) -> Date {
        calendar.date(byAdding: .weekOfYear, value: -1, to: week) ?? week
    }

    private var currentStreak: Int {
        var week = hit(thisWeek) ? thisWeek : previous(thisWeek)
        var count = 0
        while hit(week) {
            count += 1
            week = previous(week)
        }
        return count
    }

    private var bestStreak: Int {
        guard let first = workouts.first?.startedAt else { return 0 }
        var week = weekStart(first), run = 0, best = 0
        while week <= thisWeek {
            run = hit(week) ? run + 1 : 0
            best = max(best, run)
            week = calendar.date(byAdding: .weekOfYear, value: 1, to: week) ?? thisWeek.addingTimeInterval(1)
        }
        return best
    }

    private var thisWeekDays: Int { daysPerWeek[thisWeek] ?? 0 }

    /// Last 12 weeks, oldest first.
    private var recentWeeks: [Date] {
        (0..<12).reversed().compactMap { calendar.date(byAdding: .weekOfYear, value: -$0, to: thisWeek) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(currentStreak > 0 ? Theme.primary : Theme.muted.opacity(0.4))
                        Text("\(currentStreak)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                        Text(currentStreak == 1 ? "week streak" : "weeks streak")
                            .foregroundStyle(Theme.muted)
                        Text("Best: \(bestStreak) \(bestStreak == 1 ? "week" : "weeks")")
                            .font(.footnote.bold())
                            .foregroundStyle(Theme.primary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("This week") {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(Theme.primary.opacity(0.15), lineWidth: 10)
                            Circle()
                                .trim(from: 0, to: min(Double(thisWeekDays) / Double(max(target, 1)), 1))
                                .stroke(Theme.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(thisWeekDays)/\(target)").font(.headline)
                        }
                        .frame(width: 72, height: 72)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(thisWeekDays >= target
                                 ? "Target hit. Streak is safe."
                                 : "\(target - thisWeekDays) more \(target - thisWeekDays == 1 ? "day" : "days") to keep the streak.")
                                .font(.subheadline)
                            WeekDots(week: thisWeek, workouts: workouts)
                        }
                    }
                    .padding(.vertical, 4)

                    Stepper("Weekly target: \(target) days", value: $target, in: 1...7)
                }

                Section("Last 12 weeks") {
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(recentWeeks, id: \.self) { week in
                            let days = daysPerWeek[week] ?? 0
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(hit(week) ? Theme.primary : Theme.primary.opacity(days > 0 ? 0.35 : 0.1))
                                    .frame(height: CGFloat(max(days, 0)) * 12 + 6)
                                Text("\(days)").font(.caption2).foregroundStyle(Theme.muted)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 110, alignment: .bottom)
                }
            }
            .navigationTitle("Streak")
        }
    }
}

/// Seven dots for the week. Filled = worked out that day.
private struct WeekDots: View {
    let week: Date
    let workouts: [Workout]

    var body: some View {
        let calendar = Calendar.current
        let worked = Set(workouts.map { calendar.startOfDay(for: $0.startedAt) })
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let day = calendar.date(byAdding: .day, value: i, to: week) ?? week
                VStack(spacing: 2) {
                    Circle()
                        .fill(worked.contains(day) ? Theme.primary : Theme.primary.opacity(0.12))
                        .frame(width: 14, height: 14)
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2).foregroundStyle(Theme.muted)
                }
            }
        }
    }
}
