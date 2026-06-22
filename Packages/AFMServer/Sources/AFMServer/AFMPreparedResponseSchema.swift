import FoundationModels

struct AFMPreparedResponseSchema {
    let name: String
    let generationSchema: GenerationSchema
    let fallbackTokenText: String
}
