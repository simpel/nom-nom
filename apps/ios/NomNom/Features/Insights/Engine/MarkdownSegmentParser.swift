import Foundation

enum MarkdownSegmentParser {
    static func parse(_ text: String) -> [GuestNoteSegment] {
        var segments: [GuestNoteSegment] = []
        let pattern = "(\\*\\*.*?\\*\\*|~~.*?~~)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            
            var lastIndex = 0
            
            for match in matches {
                let matchRange = match.range
                
                if matchRange.location > lastIndex {
                    let prefix = nsText.substring(with: NSRange(location: lastIndex, length: matchRange.location - lastIndex))
                    segments.append(GuestNoteSegment(text: prefix, tone: .neutral))
                }
                
                let matchedString = nsText.substring(with: matchRange)
                if matchedString.hasPrefix("**") && matchedString.hasSuffix("**") {
                    let content = String(matchedString.dropFirst(2).dropLast(2))
                    segments.append(GuestNoteSegment(text: content, tone: .positive))
                } else if matchedString.hasPrefix("~~") && matchedString.hasSuffix("~~") {
                    let content = String(matchedString.dropFirst(2).dropLast(2))
                    segments.append(GuestNoteSegment(text: content, tone: .negative))
                }
                
                lastIndex = matchRange.location + matchRange.length
            }
            
            if lastIndex < nsText.length {
                let suffix = nsText.substring(from: lastIndex)
                segments.append(GuestNoteSegment(text: suffix, tone: .neutral))
            }
            
        } catch {
            segments.append(GuestNoteSegment(text: text, tone: .neutral))
        }
        
        return segments
    }
}
