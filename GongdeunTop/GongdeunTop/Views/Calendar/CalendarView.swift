//
//  CalendarView.swift
//  GongdeunTop
//
//  Created by Martin on 2023/03/16.
//

import SwiftUI


enum RecordSheetType: Identifiable {
    case setting
    case cycle
    var id: Self { self }
}

struct CalendarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject var calendarManager = CalendarManager()
    @StateObject var cycleStore = CycleStore()
    

    @State private var showSetMonth: Bool = false

    private func handleNextMonth() {
        calendarManager.handleNextButton(.month)
        cycleStore.resetAndSubscribe(calendarManager.startingPointDate)
    }
    
    private func handlePreviousMonth() {
        calendarManager.handlePreviousButton(.month)
        cycleStore.resetAndSubscribe(calendarManager.startingPointDate)
    }
    
    
    var body: some View {
        ZStack {
            themeManager.getColorInPriority(of: .background)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                getCalendar()
                
                Divider()
                
                getCycleList()
            }
            .padding(.horizontal)
            .toolbar {
                setMonthToolbar()
                if !calendarManager.isCalendarInCurrentMonth {
                    backToToday()
                }
            }
            .blur(radius: showSetMonth ? 10 : 0)
        }
        .overlay {
            if showSetMonth {
                SetMonthView(manager: calendarManager, cycleStore: cycleStore, isShowing: $showSetMonth)
            }
        }
        .onAppear {
            cycleStore.subscribeCycles(Date())
            
        }
        .onDisappear {
            cycleStore.unsubscribeCycles()
        }
    }
}

// MARK: - 캘린더
extension CalendarView {
    @ViewBuilder
    func getCalendar() -> some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 0), count: 7), spacing: 0) {
            weekdays
            
            blanks
            
            dates
        }
        .gesture(DragGesture(minimumDistance: 2.0, coordinateSpace: .local)
            .onEnded { value in
                switch(value.translation.width, value.translation.height) {
                case (...0, -50...50):
                    handleNextMonth()
                case (0..., -50...50):
                    handlePreviousMonth()
                default:  print("no clue")
                }
            })
        .padding(.bottom, 3)
    }
    
    
    @ViewBuilder
    var weekdays: some View {
        let dateFormatter = DateFormatter()
        if let weekdays = dateFormatter.shortWeekdaySymbols {
            ForEach(weekdays, id: \.self) { weekday in
                HStack(alignment: .center) {
                    Text(String(localized: LocalizedStringResource(stringLiteral: weekday))
                    )
                    .font(.subheadline.bold())
                    .padding(5)
                }
            }
        }
    }
    
    var blanks: some View {
        ForEach(1..<calendarManager.firstWeekdayDigit, id: \.self) { _ in
            VStack {
                Spacer()
            }
        }
    }
    
    var dates: some View {
        ForEach(calendarManager.currentMonthData, id: \.self) { date in
            DateCell(manager: calendarManager, date: date, evaluation: cycleStore.dateEvaluations[date])
                .id(date)
        }
    }
}

// MARK: - Toolbar
extension CalendarView {
    @ToolbarContentBuilder
    func setMonthToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showSetMonth.toggle()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(calendarManager.currentMonth)
                        .font(.title.bold())
                    
                    Text(calendarManager.currentYear)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.down.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
        }
    }
    
    @ToolbarContentBuilder
    func backToToday() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                calendarManager.handleTodayButton()
                cycleStore.resetAndSubscribe(calendarManager.startingPointDate)
            } label: {
                Text("오늘")
            }
        }
    }
}

// MARK: - Cycle List
extension CalendarView {
    @ViewBuilder
    func getCycleList() -> some View {
        ScrollView {
            VStack {
                ForEach(cycleStore.cyclesDictionary[calendarManager.selectedDate] ?? [], id: \.self) {
                    cycle in
                    CycleListCell(cycleManager: CycleManager(cycle: cycle))
                }
            }
        }
    }
}





struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(calendarManager: CalendarManager(), cycleStore: CycleStore())
            .environment(\.locale, .init(identifier: "ko"))
            .environmentObject(ThemeManager())
    }
}
