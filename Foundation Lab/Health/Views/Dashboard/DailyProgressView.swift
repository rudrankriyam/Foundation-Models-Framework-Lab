//
//  DailyProgressView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

struct DailyProgressCard: View {
    let metricType: MetricType
    let currentValue: Double
    let goalValue: Double
    let animationNamespace: Namespace.ID
    @State private var animatedProgress: Double = 0

    private var progress: Double {
        min(currentValue / goalValue, 1.0)
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metricType.icon)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(progressPercentage)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(metricType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 4) {
                    Text(formattedValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("/ \(formattedGoal)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 4)

                    Capsule()
                        .fill(Color.primary.opacity(0.3))
                        .frame(width: geometry.size.width * animatedProgress, height: 4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .frame(width: 180)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metricType.rawValue): \(formattedValue) of \(formattedGoal)")
        .accessibilityValue("\(progressPercentage) percent complete")
        .onAppear {
            animatedProgress = progress
        }
    }

    private var progressColor: Color {
        switch progress {
        case 0.8...: return .successGreen
        case 0.5..<0.8: return .warningYellow
        default: return .alertRed
        }
    }

    private var formattedValue: String {
        switch metricType {
        case .steps, .activeEnergy:
            return "\(Int(currentValue))"
        case .sleep:
            return String(format: "%.1f", currentValue)
        default:
            return "\(Int(currentValue))"
        }
    }

    private var formattedGoal: String {
        switch metricType {
        case .steps, .activeEnergy:
            return "\(Int(goalValue))"
        case .sleep:
            return String(format: "%.0f hrs", goalValue)
        default:
            return "\(Int(goalValue))"
        }
    }
}

// MARK: - Activity Rings View
struct ActivityRingsView: View {
    let steps: Double
    let activeEnergy: Double
    let standHours: Int

    @State private var animateRings = false

    var body: some View {
        ZStack {
            // Stand Ring (Outer)
            ActivityRing(
                progress: Double(standHours) / 12.0,
                color: .primary,
                lineWidth: 8,
                radius: 60
            )

            // Active Energy Ring (Middle)
            ActivityRing(
                progress: activeEnergy / 500,
                color: .primary,
                lineWidth: 8,
                radius: 45
            )

            // Steps Ring (Inner)
            ActivityRing(
                progress: steps / 10000,
                color: .primary,
                lineWidth: 8,
                radius: 30
            )
        }
        .frame(width: 140, height: 140)
        .scaleEffect(animateRings ? 1.0 : 0.8)
        .opacity(animateRings ? 1.0 : 0.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Activity rings")
        .accessibilityValue(
            "Steps \(Int(min(steps / 10000, 1.0) * 100)) percent, "
                + "Active energy \(Int(min(activeEnergy / 500, 1.0) * 100)) percent, "
                + "Stand hours \(standHours) of 12"
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animateRings = true
            }
        }
    }
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let radius: CGFloat

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.1), lineWidth: lineWidth)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.2).delay(0.1), value: animatedProgress)
        }
        .accessibilityHidden(true)
        .onAppear {
            animatedProgress = min(progress, 1.0)
        }
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            DailyProgressCard(
                metricType: .steps,
                currentValue: 7234,
                goalValue: 10000,
                animationNamespace: Namespace().wrappedValue
            )

            DailyProgressCard(
                metricType: .activeEnergy,
                currentValue: 342,
                goalValue: 500,
                animationNamespace: Namespace().wrappedValue
            )

            DailyProgressCard(
                metricType: .sleep,
                currentValue: 6.5,
                goalValue: 8,
                animationNamespace: Namespace().wrappedValue
            )
        }
        .padding()
    }
}
