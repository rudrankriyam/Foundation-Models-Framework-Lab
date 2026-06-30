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
            ),
            .init(
                id: "app-workout-adaptation-002",
                prompt: """
                    Adapt today's gym plan into a 22-minute apartment workout. Use exactly four exercises:
                    tempo squat to chair, half-kneeling press, band row, and side plank. Equipment: one
                    resistance band and one dumbbell. Constraint: avoid overhead jumping because neighbors
                    complained. Return durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(22)),
                    .jsonContains(path: "focus", values: ["strength"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["tempo squat to chair", "half-kneeling press", "band row", "side plank"]
                    ),
                    .excludes("jump")
                ]
            ),
            .init(
                id: "app-workout-adaptation-003",
                prompt: """
                    Create an 18-minute post-run recovery workout. Use exactly four exercises:
                    calf raise, hamstring walkout, glute bridge, and open book stretch. The runner's
                    right ankle is tender, so keep the focus controlled recovery and avoid sprinting.
                    Return durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(18)),
                    .jsonContains(path: "focus", values: ["recovery"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["calf raise", "hamstring walkout", "glute bridge", "open book stretch"]
                    ),
                    .excludes("sprint")
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
                    .containsAny(["walk", "quiet walk"]),
                    .containsAny(["onboarding draft", "onboarding", "draft"]),
                    .containsAny(["blocking messages", "first hour", "messages"]),
                    .excludes("diagnos"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-002",
                prompt: """
                    Journal entry: I was frustrated that the train delay made me late, but reading two
                    chapters on the platform helped me settle down. I still sent the grant notes before
                    dinner. Tomorrow I want to leave ten minutes earlier and pack my bag tonight.
                    """,
                checks: [
                    .containsAny(["two chapters", "reading"]),
                    .containsAny(["leave ten minutes earlier", "ten minutes earlier", "pack my bag", "pack the bag"]),
                    .excludes("diagnos"),
                    .excludes("therapy"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-003",
                prompt: """
                    Journal entry: The morning review felt tense, but Mina's specific compliment about
                    the prototype made the afternoon easier. I finished the bug triage list. Tomorrow I
                    want to write the release note before opening chat.
                    """,
                checks: [
                    .containsAny(["Mina", "compliment", "prototype"]),
                    .containsAny(["release note", "before opening chat", "bug triage"]),
                    .excludes("diagnos"),
                    .excludes("anxiety disorder"),
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
            ),
            .init(
                id: "app-sports-feedback-002",
                prompt: """
                    Basketball workout notes: Free throws were 18 of 24. Left-hand layups missed short
                    when tired. Defensive slide speed improved during the final five minutes. The player
                    wants one drill for tomorrow.
                    """,
                checks: [
                    .contains("18"),
                    .contains("24"),
                    .containsAny(["defensive slide", "slide speed"]),
                    .containsAny(["left-hand", "layup"]),
                    .contains("drill"),
                    .excludes("heart rate"),
                    .maximumWords(85)
                ]
            ),
            .init(
                id: "app-sports-feedback-003",
                prompt: """
                    Swim session notes: 50-meter pace held at 41 seconds for the first four repeats,
                    then drifted to 45 seconds. Breathing stayed calmer on bilateral sets. The kick
                    faded late. Give one next drill and no invented sensor data.
                    """,
                checks: [
                    .contains("41"),
                    .contains("45"),
                    .containsAny(["bilateral", "breathing"]),
                    .contains("kick"),
                    .contains("drill"),
                    .excludes("heart rate"),
                    .maximumWords(85)
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
            ),
            .init(
                id: "app-exercise-substitution-002",
                prompt: """
                    Unavailable exercise: pull-up. Limitation: cannot hang from a bar after shoulder
                    irritation. Available catalog: band row uses a resistance band and trains pulling;
                    lat pulldown needs a machine; burpee is full-body conditioning. Equipment: resistance band only.
                    """,
                checks: [
                    .contains("band row"),
                    .contains("resistance band"),
                    .containsAny(["pulling", "shoulder"]),
                    .excludes("lat pulldown"),
                    .excludes("burpee"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-exercise-substitution-003",
                prompt: """
                    Unavailable exercise: box jump. Limitation: quiet apartment and avoid high-impact
                    landings. Available catalog: reverse lunge needs no equipment and is quiet;
                    jump squat is high impact; sled push requires gym turf. Equipment: none.
                    """,
                checks: [
                    .contains("reverse lunge"),
                    .containsAny(["quiet", "no equipment"]),
                    .containsAny(["high-impact", "landings"]),
                    .excludes("jump squat"),
                    .excludes("sled push"),
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
                    .containsAny(["window light", "afternoon light", "kitchen"]),
                    .excludes("Paris"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-002",
                prompt: """
                    Clip notes: vertical repair tutorial, loose bicycle chain, rainy garage floor,
                    close-up hands, quick before-and-after spin. Need a practical caption under
                    16 words and exactly four lowercase tags. No city names.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["bicycle", "chain"]),
                    .containsAny(["garage", "repair", "before-and-after"]),
                    .excludes("London"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-003",
                prompt: """
                    Clip notes: makeup transition reel, copper eyeshadow, mirror close-up, soft lamp,
                    no brand sponsorship, final look reveal. Need a playful caption under 14 words
                    and exactly four lowercase tags.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .contains("copper"),
                    .containsAny(["eyeshadow", "mirror", "lamp"]),
                    .excludes("sponsored"),
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
            ),
            .init(
                id: "app-citation-extraction-002",
                prompt: """
                    Bibliography note: Mateo Chen. “Interface Patterns for Local Models.” Mobile Systems, 2025.
                    Ignore note owner @rhea and temporary tag draft-only.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Mateo Chen")),
                    .jsonEquals(path: "title", value: .string("Interface Patterns for Local Models")),
                    .jsonEquals(path: "year", value: .integer(2025)),
                    .jsonEquals(path: "venue", value: .string("Mobile Systems")),
                    .excludes("@rhea"),
                    .excludes("draft-only")
                ]
            ),
            .init(
                id: "app-citation-extraction-003",
                prompt: """
                    Bibliography note: Noor Williams. “Privacy Budgets in Personal Assistants.” Applied HCI, 2024.
                    Ignore folder code /imports/pending and the reviewer initials KW.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Noor Williams")),
                    .jsonEquals(path: "title", value: .string("Privacy Budgets in Personal Assistants")),
                    .jsonEquals(path: "year", value: .integer(2024)),
                    .jsonEquals(path: "venue", value: .string("Applied HCI")),
                    .excludes("/imports/pending"),
                    .excludes("KW")
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
            ),
            .init(
                id: "app-project-capture-002",
                prompt: """
                    Reference date: 2026-06-30. Put “Review crash logs” in my Release list for
                    July 1, 2026 at 2:15 PM. Tags are diagnostics and urgent. Return dueDate as
                    YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Review crash logs")),
                    .jsonEquals(path: "list", value: .string("Release")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-01 14:15")),
                    .jsonContains(path: "tags", values: ["diagnostics", "urgent"])
                ]
            ),
            .init(
                id: "app-project-capture-003",
                prompt: """
                    Reference date: 2026-06-30. Schedule “Record onboarding clip” in Marketing
                    for July 8, 2026 at 9:45 AM. Tag it with video and launch. Return dueDate as
                    YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Record onboarding clip")),
                    .jsonEquals(path: "list", value: .string("Marketing")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-08 09:45")),
                    .jsonContains(path: "tags", values: ["video", "launch"])
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
            ),
            .init(
                id: "app-document-qa-002",
                prompt: """
                    [a-1] The vendor must acknowledge security incidents within 24 hours.
                    [a-2] The service credit is capped at 10% of monthly fees.
                    [a-3] Data export is available for 45 days after termination.
                    Question: What is the incident acknowledgement window, what is the service credit cap, and who owns custom templates?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["24 hours", "10%", "not specified"]),
                    .jsonContains(path: "citations", values: ["a-1", "a-2"]),
                    .excludes("customer owns"),
                    .excludes("vendor owns")
                ]
            ),
            .init(
                id: "app-document-qa-003",
                prompt: """
                    [m-1] The renewal reminder must be sent 14 days before the annual renewal date.
                    [m-2] Support response target is two business days for standard tickets.
                    [m-3] Attachments larger than 25 MB are rejected.
                    Question: When is the renewal reminder sent, what is the support response target, and what is the uptime guarantee?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["14 days", "two business days", "not specified"]),
                    .jsonContains(path: "citations", values: ["m-1", "m-2"]),
                    .excludes("99.9"),
                    .excludes("99.99")
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
            ),
            .init(
                id: "app-learning-explanation-002",
                prompt: """
                    Lesson card source ID eco-18: A food web shows how energy moves among living
                    things. Arrows point from the food source to the organism that eats it.
                    Explain food webs in two short sentences for a middle-school student.
                    """,
                checks: [
                    .contains("food web"),
                    .contains("energy"),
                    .containsAny(["arrows", "eats"]),
                    .contains("eco-18"),
                    .excludes("photosynthesis"),
                    .maximumWords(55)
                ]
            ),
            .init(
                id: "app-learning-explanation-003",
                prompt: """
                    Lesson card source ID math-07: A ratio compares two quantities by division.
                    Equivalent ratios describe the same comparison using different numbers.
                    Explain ratios in two short sentences for a middle-school student.
                    """,
                checks: [
                    .contains("ratio"),
                    .containsAny(["division", "compares"]),
                    .contains("equivalent"),
                    .contains("math-07"),
                    .excludes("probability"),
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
                    .contains("receipt"),
                    .contains("screenshot"),
                    .excludes("refund has been issued"),
                    .minimumWords(75),
                    .maximumWords(140)
                ]
            ),
            .init(
                id: "app-support-reply-002",
                prompt: """
                    Customer: My exported PDF is missing the signature page, and I need to send it in an hour.
                    Internal facts: Case ID SG-2040. Export status shows the signature page is still processing.
                    Next step: reopen the document and tap Export again after the blue processing banner disappears.
                    If the page is still missing after 10 minutes, support can regenerate the export after receiving
                    the document ID. Do not promise legal validity.
                    """,
                checks: [
                    .contains("SG-2040"),
                    .contains("Export"),
                    .containsAny(["blue processing banner", "processing banner"]),
                    .contains("10 minutes"),
                    .contains("document ID"),
                    .excludes("legally valid"),
                    .minimumWords(70),
                    .maximumWords(140)
                ]
            ),
            .init(
                id: "app-support-reply-003",
                prompt: """
                    Customer: The shared family plan says I am not invited, but my partner added me this morning.
                    Internal facts: Case ID FP-7782. Invite status shows pending acceptance. Next step: open the
                    invitation link from the same email address that was invited. If it still fails after 20 minutes,
                    support can resend the invitation after receiving the invited email address. Billing changes are
                    handled by Apple.
                    """,
                checks: [
                    .contains("FP-7782"),
                    .contains("invitation link"),
                    .contains("same email address"),
                    .contains("20 minutes"),
                    .contains("invited email address"),
                    .excludes("billing change completed"),
                    .minimumWords(70),
                    .maximumWords(140)
                ]
            )
        ]
    )
}
// swiftlint:enable file_length line_length
