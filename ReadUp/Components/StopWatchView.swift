//
//  Timer.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//
import SwiftUI

struct StopWatchView: View {
    
    @State private var timer: Timer?
    @Binding var timeElapsed: Int

    
    var body: some View {
        HStack{
            Text(timeString(from: timeElapsed))
                .font(.largeTitle .bold())
                .padding()
                .onAppear{
                    startTimer()
                }
                .onDisappear{
                    stopTimer()
                }
            }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in timeElapsed += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        }
    
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
//
//#Preview {
//    StopWatchView(timeElapsed: <#Binding<Int>#>)
//}
