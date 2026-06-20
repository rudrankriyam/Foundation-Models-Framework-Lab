import FoundationModels

extension Transcript {
    func latestResponseText(after entryCount: Int) -> String {
        for entry in dropFirst(entryCount).reversed() {
            switch entry {
            case .response:
                return entry.textContent() ?? ""
            case .prompt:
                return ""
            default:
                continue
            }
        }
        return ""
    }
}
