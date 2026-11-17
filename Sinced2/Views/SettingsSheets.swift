//
//  SettingsSheets.swift
//  Sinced2
//
//  The sheets opened from Settings: About Sinced and About the developer,
//  plus the entrance motion their content shares.
//

import SwiftUI

// MARK: - Entrance

extension View {
    /// Rises into place as the sheet arrives, one beat after the item above.
    /// Sheets open occasionally, so the content gets a gentle settle: 10pt,
    /// a strong ease-out, items 50ms apart. Reduce Motion keeps only the fade.
    func sheetEntrance(_ order: Int) -> some View {
        modifier(SheetEntrance(order: order))
    }
}

private struct SheetEntrance: ViewModifier {
    let order: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 10)
            .onAppear {
                // Starts while the sheet is still sliding up, so the two read as one motion
                let delay = 0.1 + Double(order) * 0.05
                withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: reduceMotion ? 0.2 : 0.5).delay(delay)) {
                    shown = true
                }
            }
    }
}

// MARK: - About Sinced

struct AboutSincedSheet: View {
    private struct Point: Identifiable {
        let icon: String
        let title: String
        let detail: String
        var id: String { title }
    }

    private let points = [
        Point(icon: "clock.arrow.circlepath", title: "Count the time since anything",
              detail: "Quitting, starting, or simply remembering."),
        Point(icon: "square.grid.2x2", title: "Always in sight",
              detail: "Widgets for your Home Screen, Lock Screen and Control Center."),
        Point(icon: "flag", title: "Goals and milestones",
              detail: "Set a goal, and get a moment worth sharing when you reach it."),
        Point(icon: "arrow.uturn.backward", title: "Slips happen",
              detail: "Every run is kept, and a reset made by mistake can be undone."),
        Point(icon: "lock", title: "Private by design",
              detail: "No account and no ads. Your events stay on your phone.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 68, height: 68)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .accessibilityHidden(true)
                        .sheetEntrance(0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sinced")
                            .font(.rounded(26, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Keep the moments that matter in sight.")
                            .font(.roundedBody)
                            .foregroundColor(.secondary)
                    }
                    .sheetEntrance(1)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: point.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primaryGreen)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Color.primaryGreen.opacity(0.1)))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(point.title)
                                    .font(.rounded(16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(point.detail)
                                    .font(.roundedSubheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 1)
                        }
                        .accessibilityElement(children: .combine)
                        .sheetEntrance(2 + index)
                    }
                }

                Text(AppVersion.label)
                    .font(.roundedCaption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .sheetEntrance(2 + points.count)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
            .sheetHeightPart()
        }
        .scrollBounceBehavior(.basedOnSize)
        .fittedSheet(estimate: 560)
    }
}

// MARK: - About the developer

struct DeveloperSheet: View {
    @Environment(\.openURL) private var openURL

    private struct LinkRow: Identifiable {
        let icon: String
        let title: String
        let value: String
        let url: URL
        var id: String { title }
    }

    private let links = [
        LinkRow(icon: "globe", title: "Website", value: "adityakolte.com", url: URL(string: "https://adityakolte.com/")!),
        LinkRow(icon: "at", title: "X (Twitter)", value: "@adityakvlte", url: URL(string: "https://x.com/adityakvlte")!)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Image("DeveloperPhoto")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .cardEdge(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .accessibilityLabel("Illustrated portrait of Aditya Kolte")
                    .padding(.bottom, 22)
                    .sheetEntrance(0)

                Text("Made by Aditya Kolte")
                    .font(.rounded(24, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                    .sheetEntrance(1)

                Text("I built Sinced to keep the moments that matter in sight. It’s free, with no ads and no account. If it helps you, say hi.")
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)
                    .sheetEntrance(2)

                VStack(spacing: 0) {
                    ForEach(Array(links.enumerated()), id: \.element.id) { index, link in
                        Button {
                            HapticManager.shared.light()
                            openURL(link.url)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: link.icon)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                    .frame(width: 22)
                                Text(link.title)
                                    .font(.roundedBody)
                                    .foregroundColor(.primary)
                                Spacer(minLength: 8)
                                Text(link.value)
                                    .font(.roundedBody)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(RowPressStyle())
                        .accessibilityHint("Opens \(link.value)")

                        if index < links.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AddEventBottomSheet.fieldFill)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .sheetEntrance(3)

                Text(AppVersion.label)
                    .font(.roundedCaption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .padding(.top, 16)
                    .padding(.leading, 4)
                    .sheetEntrance(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
            .sheetHeightPart()
        }
        .scrollBounceBehavior(.basedOnSize)
        .fittedSheet(estimate: 440)
    }
}

/// A list row that dims a little while pressed, like the system's
private struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.black.opacity(configuration.isPressed ? 0.05 : 0))
            .animation(.easeOut(duration: configuration.isPressed ? 0.08 : 0.2), value: configuration.isPressed)
    }
}

// MARK: - Version

enum AppVersion {
    /// "Sinced 1.1 (4)"
    static var label: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? "Sinced \(version)" : "Sinced \(version) (\(build))"
    }
}
