struct AFMBridgeModelsResponse: Decodable, Sendable {
    struct Model: Codable, Sendable {
        let id: String
        let object: String
        let created: Int64
        let owner: String

        private enum CodingKeys: String, CodingKey {
            case id
            case object
            case created
            case owner = "owned_by"
        }
    }

    let object: String
    let data: [Model]
}
