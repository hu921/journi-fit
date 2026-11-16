import SwiftUI
import SwiftData

/// Workout history as a month calendar. Days with a workout are marked.
/// Tap a marked day to open that day's workout list.
struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    @State private var month = Calendar.current.dateInterval(of: .month, for: .now)!.start
    @State private var openDay: Date?

    private let calendar = Calendar.current

    private var byDay: [Date: [Workout]] {
        Dictionary(grouping: workouts) { calendar.startOfDay(for: $0.startedAt) }
    }

    private var monthWorkouts: [Workout] {
        workouts.filter { calendar.isDate($0.startedAt, equalTo: month, toGranularity: .month) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthHeader(month: $month)
                    MonthGrid(month: month, marked: Set(byDay.keys)) { day in
                        if byDay[day] != nil { openDay = day }
                    }
                        .padding(.vertical, 4)
                }

                Section("This month") {
                    HStack {
                        Summary(value: "\(monthWorkouts.count)", title: "Workouts")
                        Summary(value: monthWorkouts.reduce(0) { $0 + $1.duration }.shortString, title: "Total time")
                        Summary(value: "\(Set(monthWorkouts.map { calendar.startOfDay(for: $0.startedAt) }).count)",
                                title: "Active days")
                    }
                }

            }
            .navigationTitle("History")
            .navigationDestination(item: $openDay) { day in
                DayWorkoutsView(day: day)
            }
        }
    }
}

private struct MonthHeader: View {
    @Binding var month: Date

    var body: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.borderless)
    }

    private func shift(_ n: Int) {
        month = Calendar.current.date(byAdding: .month, value: n, to: month) ?? month
    }
}

private struct MonthGrid: View {
    let month: Date
    let marked: Set<Date>
    let onTap: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    /// Leading blanks (nil) then each day of the month.
    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: month)
        let blanks = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: blanks) + range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: month)
        }
    }

    private var weekdaySymbols: [String] {
        let s = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(s[first...] + s[..<first])
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                Text(s).font(.caption.bold()).foregroundStyle(Theme.muted)
            }
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(day: day,
                            hasWorkout: marked.contains(day),
                            isToday: calendar.isDateInToday(day))
                        .onTapGesture { onTap(day) }
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }
}

private struct DayCell: View {
    let day: Date
    let hasWorkout: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.callout.weight(isToday ? .bold : .regular))
                .foregroundStyle(hasWorkout ? .white : (isToday ? Theme.primary : Theme.text))
                .frame(width: 32, height: 32)
                .background {
                    if hasWorkout {
                        Circle().fill(Theme.primary)
                    } else if isToday {
                        Circle().stroke(Theme.primary, lineWidth: 1.5)
                    }
                }
        }
        .frame(height: 40)
        .contentShape(Rectangle())
        .accessibilityAddTraits(hasWorkout ? .isButton : [])
    }
}

private struct Summary: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundStyle(Theme.primary)
            Text(title).font(.caption).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }
}
