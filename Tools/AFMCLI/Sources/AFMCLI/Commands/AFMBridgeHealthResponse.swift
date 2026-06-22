struct AFMBridgeHealthResponse: Decodable, Sendable {
    struct Model: Codable, Sendable {
        let name: String
        let available: Bool
    }

    let status: String
    let models: [Model]
}
