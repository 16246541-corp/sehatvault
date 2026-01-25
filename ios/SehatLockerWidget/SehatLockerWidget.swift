import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), iceData: "Locked • Tap to authenticate")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), iceData: "Locked • Tap to authenticate")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Read data from UserDefaults shared group
        // Note: You must enable App Groups in Xcode capabilities for both targets
        // and add "group.com.sehatlocker.widget"
        let userDefaults = UserDefaults(suiteName: "group.com.sehatlocker.widget")
        let iceData = userDefaults?.string(forKey: "ice_data") ?? "Locked • Tap to authenticate"
        
        let entry = SimpleEntry(date: Date(), iceData: iceData)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let iceData: String
}

struct SehatLockerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                    Text("Sehat Locker")
                        .font(.caption2)
                        .bold()
                }
                Text(entry.iceData)
                    .font(.caption)
                    .minimumScaleFactor(0.8)
            }
        case .accessoryInline:
            Text(entry.iceData)
        case .accessoryCircular:
            ZStack {
                Circle().stroke(lineWidth: 2)
                Image(systemName: "lock.shield.fill")
            }
        default:
            // Home Screen Widget
            VStack(alignment: .leading) {
                HStack {
                    // Placeholder for AppIcon if not available in asset catalog
                    Image(systemName: "lock.shield.fill") 
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    
                    Text("Sehat Locker")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(entry.iceData)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding()
        }
    }
}

@main
struct SehatLockerWidget: Widget {
    let kind: String = "SehatLockerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SehatLockerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sehat Locker")
        .description("Shows lock status and ICE contact.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}
