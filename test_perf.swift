import Foundation

func measure(name: String, _ block: () -> Void) {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let end = CFAbsoluteTimeGetCurrent()
    print("\(name) took \(end - start) seconds")
}

measure(name: "Creating formatter repeatedly") {
    for _ in 0..<10000 {
        let formatter = ISO8601DateFormatter()
        _ = formatter.string(from: Date())
    }
}

let sharedFormatter = ISO8601DateFormatter()
measure(name: "Using shared formatter") {
    for _ in 0..<10000 {
        _ = sharedFormatter.string(from: Date())
    }
}
