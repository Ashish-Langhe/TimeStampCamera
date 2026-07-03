import Foundation

protocol StampDateFormatting {
    func string(from date: Date) -> String
    func referenceStyleString(from date: Date) -> String
    func dateString(from date: Date) -> String
    func timeString(from date: Date) -> String
    func timestampString(from date: Date) -> String
}

struct DefaultStampDateFormatter: StampDateFormatting {
    private let formatter: DateFormatter
    private let referenceFormatter: DateFormatter
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let timestampFormatter: ISO8601DateFormatter

    init(timeZone: TimeZone = .current, locale: Locale = .current) {
        formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = locale
        formatter.dateFormat = "dd MMM yyyy, h:mm a"

        referenceFormatter = DateFormatter()
        referenceFormatter.timeZone = timeZone
        referenceFormatter.locale = locale
        referenceFormatter.dateFormat = "MMM d, yyyy 'at' h:mm:ss a"

        dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = locale
        dateFormatter.dateFormat = "dd MMM yyyy"

        timeFormatter = DateFormatter()
        timeFormatter.timeZone = timeZone
        timeFormatter.locale = locale
        timeFormatter.dateFormat = "h:mm:ss a zzz"

        timestampFormatter = ISO8601DateFormatter()
        timestampFormatter.timeZone = timeZone
        timestampFormatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    }

    func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    func referenceStyleString(from date: Date) -> String {
        referenceFormatter.string(from: date)
    }

    func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    func timeString(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    func timestampString(from date: Date) -> String {
        timestampFormatter.string(from: date)
    }
}
