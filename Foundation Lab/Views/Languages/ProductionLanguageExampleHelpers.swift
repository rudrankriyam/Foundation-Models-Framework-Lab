//
//  ProductionLanguageExampleHelpers.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import FoundationLabCore
import SwiftUI

extension ProductionLanguageExampleView {
    @ViewBuilder
    func implementationSectionView() -> some View {
        CodeDisclosure(
            code: """
let result = try await AnalyzeNutritionUseCase().execute(
    AnalyzeNutritionRequest(
        foodDescription: description,
        responseLanguage: language,
        context: CapabilityInvocationContext(
            source: .app,
            localeIdentifier: Locale.current.identifier
        )
    )
)

let analysis: NutritionAnalysis = result.analysis
print(analysis.foodName)
print(analysis.insights)
print(result.metadata.tokenCount ?? 0)
"""
        )
    }
}
