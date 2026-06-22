import Foundation

public struct AFMServerModel: Sendable, Equatable {
    public let id: String
    public let isAvailable: Bool
    public let owner: String

    public init(id: String, isAvailable: Bool, owner: String = "Apple") {
        self.id = id
        self.isAvailable = isAvailable
        self.owner = owner
    }
}

public protocol AFMModelCatalog: Sendable {
    func models() -> [AFMServerModel]
}

public struct AFMStaticModelCatalog: AFMModelCatalog {
    private let entries: [AFMServerModel]

    public init(models: [AFMServerModel]) {
        entries = models
    }

    public func models() -> [AFMServerModel] {
        entries
    }
}

public protocol AFMServerClock: Sendable {
    func unixTime() -> Int64
}

public struct AFMSystemServerClock: AFMServerClock {
    public init() {}

    public func unixTime() -> Int64 {
        Int64(Date().timeIntervalSince1970)
    }
}
