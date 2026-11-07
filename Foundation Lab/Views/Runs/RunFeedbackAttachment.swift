//
//  RunFeedbackAttachment.swift
//  Foundation Lab
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct RunFeedbackAttachment: Transferable {
    let data: Data
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { attachment in
            attachment.data
        }
        .suggestedFileName { $0.fileName }
    }
}
