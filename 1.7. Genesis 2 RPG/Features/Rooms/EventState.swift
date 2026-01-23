import Foundation

struct EventState: Identifiable, Codable, Hashable {
    struct Option: Identifiable, Codable, Hashable {
        let id: UUID
        let title: String
        let toast: String

        init(title: String, toast: String) {
            self.id = UUID()
            self.title = title
            self.toast = toast
        }
    }

    let id: UUID
    let title: String
    let text: String
    let options: [Option]

    init(title: String, text: String, options: [Option]) {
        self.id = UUID()
        self.title = title
        self.text = text
        self.options = options
    }
}

