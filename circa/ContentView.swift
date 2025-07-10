//
//  ContentView.swift
//  circa
//
//  Created by Anjali Chaturvedi on 11/07/25.
//

import SwiftUI

struct ContentView: View {
    @State private var streakDates: Set<String> = []
    @State private var today = Date()
    var onStreakChange: ((Int) -> Void)? = nil
    var popover: NSPopover

    var streakTitle: String {
        "🔥 \(streakDates.count)"
    }

    let calendar = Calendar.current

    var body: some View {
        VStack {
            Text(monthYearString(from: today))
                .font(.headline)
                .padding(.top, 10)

            calendarGrid
                .padding(10)

            Spacer()
        }
            .frame(width: 240, height: 300)
            .onAppear {
                loadData()
            }
    }

    var calendarGrid: some View {
        let days = makeMonthDays(for: today)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, date in Button(action: {
                toggle(date)
            }) {
                Text(displayText(for: date))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            }

        }
    }

    func displayText(for date: Date) -> String {
        let dateStr = isoString(from: date)
        if streakDates.contains(dateStr) {
            return "🔥"
        } else {
            let day = calendar.component(.day, from: date)
            return "\(day)"
        }
    }

    func toggle(_ date: Date) {
        let dateStr = isoString(from: date)
        if streakDates.contains(dateStr) {
            streakDates.remove(dateStr)
        } else {
            streakDates.insert(dateStr)
        }
        saveData()
        onStreakChange?(streakDates.count)
    }

    func makeMonthDays(for date: Date) -> [Date] {
        var result: [Date] = []
        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekdayOffset = calendar.component(.weekday, from: firstOfMonth) - 1

        for _ in 0..<weekdayOffset {
            result.append(Date.distantPast) // placeholder
        }

        for day in range {
            if let d = calendar.date(bySetting: .day, value: day, of: firstOfMonth) {
                result.append(d)
            }
        }

        return result
    }

    func isoString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    func loadData() {
        if let saved = UserDefaults.standard.array(forKey: "streakDates") as? [String] {
            streakDates = Set(saved)
        }
    }

    func saveData() {
        UserDefaults.standard.set(Array(streakDates), forKey: "streakDates")
    }
}
