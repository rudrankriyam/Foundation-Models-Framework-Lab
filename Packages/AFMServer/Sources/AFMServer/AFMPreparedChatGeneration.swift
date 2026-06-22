import FoundationModels

struct AFMPreparedChatGeneration {
    let transcript: Transcript
    let prompt: Prompt
    let inputTranscript: Transcript
    let options: GenerationOptions
    let responseSchema: AFMPreparedResponseSchema?
}
