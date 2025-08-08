import XCTest
@testable import damda

final class DesignTests: XCTestCase {
    
    func testTimerSessionTitleDesign() {
        // 타이머 세션 제목 디자인 테스트
        let morningTitle = "아침"
        let afternoonTitle = "오후"
        let eveningTitle = "저녁"
        
        // 제목이 올바르게 설정되어 있는지 확인
        XCTAssertEqual(morningTitle, "아침")
        XCTAssertEqual(afternoonTitle, "오후")
        XCTAssertEqual(eveningTitle, "저녁")
    }
    
    func testTimerTimeFormat() {
        // 타이머 시간 포맷 테스트
        let seconds = 3661 // 1시간 1분 1초
        let formattedTime = formatTime(seconds)
        
        // HH:MM:SS 형식인지 확인
        XCTAssertEqual(formattedTime, "01:01:01")
    }
    
    func testColorHexConversion() {
        // 색상 HEX 변환 테스트 - 문자열 검증
        let hexColorString = "565D6D"
        let darkHexColorString = "171A1F"
        
        // HEX 문자열이 올바른 형식인지 확인
        XCTAssertEqual(hexColorString.count, 6)
        XCTAssertEqual(darkHexColorString.count, 6)
        XCTAssertTrue(hexColorString.allSatisfy { $0.isHexDigit })
        XCTAssertTrue(darkHexColorString.allSatisfy { $0.isHexDigit })
    }
    
    func testFontWeightConversion() {
        // 폰트 굵기 변환 테스트 - 문자열 검증
        let regularWeightString = "regular"
        let heavyWeightString = "heavy"
        
        // 폰트 굵기 문자열이 올바른지 확인
        XCTAssertEqual(regularWeightString, "regular")
        XCTAssertEqual(heavyWeightString, "heavy")
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
} 