//
//  TimerManager.swift
//  GongdeunTop
//
//  Created by Martin on 2023/03/19.
//

import Foundation
import SwiftUI
import Combine

struct TimeSetting {
    var session: Session = Session.basicSetting
    var sessions: [Session] = Session.basicSessions
    var numOfSessions: Int {
        get { sessions.count }
        set(newValue) {
            guard abs(newValue - numOfSessions) == 1 else {
                return
            }
            if newValue < numOfSessions {
                sessions.removeFirst()
            } else {
                sessions.insert(self.session, at: sessions.startIndex)
            }
        }
    }
    var willGetLongRefresh: Bool = true
    var isCustomized: Bool = false
    
    static let longRefreshTime: Int = 30
}

struct Session: Identifiable {
    var id: String = UUID().uuidString
    var concentrationTime: Int
    var restTime: Int
    
    var concentrationSeconds: Int {
        concentrationTime * 60
    }
    
    var restSeconds: Int {
        restTime * 60
    }
    
    var sessionTime: Int {
        concentrationTime + restTime
    }
}

extension Session {
    static let basicSetting = Session(concentrationTime: 25, restTime: 5)
    static let lastSessionPlaceholder = Session(concentrationTime: 25, restTime: 30)
    static var basicSessions = Array(repeating: Self.basicSetting, count: 3) + [Self.lastSessionPlaceholder]
}

@MainActor
final class TimerManager: ObservableObject {
    @Published var timeSetting = TimeSetting()
    @Published var currentTimeIndex: Int = 0
    @Published var remainSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var timer: Timer?
    
    var currentSession: Session {
        let sessionIndex = Int(currentTimeIndex / 2)
        guard sessionIndex < timeSetting.sessions.count else { return timeSetting.sessions.first ?? Session.basicSetting}
        return timeSetting.sessions[sessionIndex]
    }
    
    
    init() {
        $currentTimeIndex
            .combineLatest($timeSetting)
            .map { (current, timeSetting) in
                let sessionIndex = Int(current / 2)
                let timeIndex = current % 2
                let currentSession: Session = timeSetting.sessions[sessionIndex]
                return timeIndex == 0 ? currentSession.concentrationSeconds : currentSession.restSeconds
            }
            .assign(to: &$remainSeconds)
    }
    
    
    // MARK: - Reset Methods
    func resetToOrigin() {
        pauseTime()
        currentTimeIndex = 0
        timer = nil
    }
    
    func resetTimes() {
        pauseTime()
        currentTimeIndex = currentTimeIndex
    }
    
    
// MARK: - Move and Stop Time
    func moveToNextTimes() {
        withAnimation {
            pauseTime()
            if knowIsInSession() && !knowIsLastTime() {
                currentTimeIndex += 1
            }
        }
    }
    
    func pauseTime() {
        timer?.invalidate()
        isRunning = false
    }
    
    func elapsesTime() {
        remainSeconds -= 1
    }
    
    
    
// MARK: - Get CurrentTime Info
    func knowIsInRestTime() -> Bool {
        self.currentTimeIndex % 2 == 1
    }
    
    func knowIsInSession() -> Bool {
        let numOfTimes = timeSetting.numOfSessions * 2
        return (0..<numOfTimes).contains(self.currentTimeIndex)
    }
    
    func knowIsLastTime() -> Bool {
        let numOfTimes = timeSetting.numOfSessions * 2
        return self.currentTimeIndex == numOfTimes - 1
    }
    
    
// MARK: - Get CurrentTime Digit Strings
    func getMinuteString() -> String {
        let seconds: Int = self.remainSeconds <= 0 ? 0 : self.remainSeconds
        let result: Int = Int(seconds / 60)
        
        if result < 10 {
            return "0" + String(result)
        }
        return String(result)
    }
    
    func getSecondString() -> String {
        let seconds: Int = self.remainSeconds <= 0 ? 0 : self.remainSeconds
        let result: Int = seconds % 60
        
        if result < 10 {
            return "0" + String(result)
        } else {
            return String(result)
        }
    }
    
    func getTotalMinute() -> Int {
        timeSetting.sessions.reduce(0) {$0 + $1.sessionTime}
    }
    
// MARK: - Get End Degree
    func getEndDegree() -> Double {
        let currentSeconds = knowIsInRestTime() ? currentSession.restSeconds : currentSession.concentrationSeconds
        
        return Double(self.remainSeconds) / Double(currentSeconds)  * 360.0
    }

    func subtractTimeElapsed(from last: Double) {
        let now: Double = Double(Date.now.timeIntervalSince1970)
        let diff: Int = Int((now - last).rounded())
        
        remainSeconds = knowIsInRestTime() ? currentSession.restTime - diff : currentSession.concentrationSeconds - diff
     
    }
    
//MARK: - Set Time
    func mapAllSessions() {
        let concentrationTime = timeSetting.session.concentrationTime
        let restTime = timeSetting.session.restTime
        var newSessions = [Session]()
        for index in 0..<timeSetting.numOfSessions {
            newSessions.append(Session(concentrationTime: concentrationTime,
                                       restTime: index == timeSetting.numOfSessions - 1 ?
                                       TimeSetting.longRefreshTime :
                                       restTime))
        }
        timeSetting.sessions = newSessions
    }
    
    func toggleLastLongRefresh(isOn: Bool) {
        timeSetting.sessions.removeLast()
        timeSetting.sessions.append(Session(concentrationTime: timeSetting.session.concentrationTime,
                                            restTime: isOn ? TimeSetting.longRefreshTime : 0))
    }
    

 
}

