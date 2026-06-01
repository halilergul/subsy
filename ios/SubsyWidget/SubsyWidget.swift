import WidgetKit
import SwiftUI

// Subsy home-screen widget (iOS, WidgetKit). A dumb renderer: it reads the
// display-ready strings the Flutter side writes into the shared App Group
// UserDefaults (see widget_keys.dart) and renders them. Tapping opens the app.
//
// NOTE: verified on a real device/simulator. This source is scaffolded; the
// Xcode widget-extension target + App Group capability must be added in Xcode
// (project.pbxproj wiring is not scripted here). App Group: group.com.halilergul.subsy

private let appGroupId = "group.com.halilergul.subsy"

struct SubsyEntry: TimelineEntry {
    let date: Date
    let state: String
    let nextTitle: String
    let nextWhen: String
    let nextAmount: String
    let totalLine: String
    let unifiedLine: String
}

struct Provider: TimelineProvider {
    private func read() -> SubsyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return SubsyEntry(
            date: Date(),
            state: defaults?.string(forKey: "state") ?? "empty",
            nextTitle: defaults?.string(forKey: "next_title") ?? "",
            nextWhen: defaults?.string(forKey: "next_when") ?? "",
            nextAmount: defaults?.string(forKey: "next_amount") ?? "",
            totalLine: defaults?.string(forKey: "total_line") ?? "",
            unifiedLine: defaults?.string(forKey: "unified_line") ?? ""
        )
    }

    func placeholder(in context: Context) -> SubsyEntry {
        SubsyEntry(date: Date(), state: "empty", nextTitle: "", nextWhen: "",
                   nextAmount: "", totalLine: "", unifiedLine: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (SubsyEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubsyEntry>) -> Void) {
        // The app pushes updates via home_widget; a single entry + .never policy
        // means we render whatever is currently stored.
        completion(Timeline(entries: [read()], policy: .never))
    }
}

struct SubsyWidgetEntryView: View {
    var entry: SubsyEntry
    private let muted = Color(red: 0.60, green: 0.60, blue: 0.64)

    var body: some View {
        Group {
            switch entry.state {
            case "ready": ready
            case "locked":
                Text("Premium ile aboneliklerini ana ekranda gör")
                    .font(.caption).foregroundColor(muted)
                    .multilineTextAlignment(.center)
            default:
                Text("Abonelik ekle").font(.subheadline).foregroundColor(muted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background(Color(red: 0.09, green: 0.09, blue: 0.11)) // 0xFF17171D
        .widgetURL(URL(string: "subsy://open"))
    }

    private var ready: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.nextTitle).font(.headline).foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text(entry.nextAmount).font(.headline).foregroundColor(.white)
            }
            Text(entry.nextWhen).font(.caption).foregroundColor(muted)
            Divider().background(muted).padding(.vertical, 8)
            Text("Aylık").font(.caption2).foregroundColor(muted)
            Text(entry.totalLine).font(.subheadline).bold().foregroundColor(.white)
                .lineLimit(1)
            if !entry.unifiedLine.isEmpty {
                Text(entry.unifiedLine).font(.caption).foregroundColor(muted)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct SubsyWidget: Widget {
    let kind: String = "SubsyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SubsyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Subsy")
        .description("Sıradaki ödeme ve aylık toplam.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
