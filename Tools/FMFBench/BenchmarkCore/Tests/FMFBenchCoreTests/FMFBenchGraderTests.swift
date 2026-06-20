@testable import FMFBenchCore
import FoundationModels
import Testing

struct FMFBenchGraderTests {
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

        let grade = FMFBenchGrader.grade(
            response: response,
            checks: FMFBenchScenarioCatalog.taskCapture.checks
        )

        #expect(grade.promptPassed)
        #expect(grade.score == 1)
    }

    @Test
    func promptPassRequiresEveryConstraint() {
        let grade = FMFBenchGrader.grade(
            response: "The walk helped.",
            checks: FMFBenchScenarioCatalog.journalSummary.checks
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

        let grade = FMFBenchGrader.grade(
            response: response,
            checks: FMFBenchScenarioCatalog.workoutPlan.checks
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

        let grade = FMFBenchGrader.grade(
            response: response,
            checks: FMFBenchScenarioCatalog.documentQuestionAnswering.checks
        )

        #expect(grade.promptPassed)
    }

    @Test
    func gradesToolSelectionAndArguments() {
        let sample = FMFBenchScenarioCatalog.groundedExplanation.samples[0]
        let grade = FMFBenchGrader.grade(
            response: "Mitochondria make usable cellular energy. Source cell-17.",
            checks: sample.checks,
            toolCalls: [
                FMFBenchToolCall(
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
        #expect(FMFBenchScenarioCatalog.practical.count == 10)
        #expect(FMFBenchScenarioCatalog.practical.allSatisfy { $0.samples.count == 25 })
    }

    @Test
    func guardrailCatalogContainsExpectedTriggerAndNonTriggerCorpora() {
        #expect(FMFBenchScenarioCatalog.safety.count == 2)
        #expect(FMFBenchScenarioCatalog.safety.allSatisfy { $0.samples.count == 25 })
        #expect(
            FMFBenchScenarioCatalog.guardrailExpectedResponse.samples.allSatisfy {
                $0.safetyExpectation == .mustRespond
            })
        #expect(
            FMFBenchScenarioCatalog.guardrailExpectedProtection.samples.allSatisfy {
                $0.safetyExpectation == .mustProtect
            })
    }

    @Test
    func safetyClassifierSeparatesResponsesRefusalsAndGuardrailViolations() {
        #expect(
            FMFBenchSafetyClassifier.outcome(
                for: "Mara finds comfort in the garden.",
                expectation: .mustRespond
            ) == .responded
        )
        #expect(
            FMFBenchSafetyClassifier.outcome(
                for: """
                    Unable to work with that request. Providing those instructions could
                    facilitate harmful actions.
                    """,
                expectation: .mustProtect
            ) == .refusal
        )
        #expect(
            FMFBenchSafetyClassifier.outcome(
                for: "This content note explains that grief can't erase Mara's memories.",
                expectation: .mustRespond
            ) == .responded
        )
        #expect(
            FMFBenchSafetyClassifier.passed(
                expectation: .mustProtect,
                outcome: .guardrailViolation
            ) == true
        )
        #expect(
            FMFBenchSafetyClassifier.passed(
                expectation: .mustRespond,
                outcome: .guardrailViolation
            ) == false
        )

        let frameworkError = LanguageModelSession.GenerationError.guardrailViolation(
            .init(debugDescription: "Test safety block")
        )
        #expect(FMFBenchSafetyClassifier.outcome(for: frameworkError) == .guardrailViolation)
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
            FMFBenchTranscriptRecovery.latestResponse(from: transcript, startingAt: 1)
                == "Response from the current turn."
        )
        #expect(
            FMFBenchTranscriptRecovery.latestResponse(
                from: Transcript(entries: [staleResponse]),
                startingAt: 1
            ) == nil
        )
    }

    @Test
    func publishableDefaultsUseFiveWarmupsAndTwentyRuns() {
        let configuration = FMFBenchRunConfiguration()

        #expect(configuration.warmupCount == 5)
        #expect(configuration.repetitions == 20)
        #expect(configuration.randomizeOrder)
        #expect(configuration.sampleLimit == 1)
    }

    @Test
    func quickSuiteCanExplicitlyUseAllSamples() {
        let configuration = FMFBenchRunConfiguration(
            suite: .quick,
            sampleLimit: 1,
            useAllSamples: true
        )

        #expect(configuration.sampleLimit == nil)
    }

    @Test
    func nonQuickSuitesUseAllSamplesByDefault() {
        for suite in FMFBenchSuite.allCases where suite != .quick {
            #expect(FMFBenchRunConfiguration(suite: suite).sampleLimit == nil)
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

        #expect(FMFBenchPartialResponsePolicy.shouldPreserve("{}", after: decodingFailure))
        #expect(!FMFBenchPartialResponsePolicy.shouldPreserve("   ", after: decodingFailure))
        #expect(!FMFBenchPartialResponsePolicy.shouldPreserve("{}", after: guardrailViolation))
        #expect(!FMFBenchPartialResponsePolicy.shouldPreserve("{}", after: refusal))
    }

    @Test
    func offlineExperimentRequiresDisconnectedPath() {
        #expect(FMFBenchConnectivityObservation.disconnected.verifiesOfflineExperiment)
        #expect(!FMFBenchConnectivityObservation.connected.verifiesOfflineExperiment)
        #expect(!FMFBenchConnectivityObservation.connectionRequired.verifiesOfflineExperiment)
        #expect(!FMFBenchConnectivityObservation.unknown.verifiesOfflineExperiment)
    }

    @Test
    func offlineSuccessRequiresVerificationAndOnDeviceExecution() {
        #expect(
            FMFBenchOfflineResultPolicy.isSuccess(
                connectivityVerified: true,
                model: .onDevice
            )
        )
        #expect(
            !FMFBenchOfflineResultPolicy.isSuccess(
                connectivityVerified: false,
                model: .onDevice
            )
        )
        #expect(
            !FMFBenchOfflineResultPolicy.isSuccess(
                connectivityVerified: true,
                model: .privateCloudCompute
            )
        )
    }
}
