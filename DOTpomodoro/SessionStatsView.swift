import SwiftUI

struct SessionStatsView: View {
    let workSessions: Int
    let breakSessions: Int
    let totalFocusTime: TimeInterval
    let sessionDuration: TimeInterval
    let onDismiss: () -> Void
    
    private let primaryColor = Color(hex: "F07167")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 42))
                    .foregroundColor(primaryColor)
                    .padding(.top, 8)
                
                Text("Session Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Great work! Here's your session summary:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)
            
            // Stats Grid Section
            VStack(spacing: 0) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    SessionStatCard(
                        title: "Focus Sessions",
                        value: "\(workSessions)",
                        subtitle: "completed",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    SessionStatCard(
                        title: "Break Sessions",
                        value: "\(breakSessions)",
                        subtitle: "taken",
                        icon: "cup.and.saucer.fill",
                        color: .blue
                    )
                    
                    SessionStatCard(
                        title: "Total Focus Time",
                        value: formatTime(totalFocusTime),
                        subtitle: totalFocusTime >= 3600 ? "hours" : "minutes",
                        icon: "clock.fill",
                        color: primaryColor
                    )
                    
                    SessionStatCard(
                        title: "Session Duration",
                        value: formatTime(sessionDuration),
                        subtitle: sessionDuration >= 3600 ? "hours" : "minutes",
                        icon: "stopwatch.fill",
                        color: .green
                    )
                }
                .padding(.horizontal, 32)
                
                // Achievement Badge (if applicable)
                if workSessions >= 4 {
                    VStack(spacing: 10) {
                        Image(systemName: "rosette")
                            .font(.system(size: 28))
                            .foregroundColor(.yellow)
                        
                        Text("Achievement Unlocked!")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Completed \(workSessions) focus sessions in one go!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.yellow.opacity(0.1))
                            .stroke(.yellow.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                }
            }
            
            Spacer(minLength: 20)
            
            // Bottom Action Section
            VStack(spacing: 0) {
                Button("Continue") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(primaryColor)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .frame(minWidth: 380, maxWidth: 420)
        .frame(minHeight: 460, maxHeight: 520)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%.1f", Double(timeInterval) / 3600.0)
        } else {
            return "\(minutes)"
        }
    }
}

// Custom StatCard for SessionStatsView to avoid naming conflicts
private struct SessionStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .padding(.top, 2)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            VStack(spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}



#Preview {
    SessionStatsView(
        workSessions: 5,
        breakSessions: 4,
        totalFocusTime: 2.5 * 3600, // 2.5 hours
        sessionDuration: 3 * 3600,   // 3 hours
        onDismiss: {}
    )
} 