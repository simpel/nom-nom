import Foundation
import Parsing

/// Strongly-typed configuration parsed from command line and launch arguments.
struct LaunchConfiguration: Equatable {
    var initialTab: Int?
    var devSignInEmail: String?
    var seedSampleData: Bool = false
    var devSelfCheck: Bool = false
}

enum LaunchArgumentsParser {
    static func parse(arguments: [String] = ProcessInfo.processInfo.arguments) -> LaunchConfiguration {
        var config = LaunchConfiguration()

        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            switch arg {
            case "-initial-tab":
                if i + 1 < arguments.count, let tab = Int(arguments[i + 1]), (0...3).contains(tab) {
                    config.initialTab = tab
                    i += 1
                }
            case "-dev-sign-in":
                if i + 1 < arguments.count, !arguments[i + 1].hasPrefix("-") {
                    config.devSignInEmail = arguments[i + 1]
                    i += 1
                } else {
                    config.devSignInEmail = "dev@example.com"
                }
            case "-seed-sample-data":
                config.seedSampleData = true
            case "-dev-selfcheck":
                config.devSelfCheck = true
            default:
                break
            }
            i += 1
        }

        return config
    }
}
