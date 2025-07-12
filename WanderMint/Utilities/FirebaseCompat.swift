import Foundation

// MARK: - Firebase Compatibility Layer
// This file provides compatibility types when Firebase is not available

#if canImport(FirebaseFirestore)
import FirebaseFirestore
public typealias AppTimestamp = Timestamp
public typealias AppDocumentReference = DocumentReference
public typealias AppCollectionReference = CollectionReference
public typealias AppQuery = Query
public typealias AppDocumentSnapshot = DocumentSnapshot
public typealias AppQuerySnapshot = QuerySnapshot
#else
// Fallback implementations when Firebase is not available

public struct AppTimestamp: Codable, Equatable {
    public let seconds: Int64
    public let nanoseconds: Int32
    
    public init() {
        let now = Date()
        self.seconds = Int64(now.timeIntervalSince1970)
        self.nanoseconds = Int32((now.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
    }
    
    public init(date: Date) {
        self.seconds = Int64(date.timeIntervalSince1970)
        self.nanoseconds = Int32((date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
    }
    
    public var dateValue: Date {
        return Date(timeIntervalSince1970: Double(seconds) + Double(nanoseconds) / 1_000_000_000)
    }
}

// Mock Firebase types for compilation
public struct AppDocumentReference {
    public let path: String
    
    public init(path: String) {
        self.path = path
    }
}

public struct AppCollectionReference {
    public let path: String
    
    public init(path: String) {
        self.path = path
    }
}

public struct AppQuery {
    public let path: String
    
    public init(path: String) {
        self.path = path
    }
}

public struct AppDocumentSnapshot {
    public let data: [String: Any]?
    public let exists: Bool
    
    public init(data: [String: Any]? = nil, exists: Bool = false) {
        self.data = data
        self.exists = exists
    }
}

public struct AppQuerySnapshot {
    public let documents: [AppDocumentSnapshot]
    
    public init(documents: [AppDocumentSnapshot] = []) {
        self.documents = documents
    }
}

#endif

// MARK: - Common Firebase Functions
#if canImport(FirebaseFirestore)
public func createTimestamp() -> AppTimestamp {
    return Timestamp()
}

public func createTimestamp(date: Date) -> AppTimestamp {
    return Timestamp(date: date)
}
#else
public func createTimestamp() -> AppTimestamp {
    return AppTimestamp()
}

public func createTimestamp(date: Date) -> AppTimestamp {
    return AppTimestamp(date: date)
}
#endif