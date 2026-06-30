import Foundation

// Real app experience prompts inspired by Apple's public Foundation Models
// app showcase. The prompts are repo-owned fixtures, not copied app text.
// swiftlint:disable file_length line_length
extension FMFBenchScenarioCatalog {
    public static let appExperiences: [FMFBenchScenario] = [
        appWorkoutAdaptation,
        appJournalReflection,
        appSportsFeedback,
        appExerciseSubstitution,
        appCreatorMetadata,
        appCitationExtraction,
        appProjectCapture,
        appDocumentQuestionAnswering,
        appLearningExplanation,
        appSupportReply
    ]

    public static let appWorkoutAdaptation = FMFBenchScenario(
        id: "app-workout-adaptation",
        title: "Workout adaptation from user constraints",
        summary: "Builds a structured workout plan from duration, equipment, and recovery constraints.",
        category: .workoutGeneration,
        inspiredBy: ["SmartGym"],
        instructions: """
            Create a safe, concise workout plan that follows every stated constraint.
            Return only the requested structured workout fields.
            """,
        outputMode: .guided(.workout),
        maximumResponseTokens: 180,
        samples: [
            .init(
                id: "app-workout-adaptation-001",
                prompt: """
                    Create a 14-minute travel workout for a hotel room. Use exactly four exercises:
                    wall sit, incline push-up, dead bug, and suitcase march. The user has a sore knee,
                    so keep the focus low-impact lower-body and core. Return durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(14)),
                    .jsonContains(path: "focus", values: ["low-impact"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["wall sit", "incline push-up", "dead bug", "suitcase march"]
                    ),
                    .excludes("jump")
                ]
            )
        ]
    )

    public static let appJournalReflection = FMFBenchScenario(
        id: "app-journal-reflection",
        title: "Grounded journal reflection",
        summary: "Reflects on a private journal entry without diagnosis or invented events.",
        category: .summarization,
        inspiredBy: ["Stoic"],
        instructions: """
            Write exactly two sentences grounded only in the journal entry. Mention one positive
            moment and one practical next step. Do not diagnose the writer.
            """,
        outputMode: .text,
        maximumResponseTokens: 110,
        samples: [
            .init(
                id: "app-journal-reflection-001",
                prompt: """
                    Journal entry: I felt scattered after three context switches this morning, but
                    the quiet walk after lunch helped. I finished the onboarding draft and enjoyed
                    calling my sister. Tomorrow I want to start by blocking messages for the first hour.
                    """,
                checks: [
                    .contains("walk"),
                    .contains("onboarding draft"),
                    .contains("blocking messages"),
                    .excludes("diagnos"),
                    .maximumWords(60)
                ]
            )
        ]
    )

    public static let appSportsFeedback = FMFBenchScenario(
        id: "app-sports-feedback",
        title: "Sports coaching feedback",
        summary: "Turns sports session observations into concise coaching feedback.",
        category: .summarization,
        inspiredBy: ["SwingVision"],
        instructions: """
            Give concise, actionable feedback from the recorded observations only. Include one
            strength, one adjustment, and one next drill. Do not invent biometrics.
            """,
        outputMode: .text,
        maximumResponseTokens: 130,
        samples: [
            .init(
                id: "app-sports-feedback-001",
                prompt: """
                    Tennis session notes: First serve landed 62 percent in. Backhand return depth
                    improved in the final set. Forehand contact drifted late on wide balls. The player
                    wants one drill for the next practice.
                    """,
                checks: [
                    .contains("62"),
                    .contains("backhand"),
                    .contains("forehand"),
                    .containsAny(["wide balls", "late"]),
                    .contains("drill"),
                    .excludes("heart rate"),
                    .maximumWords(80)
                ]
            )
        ]
    )

    public static let appExerciseSubstitution = FMFBenchScenario(
        id: "app-exercise-substitution",
        title: "Exercise substitution under constraints",
        summary: "Recommends a replacement exercise that fits equipment and limitation constraints.",
        category: .exerciseSubstitution,
        inspiredBy: ["Train Fitness"],
        instructions: """
            Recommend one substitute exercise and explain the fit in one sentence. Use only the
            supplied catalog entry and preserve the stated limitation.
            """,
        outputMode: .text,
        maximumResponseTokens: 90,
        samples: [
            .init(
                id: "app-exercise-substitution-001",
                prompt: """
                    Unavailable exercise: barbell back squat. Limitation: no barbell and avoid heavy spinal loading.
                    Available catalog: goblet squat uses one dumbbell and keeps the load in front; split squat needs
                    balance; leg press requires a machine. Equipment: dumbbells only.
                    """,
                checks: [
                    .contains("goblet squat"),
                    .contains("dumbbell"),
                    .containsAny(["front", "spinal"]),
                    .excludes("leg press"),
                    .maximumWords(45)
                ]
            )
        ]
    )

    public static let appCreatorMetadata = FMFBenchScenario(
        id: "app-creator-metadata",
        title: "Creator clip metadata",
        summary: "Generates constrained creator-facing title and tags from clip notes.",
        category: .creativeWriting,
        inspiredBy: ["Detail", "VLLO", "LumaFusion"],
        instructions: """
            Create concise creator metadata from the clip notes. Return only three lines:
            Title, Caption, Tags. Do not invent location names.
            """,
        outputMode: .text,
        maximumResponseTokens: 120,
        samples: [
            .init(
                id: "app-creator-metadata-001",
                prompt: """
                    Clip notes: handheld cooking reel, rosemary focaccia, afternoon window light,
                    friend laughing off camera, cozy kitchen sound. Need a warm caption under 18 words
                    and exactly four lowercase tags.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .contains("rosemary"),
                    .contains("focaccia"),
                    .containsAny(["window light", "kitchen"]),
                    .excludes("Paris"),
                    .maximumWords(45)
                ]
            )
        ]
    )

    public static let appCitationExtraction = FMFBenchScenario(
        id: "app-citation-extraction",
        title: "Citation extraction from noisy note",
        summary: "Extracts bibliographic fields exactly while ignoring internal markers.",
        category: .citationExtraction,
        inspiredBy: ["Essayist"],
        instructions: "Extract only supplied citation fields. Preserve names, title, year, and venue exactly.",
        outputMode: .guided(.citation),
        maximumResponseTokens: 100,
        samples: [
            .init(
                id: "app-citation-extraction-001",
                prompt: """
                    Bibliography note: Aisha Patel. “Grounded Generation for Notes.” Personal Computing, 2026.
                    Ignore draft marker [internal-review] and do not include the library shelf code PC-77.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Aisha Patel")),
                    .jsonEquals(path: "title", value: .string("Grounded Generation for Notes")),
                    .jsonEquals(path: "year", value: .integer(2026)),
                    .jsonEquals(path: "venue", value: .string("Personal Computing")),
                    .excludes("internal-review"),
                    .excludes("PC-77")
                ]
            )
        ]
    )

    public static let appProjectCapture = FMFBenchScenario(
        id: "app-project-capture",
        title: "Project task capture",
        summary: "Extracts a concrete task from conversational project-planning input.",
        category: .taskParsing,
        inspiredBy: ["Stuff", "OmniFocus"],
        instructions: """
            Extract task information exactly from the request. Never invent missing details.
            Use the supplied reference date and the requested date format.
            """,
        outputMode: .guided(.task),
        maximumResponseTokens: 120,
        samples: [
            .init(
                id: "app-project-capture-001",
                prompt: """
                    Reference date: 2026-06-30. Add “Send beta invite email” to my Launch list
                    for July 3, 2026 at 10:00 AM. Tag it with beta and support. Return dueDate as
                    YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Send beta invite email")),
                    .jsonEquals(path: "list", value: .string("Launch")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-03 10:00")),
                    .jsonContains(path: "tags", values: ["beta", "support"])
                ]
            )
        ]
    )

    public static let appDocumentQuestionAnswering = FMFBenchScenario(
        id: "app-document-qa",
        title: "Document QA with missing information",
        summary: "Answers from supplied documents and refuses to invent absent facts.",
        category: .documentQuestionAnswering,
        inspiredBy: ["Signeasy"],
        instructions: """
            Answer only from the supplied documents. If a requested fact is absent, say it is not
            specified. Cite only document IDs that directly support the answer.
            """,
        outputMode: .guided(.groundedAnswer),
        maximumResponseTokens: 150,
        samples: [
            .init(
                id: "app-document-qa-001",
                prompt: """
                    [sec-1] Subscription starts August 1, 2026 and lasts twelve months.
                    [sec-2] Customer data must be deleted within 30 days after verified written termination request.
                    [sec-3] Late payments accrue interest at 1.5% per month.
                    Question: When must customer data be deleted, what is the late payment interest, and what is the governing law?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["30 days", "1.5%", "not specified"]),
                    .jsonContains(path: "citations", values: ["sec-2", "sec-3"]),
                    .excludes("California"),
                    .excludes("New York")
                ]
            )
        ]
    )

    public static let appLearningExplanation = FMFBenchScenario(
        id: "app-learning-explanation",
        title: "Grounded learning explanation",
        summary: "Explains a concept from a supplied lesson card without extra facts.",
        category: .groundedExplanation,
        inspiredBy: ["CellWalk"],
        instructions: """
            Explain only the supplied lesson facts for a student. Include the source ID and do not
            add facts from outside the lesson card.
            """,
        outputMode: .text,
        maximumResponseTokens: 120,
        samples: [
            .init(
                id: "app-learning-explanation-001",
                prompt: """
                    Lesson card source ID cell-42: Mitochondria release usable energy from food.
                    Cells use that energy for work such as movement, repair, and transport.
                    Explain mitochondria in two short sentences for a middle-school student.
                    """,
                checks: [
                    .contains("mitochondria"),
                    .contains("energy"),
                    .containsAny(["food", "usable"]),
                    .contains("cell-42"),
                    .excludes("DNA"),
                    .maximumWords(55)
                ]
            )
        ]
    )

    public static let appSupportReply = FMFBenchScenario(
        id: "app-support-reply",
        title: "Policy-grounded support reply",
        summary: "Drafts a customer reply that follows support-policy boundaries.",
        category: .summarization,
        inspiredBy: ["App Store commerce workflows"],
        instructions: """
            Draft a concise support reply from the internal facts. Do not promise outcomes outside
            the policy. Include the exact next step and case ID.
            """,
        outputMode: .text,
        maximumResponseTokens: 180,
        samples: [
            .init(
                id: "app-support-reply-001",
                prompt: """
                    Customer: I paid for Pro yesterday but the app still shows Free. I already tried
                    force quitting. This is for my team demo tomorrow.
                    Internal facts: Case ID RQ-8841. Purchase status shows pending Apple receipt
                    validation. Next step: tap Restore Purchases while signed into the same Apple ID.
                    If it still fails after 15 minutes, support can manually refresh entitlement after
                    receiving the App Store receipt screenshot. Refunds are handled by Apple, not us.
                    """,
                checks: [
                    .contains("RQ-8841"),
                    .contains("Restore Purchases"),
                    .contains("same Apple ID"),
                    .contains("15 minutes"),
                    .contains("receipt screenshot"),
                    .excludes("refund has been issued"),
                    .minimumWords(75),
                    .maximumWords(140)
                ]
            )
        ]
    )
}
// swiftlint:enable file_length line_length
