//
//  CalendarView.swift
//  circa
//
//  Created by Anjali Chaturvedi on 11/07/25.
//
import SwiftUI

struct CalendarView: View {
    @State private var streakDates: [String] = UserDefaults.standard.stringArray(forKey: "streakDates") ?? []
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        VStack {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(monthYearTitle)
                    .font(.headline)

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(1...daysInMonth(for: displayedMonth), id: \.self) { day in
                    let date = dateFor(day: day, in: displayedMonth)
                    let dateStr = formatter.string(from: date)

                    Button(action: {
                        toggleStreak(for: dateStr)
                    }) {
                        ZStack {
                            if streakDates.contains(dateStr) {
                                Text("🔥")
                            } else {
                                Text("\(day)")
                            }
                        }
                        .frame(width: 30, height: 30)
                        .background(streakDates.contains(dateStr) ? Color.orange.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom)
        }
        .frame(width: 260, height: 270)
        .onAppear {
            notifyStreakUpdate()
        }
    }

    var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    func dateFor(day: Int, in month: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: month)
        return calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: day))!
    }

    func daysInMonth(for date: Date) -> Int {
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }

    func toggleStreak(for dateStr: String) {
        if let index = streakDates.firstIndex(of: dateStr) {
            streakDates.remove(at: index)
        } else {
            streakDates.append(dateStr)
        }

        UserDefaults.standard.set(streakDates, forKey: "streakDates")
        notifyStreakUpdate()
    }

    func notifyStreakUpdate() {
        let count = calculateStreakCount()
        NotificationCenter.default.post(name: .streakCountUpdated, object: nil, userInfo: ["streakCount": count])
    }

    func calculateStreakCount() -> Int {
        var count = 0
        var date = calendar.startOfDay(for: Date())
        while streakDates.contains(formatter.string(from: date)) {
            count += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }

    func changeMonth(by offset: Int) {
        if let newDate = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
}
