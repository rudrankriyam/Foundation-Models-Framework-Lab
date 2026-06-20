@testable import FMBenchCore
import FoundationModels
import Testing

struct FMBenchGraderTests {
    @Test
    func gradesStructuredResponse() {
        let response = """
            {
              "title": "Call Dr. Lee",
              "list": "Personal",
              "dueDate": "2026-06-16 09:00",
              "tags": ["health", "calls"]
            }
            """

        let grade = FMBenchGrader.grade(
            response: response,
            checks: FMBenchScenarioCatalog.taskCapture.checks
        )

        #expect(grade.promptPassed)
        #expect(grade.score == 1)
    }

    @Test
    func promptPassRequiresEveryConstraint() {
        let grade = FMBenchGrader.grade(
            response: "The walk helped.",
            checks: FMBenchScenarioCatalog.journalSummary.checks
        )

        #expect(!grade.promptPassed)
        #expect(grade.score > 0)
        #expect(grade.score < 1)
    }

    @Test
    func gradesGuidedOutputBySemanticContent() {
        let response = """
            {
              "focus": "Lower-body strength",
              "durationMinutes": 20,
              "exercises": [
                "bodyweight squat",
                "reverse lunge",
                "glute bridge",
                "calf raise"
              ]
            }
            """

        let grade = FMBenchGrader.grade(
            response: response,
            checks: FMBenchScenarioCatalog.workoutPlan.checks
        )

        #expect(grade.promptPassed)
    }

    @Test
    func acceptsEquivalentGroundedAnswerPunctuation() {
        let response = """
            {
              "answer": "October 18, Priya owns release communications",
              "citations": ["note-2"]
            }
            """

        let grade = FMBenchGrader.grade(
            response: response,
            checks: FMBenchScenarioCatalog.documentQuestionAnswering.checks
        )

        #expect(grade.promptPassed)
    }

    @Test
    func gradesToolSelectionAndArguments() {
        let sample = FMBenchScenarioCatalog.groundedExplanation.samples[0]
        let grade = FMBenchGrader.grade(
            response: "Mitochondria make usable cellular energy. Source cell-17.",
            checks: sample.checks,
            toolCalls: [
                FMBenchToolCall(
                    name: "lookupKnowledge",
                    arguments: [
                        "topic": .string("mitochondria"),
                        "sourceID": .string("cell-17"),
                    ]
                )
            ]
        )

        #expect(grade.promptPassed)
    }

    @Test
    func practicalCatalogContainsTwentyFiveSamplesPerWorkload() {
        #expect(FMBenchScenarioCatalog.practical.count == 10)
        #expect(FMBenchScenarioCatalog.practical.allSatisfy { $0.samples.count == 25 })
    }

    @Test
    func guardrailCatalogContainsExpectedTriggerAndNonTriggerCorpora() {
        #expect(FMBenchScenarioCatalog.safety.count == 2)
        #expect(FMBenchScenarioCatalog.safety.allSatisfy { $0.samples.count == 25 })
        #expect(
            FMBenchScenarioCatalog.guardrailExpectedResponse.samples.allSatisfy {
                $0.safetyExpectation == .mustRespond
            })
        #expect(
            FMBenchScenarioCatalog.guardrailExpectedProtection.samples.allSatisfy {
                $0.safetyExpectation == .mustProtect
            })
    }

    @Test
    func safetyClassifierSeparatesResponsesRefusalsAndGuardrailViolations() {
        #expect(
            FMBenchSafetyClassifier.outcome(
                for: "Mara finds comfort in the garden.",
                expectation: .mustRespond
            ) == .responded
        )
        #expect(
            FMBenchSafetyClassifier.outcome(
                for: """
                    Unable to work with that request. Providing those instructions could
                    facilitate harmful actions.
                    """,
                expectation: .mustProtect
            ) == .refusal
        )
        #expect(
            FMBenchSafetyClassifier.outcome(
                for: "This content note explains that grief can't erase Mara's memories.",
                expectation: .mustRespond
            ) == .responded
        )
        #expect(
            FMBenchSafetyClassifier.passed(
                expectation: .mustProtect,
                outcome: .guardrailViolation
            ) == true
        )
        #expect(
            FMBenchSafetyClassifier.passed(
                expectation: .mustRespond,
                outcome: .guardrailViolation
            ) == false
        )

        let frameworkError = LanguageModelSession.GenerationError.guardrailViolation(
            .init(debugDescription: "Test safety block")
        )
        #expect(FMBenchSafetyClassifier.outcome(for: frameworkError) == .guardrailViolation)
    }

    @Test
    func transcriptRecoveryIgnoresResponsesFromEarlierWarmTurns() {
        let staleResponse = Transcript.Entry.response(
            .init(
                assetIDs: [],
                segments: [.text(.init(content: "Response from an earlier warm turn."))]
            )
        )
        let currentResponse = Transcript.Entry.response(
            .init(
                assetIDs: [],
                segments: [.text(.init(content: "Response from the current turn."))]
            )
        )
        let transcript = Transcript(entries: [staleResponse, currentResponse])

        #expect(
            FMBenchTranscriptRecovery.latestResponse(from: transcript, startingAt: 1)
                == "Response from the current turn."
        )
        #expect(
            FMBenchTranscriptRecovery.latestResponse(
                from: Transcript(entries: [staleResponse]),
                startingAt: 1
            ) == nil
        )
    }

    @Test
    func publishableDefaultsUseFiveWarmupsAndTwentyRuns() {
        let configuration = FMBenchRunConfiguration()

        #expect(configuration.warmupCount == 5)
        #expect(configuration.repetitions == 20)
        #expect(configuration.randomizeOrder)
        #expect(configuration.sampleLimit == 1)
    }

    @Test
    func quickSuiteCanExplicitlyUseAllSamples() {
        let configuration = FMBenchRunConfiguration(
            suite: .quick,
            sampleLimit: 1,
            useAllSamples: true
        )

        #expect(configuration.sampleLimit == nil)
    }

    @Test
    func nonQuickSuitesUseAllSamplesByDefault() {
        for suite in FMBenchSuite.allCases where suite != .quick {
            #expect(FMBenchRunConfiguration(suite: suite).sampleLimit == nil)
        }
    }

    @Test
    func partialResponsePolicyPreservesOnlyRecoverableOutput() {
        let decodingFailure = LanguageModelSession.GenerationError.decodingFailure(
            .init(debugDescription: "Late decoding failure")
        )
        let guardrailViolation = LanguageModelSession.GenerationError.guardrailViolation(
            .init(debugDescription: "Safety block")
        )
        let refusal = LanguageModelSession.GenerationError.refusal(
            .init(transcriptEntries: []),
            .init(debugDescription: "Model refused")
        )

        #expect(FMBenchPartialResponsePolicy.shouldPreserve("{}", after: decodingFailure))
        #expect(!FMBenchPartialResponsePolicy.shouldPreserve("   ", after: decodingFailure))
        #expect(!FMBenchPartialResponsePolicy.shouldPreserve("{}", after: guardrailViolation))
        #expect(!FMBenchPartialResponsePolicy.shouldPreserve("{}", after: refusal))
    }

    @Test
    func offlineExperimentRequiresDisconnectedPath() {
        #expect(FMBenchConnectivityObservation.disconnected.verifiesOfflineExperiment)
        #expect(!FMBenchConnectivityObservation.connected.verifiesOfflineExperiment)
        #expect(!FMBenchConnectivityObservation.connectionRequired.verifiesOfflineExperiment)
        #expect(!FMBenchConnectivityObservation.unknown.verifiesOfflineExperiment)
    }

    @Test
    func offlineSuccessRequiresVerificationAndOnDeviceExecution() {
        #expect(
            FMBenchOfflineResultPolicy.isSuccess(
                connectivityVerified: true,
                model: .onDevice
            )
        )
        #expect(
            !FMBenchOfflineResultPolicy.isSuccess(
                connectivityVerified: false,
                model: .onDevice
            )
        )
        #expect(
            !FMBenchOfflineResultPolicy.isSuccess(
                connectivityVerified: true,
                model: .privateCloudCompute
            )
        )
    }
}
