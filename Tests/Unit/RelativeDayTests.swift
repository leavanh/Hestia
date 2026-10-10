import Testing
@testable import Habitus

/// Beschriftung des angezeigten Tags (Spezifikation 5.2).
struct RelativeDayTests {
    @Test func namesTodayYesterdayAndTheDayBefore() {
        #expect(RelativeDay.text(daysAgo: 0) == "Heute")
        #expect(RelativeDay.text(daysAgo: 1) == "Gestern")
        #expect(RelativeDay.text(daysAgo: 2) == "Vorgestern")
    }

    @Test func countsOlderDays() {
        #expect(RelativeDay.text(daysAgo: 3) == "Vor 3 Tagen")
        #expect(RelativeDay.text(daysAgo: 30) == "Vor 30 Tagen")
    }
}
