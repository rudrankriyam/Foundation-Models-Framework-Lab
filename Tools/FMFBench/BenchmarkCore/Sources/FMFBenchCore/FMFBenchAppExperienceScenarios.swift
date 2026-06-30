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
        appContentClassification
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
            ),
            .init(
                id: "app-workout-adaptation-004",
                prompt: """
                    Create a 12-minute desk break workout for a small office. Use exactly four exercises:
                    sit-to-stand, wall push-up, standing calf raise, and doorway pec stretch. The user's
                    wrist is tender, so keep the focus gentle desk mobility and avoid floor planks.
                    Return durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(12)),
                    .jsonContains(path: "focus", values: ["mobility"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["sit-to-stand", "wall push-up", "standing calf raise", "doorway pec stretch"]
                    ),
                    .excludes("plank")
                ]
            ),
            .init(
                id: "app-workout-adaptation-005",
                prompt: """
                    Create a 16-minute no-equipment morning warmup after a long flight. Use exactly four
                    exercises: shoulder circles, hip hinge, standing march, and heel raise. The user wants
                    circulation and stiffness relief, and wants to avoid burpees. Return durationMinutes
                    as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(16)),
                    .jsonContains(path: "focus", values: ["circulation"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["shoulder circles", "hip hinge", "standing march", "heel raise"]
                    ),
                    .excludes("burpee")
                ]
            ),
            .init(
                id: "app-workout-adaptation-006",
                prompt: """
                    Create a 20-minute home workout for someone with a low ceiling. Use exactly four
                    exercises: split-stance row, floor press, glute bridge march, and farmer carry.
                    Equipment: two dumbbells. Keep the focus upper-body and posterior-chain strength,
                    and avoid overhead pressing. Return durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(20)),
                    .jsonContains(path: "focus", values: ["strength"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["split-stance row", "floor press", "glute bridge march", "farmer carry"]
                    ),
                    .excludes("overhead")
                ]
            ),
            .init(
                id: "app-workout-adaptation-007",
                prompt: """
                    Create a 9-minute between-meetings reset. Use exactly four exercises:
                    neck CARs, seated thoracic rotation, standing hip flexor stretch, and calf pump.
                    The user is in work clothes and wants mobility, not sweating. Return durationMinutes
                    as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(9)),
                    .jsonContains(path: "focus", values: ["mobility"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["neck CARs", "seated thoracic rotation", "standing hip flexor stretch", "calf pump"]
                    ),
                    .excludes("burpee")
                ]
            ),
            .init(
                id: "app-workout-adaptation-008",
                prompt: """
                    Create a 24-minute posterior-chain session. Use exactly four exercises:
                    Romanian deadlift, bird dog, band pull-apart, and suitcase carry. The user's knee
                    dislikes deep bending, so avoid lunges and keep the focus hinge and core strength.
                    Return durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(24)),
                    .jsonContains(path: "focus", values: ["hinge", "core"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["Romanian deadlift", "bird dog", "band pull-apart", "suitcase carry"]
                    ),
                    .excludes("lunge")
                ]
            ),
            .init(
                id: "app-workout-adaptation-009",
                prompt: """
                    Create a 15-minute quiet evening workout. Use exactly four exercises:
                    tempo dead bug, wall angel, heel-elevated squat hold, and kneeling hip hinge.
                    The user lives above a nursery, so avoid stomping and jumping. Return
                    durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(15)),
                    .jsonContains(path: "focus", values: ["quiet"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["tempo dead bug", "wall angel", "heel-elevated squat hold", "kneeling hip hinge"]
                    ),
                    .excludes("jump")
                ]
            ),
            .init(
                id: "app-workout-adaptation-010",
                prompt: """
                    Create an 11-minute cooldown after a rowing workout. Use exactly four exercises:
                    child's pose reach, forearm lat stretch, hamstring floss, and nasal breathing walk.
                    Keep the focus cooldown and back relief, and do not add more intervals. Return
                    durationMinutes as an integer.
                    """,
                checks: [
                    .jsonEquals(path: "durationMinutes", value: .integer(11)),
                    .jsonContains(path: "focus", values: ["cooldown"]),
                    .jsonContains(
                        path: "exercises",
                        values: ["child's pose reach", "forearm lat stretch", "hamstring floss", "nasal breathing walk"]
                    ),
                    .excludes("interval")
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
            ),
            .init(
                id: "app-journal-reflection-004",
                prompt: """
                    Journal entry: I woke up annoyed about the noisy construction, but coffee with Sam
                    helped me reset. I paid the overdue electric bill before lunch. Tomorrow I want to
                    lay out my clothes before bed so the morning feels less rushed.
                    """,
                checks: [
                    .containsAny(["coffee with Sam", "Sam", "coffee"]),
                    .containsAny(["lay out my clothes", "clothes", "morning"]),
                    .excludes("diagnos"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-005",
                prompt: """
                    Journal entry: The product demo froze twice, but Arjun handled the Q&A calmly and
                    made me laugh afterward. I uploaded the revised slides tonight. Tomorrow I want to
                    rehearse with a timer instead of changing the deck again.
                    """,
                checks: [
                    .containsAny(["Arjun", "Q&A", "laugh"]),
                    .containsAny(["rehearse", "timer"]),
                    .excludes("diagnos"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-006",
                prompt: """
                    Journal entry: I forgot my lunch and snapped at Dev, but the quick apology afterward
                    helped us reset. The budget spreadsheet is still unfinished. Tomorrow I want to
                    send Dev a calmer follow-up before opening the spreadsheet again.
                    """,
                checks: [
                    .containsAny(["apology", "Dev", "reset"]),
                    .containsAny(["follow-up", "calmer", "spreadsheet"]),
                    .excludes("diagnos"),
                    .excludes("anger issue"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-007",
                prompt: """
                    Journal entry: I did not finish the proposal, but the library hour was focused and
                    I found the missing pricing note. Tomorrow I want to draft only the risks section
                    before checking mail.
                    """,
                checks: [
                    .containsAny(["library", "focused", "pricing note"]),
                    .containsAny(["risks section", "checking mail", "mail"]),
                    .excludes("finished the proposal"),
                    .excludes("diagnos"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-008",
                prompt: """
                    Journal entry: My presentation was postponed again, which annoyed me, but I used
                    the extra time to practice the opening with Isha. Tomorrow I want to stop editing
                    slides at 8 PM and sleep earlier.
                    """,
                checks: [
                    .containsAny(["Isha", "practice", "opening"]),
                    .containsAny(["8 PM", "sleep", "stop editing"]),
                    .excludes("diagnos"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-009",
                prompt: """
                    Journal entry: The clinic queue took two hours, but Mum and I laughed over the
                    terrible vending-machine coffee. I still need to upload the insurance form.
                    Tomorrow I want to scan the form before breakfast.
                    """,
                checks: [
                    .containsAny(["Mum", "laughed", "coffee"]),
                    .containsAny(["scan the form", "insurance form", "breakfast"]),
                    .excludes("diagnos"),
                    .maximumWords(60)
                ]
            ),
            .init(
                id: "app-journal-reflection-010",
                prompt: """
                    Journal entry: I skipped the team dinner because I was tired, but the quiet train
                    ride home helped me decompress. I packed tomorrow's charger and notebook. Tomorrow
                    I want to ask Leah for the decision summary instead of guessing.
                    """,
                checks: [
                    .containsAny(["train", "decompress", "quiet"]),
                    .containsAny(["Leah", "decision summary", "guessing"]),
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
            ),
            .init(
                id: "app-sports-feedback-004",
                prompt: """
                    Golf range notes: Seven of 10 drives found the fairway target. Tempo stayed smooth
                    after the pause drill. Short putts kept finishing left. Give one next drill and do
                    not invent launch-monitor numbers.
                    """,
                checks: [
                    .containsAny(["7", "seven"]),
                    .contains("10"),
                    .contains("fairway"),
                    .containsAny(["putt", "left"]),
                    .contains("drill"),
                    .excludes("spin rate"),
                    .maximumWords(85)
                ]
            ),
            .init(
                id: "app-sports-feedback-005",
                prompt: """
                    Running workout notes: The first two 400-meter repeats were 1:48, then the last
                    two slipped to 1:55. Cadence stayed relaxed, but shoulders tightened late. Give
                    one next drill and no invented GPS or heart-rate data.
                    """,
                checks: [
                    .contains("1:48"),
                    .contains("1:55"),
                    .containsAny(["cadence", "relaxed"]),
                    .contains("shoulders"),
                    .contains("drill"),
                    .excludes("heart-rate"),
                    .maximumWords(85)
                ]
            ),
            .init(
                id: "app-sports-feedback-006",
                prompt: """
                    Pickleball notes: Third-shot drops landed in 9 of 14 attempts. Backhand dink
                    placement improved cross-court. Serve returns floated high under pressure.
                    Give one next drill and do not invent paddle-speed data.
                    """,
                checks: [
                    .contains("9"),
                    .contains("14"),
                    .containsAny(["backhand dink", "cross-court"]),
                    .containsAny(["serve return", "returns", "floated high"]),
                    .contains("drill"),
                    .excludes("paddle-speed"),
                    .maximumWords(85)
                ]
            ),
            .init(
                id: "app-sports-feedback-007",
                prompt: """
                    Soccer practice notes: First touch stayed clean on 16 of 20 wall passes. Right-foot
                    crosses sailed long. Defensive scanning improved before receiving. Give one next
                    drill and no invented speed or distance metrics.
                    """,
                checks: [
                    .contains("16"),
                    .contains("20"),
                    .containsAny(["first touch", "wall passes"]),
                    .containsAny(["right-foot", "crosses"]),
                    .contains("drill"),
                    .excludes("speed"),
                    .maximumWords(85)
                ]
            ),
            .init(
                id: "app-sports-feedback-008",
                prompt: """
                    Climbing session notes: The climber completed 3 of 5 overhang attempts. Foot swaps
                    were quieter on slab routes. Grip failed late when locking off. Give one next drill
                    and do not invent grip-strength numbers.
                    """,
                checks: [
                    .contains("3"),
                    .contains("5"),
                    .containsAny(["foot swaps", "slab"]),
                    .containsAny(["grip", "locking off"]),
                    .contains("drill"),
                    .excludes("grip-strength"),
                    .maximumWords(85)
                ]
            ),
            .init(
                id: "app-sports-feedback-009",
                prompt: """
                    Baseball bullpen notes: Changeups hit the lower target 11 of 18 times. Fastball
                    release stayed consistent. Curveball bounced early when the elbow dropped. Give
                    one next drill and no invented velocity.
                    """,
                checks: [
                    .contains("11"),
                    .contains("18"),
                    .contains("changeup"),
                    .containsAny(["curveball", "elbow"]),
                    .contains("drill"),
                    .excludes("velocity"),
                    .maximumWords(85)
                ]
            ),
            .init(
                id: "app-sports-feedback-010",
                prompt: """
                    Volleyball notes: Serve receive was clean on 13 of 17 reps. Approach timing improved
                    on outside hits. Blocks drifted inside against line shots. Give one next drill and
                    do not invent jump-height data.
                    """,
                checks: [
                    .contains("13"),
                    .contains("17"),
                    .containsAny(["serve receive", "clean"]),
                    .containsAny(["blocks", "line shots"]),
                    .contains("drill"),
                    .excludes("jump-height"),
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
            ),
            .init(
                id: "app-exercise-substitution-004",
                prompt: """
                    Unavailable exercise: push-up. Limitation: wrist extension is uncomfortable.
                    Available catalog: dumbbell floor press keeps wrists neutral and trains pressing;
                    handstand push-up loads the wrists; cable fly needs a machine. Equipment: dumbbells only.
                    """,
                checks: [
                    .contains("dumbbell floor press"),
                    .containsAny(["neutral", "wrists"]),
                    .contains("pressing"),
                    .excludes("handstand push-up"),
                    .excludes("cable fly"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-exercise-substitution-005",
                prompt: """
                    Unavailable exercise: treadmill run. Limitation: hotel gym is closed and the user
                    wants low noise. Available catalog: step-up uses a sturdy bench; jumping jack is
                    noisy; rowing machine requires gym access. Equipment: bench only.
                    """,
                checks: [
                    .contains("step-up"),
                    .containsAny(["bench", "low noise"]),
                    .containsAny(["hotel gym", "gym is closed", "gym"]),
                    .excludes("jumping jack"),
                    .excludes("rowing machine"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-exercise-substitution-006",
                prompt: """
                    Unavailable exercise: kneeling cable crunch. Limitation: knees cannot tolerate
                    kneeling. Available catalog: standing band crunch trains trunk flexion without
                    kneeling; ab wheel starts from the knees; cable crunch needs a machine. Equipment:
                    resistance band only.
                    """,
                checks: [
                    .contains("standing band crunch"),
                    .containsAny(["without kneeling", "no kneeling", "knees"]),
                    .containsAny(["trunk", "core"]),
                    .excludes("ab wheel"),
                    .excludes("cable crunch"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-exercise-substitution-007",
                prompt: """
                    Unavailable exercise: barbell hip thrust. Limitation: no bench and no barbell.
                    Available catalog: floor glute bridge needs no equipment and trains hip extension;
                    kettlebell swing needs a kettlebell; leg curl needs a machine. Equipment: none.
                    """,
                checks: [
                    .contains("floor glute bridge"),
                    .containsAny(["no equipment", "none"]),
                    .containsAny(["hip extension", "glute"]),
                    .excludes("kettlebell swing"),
                    .excludes("leg curl"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-exercise-substitution-008",
                prompt: """
                    Unavailable exercise: mountain climber. Limitation: wrist pressure is painful and
                    the user wants low impact. Available catalog: standing knee drive trains the same
                    pattern without floor loading; plank jack loads wrists; sprint start is high impact.
                    Equipment: none.
                    """,
                checks: [
                    .contains("standing knee drive"),
                    .containsAny(["wrist", "floor loading"]),
                    .containsAny(["low impact", "pattern"]),
                    .excludes("plank jack"),
                    .excludes("sprint start"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-exercise-substitution-009",
                prompt: """
                    Unavailable exercise: dumbbell curl. Limitation: gripping dumbbells irritates the
                    elbow. Available catalog: band curl uses a light band and can reduce grip demand;
                    chin-up is heavy pulling; preacher curl needs a bench. Equipment: resistance band only.
                    """,
                checks: [
                    .contains("band curl"),
                    .contains("resistance band"),
                    .containsAny(["grip", "elbow"]),
                    .excludes("chin-up"),
                    .excludes("preacher curl"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-exercise-substitution-010",
                prompt: """
                    Unavailable exercise: calf raise on step. Limitation: plantar fascia is irritated,
                    so avoid loaded calf work today. Available catalog: ankle alphabet keeps motion gentle;
                    pogo hop is high impact; seated calf raise is loaded. Equipment: none.
                    """,
                checks: [
                    .contains("ankle alphabet"),
                    .containsAny(["gentle", "plantar fascia"]),
                    .containsAny(["avoid loaded", "loaded calf"]),
                    .excludes("pogo hop"),
                    .excludes("seated calf raise"),
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
            ),
            .init(
                id: "app-creator-metadata-004",
                prompt: """
                    Clip notes: pottery studio timelapse, clay mug trimming, wheel hum, dusty apron,
                    shelf of finished cups. Need a calm caption under 15 words and exactly four
                    lowercase tags. Do not name a city.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["pottery", "clay", "mug"]),
                    .containsAny(["studio", "wheel", "apron"]),
                    .excludes("Tokyo"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-005",
                prompt: """
                    Clip notes: rainy bookstore mini vlog, stacked paperbacks, receipt used as bookmark,
                    quiet aisle pan, tea cup at the end. Need a cozy caption under 16 words and exactly
                    four lowercase tags. No store name was provided.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["bookstore", "paperbacks", "bookmark"]),
                    .containsAny(["rainy", "tea", "aisle"]),
                    .excludes("Barnes"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-006",
                prompt: """
                    Clip notes: desk setup before-and-after, cable tray, warm monitor light, no product
                    sponsor, quick dust wipe. Need a practical caption under 15 words and exactly four
                    lowercase tags. Do not invent a brand.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["desk", "cable", "setup"]),
                    .containsAny(["before-and-after", "monitor", "dust"]),
                    .excludes("sponsored"),
                    .excludes("Apple"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-007",
                prompt: """
                    Clip notes: rooftop herb garden update, basil seedlings, cracked terracotta pot,
                    wind noise, sunset watering can. Need a calm caption under 14 words and exactly
                    four lowercase tags. No city was provided.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["herb", "basil", "garden"]),
                    .containsAny(["terracotta", "watering", "sunset"]),
                    .excludes("Brooklyn"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-008",
                prompt: """
                    Clip notes: dance practice blooper reel, missed count, laughing reset, mirrored
                    studio wall, final clean eight-count. Need an upbeat caption under 13 words and
                    exactly four lowercase tags.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["dance", "eight-count", "practice"]),
                    .containsAny(["blooper", "laughing", "studio"]),
                    .excludes("competition"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-009",
                prompt: """
                    Clip notes: tiny apartment cleaning reset, laundry basket, windowsill plants,
                    timer beeps at the end, no voiceover. Need a crisp caption under 12 words and
                    exactly four lowercase tags.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["cleaning", "reset", "laundry"]),
                    .containsAny(["plants", "timer", "apartment"]),
                    .excludes("voiceover"),
                    .maximumWords(45)
                ]
            ),
            .init(
                id: "app-creator-metadata-010",
                prompt: """
                    Clip notes: night market sketchbook flip-through, ink thumbnails, neon reflections,
                    vendor hands only, no location named. Need a moody caption under 15 words and
                    exactly four lowercase tags.
                    """,
                checks: [
                    .contains("Title:"),
                    .contains("Caption:"),
                    .contains("Tags:"),
                    .containsAny(["sketchbook", "ink", "thumbnails"]),
                    .containsAny(["neon", "market", "vendor"]),
                    .excludes("Taipei"),
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
            ),
            .init(
                id: "app-citation-extraction-004",
                prompt: """
                    Bibliography note: Leila Okafor. “Assistive Summaries for Field Notes.” Ubiquitous Learning, 2023.
                    Ignore import batch B-19 and comment needs-abstract.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Leila Okafor")),
                    .jsonEquals(path: "title", value: .string("Assistive Summaries for Field Notes")),
                    .jsonEquals(path: "year", value: .integer(2023)),
                    .jsonEquals(path: "venue", value: .string("Ubiquitous Learning")),
                    .excludes("B-19"),
                    .excludes("needs-abstract")
                ]
            ),
            .init(
                id: "app-citation-extraction-005",
                prompt: """
                    Bibliography note: Evan Rossi. “Small Language Models in Studio Tools.” Creative Systems, 2026.
                    Ignore shelf location CRAFT-4 and uploader handle @milo.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Evan Rossi")),
                    .jsonEquals(path: "title", value: .string("Small Language Models in Studio Tools")),
                    .jsonEquals(path: "year", value: .integer(2026)),
                    .jsonEquals(path: "venue", value: .string("Creative Systems")),
                    .excludes("CRAFT-4"),
                    .excludes("@milo")
                ]
            ),
            .init(
                id: "app-citation-extraction-006",
                prompt: """
                    OCR text: Priya Nair — “Offline Tutors for Language Practice” — Learning Interfaces — 2026.
                    Ignore scan confidence 0.74 and sticky note ask Sam.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Priya Nair")),
                    .jsonEquals(path: "title", value: .string("Offline Tutors for Language Practice")),
                    .jsonEquals(path: "year", value: .integer(2026)),
                    .jsonEquals(path: "venue", value: .string("Learning Interfaces")),
                    .excludes("0.74"),
                    .excludes("ask Sam")
                ]
            ),
            .init(
                id: "app-citation-extraction-007",
                prompt: """
                    Imported reference: “Workout Planning with Structured Generation” by Tomas Iversen.
                    Venue: Mobile Health Review. Year: 2025. Ignore duplicate candidate Thomas Iverson.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Tomas Iversen")),
                    .jsonEquals(path: "title", value: .string("Workout Planning with Structured Generation")),
                    .jsonEquals(path: "year", value: .integer(2025)),
                    .jsonEquals(path: "venue", value: .string("Mobile Health Review")),
                    .excludes("Thomas Iverson")
                ]
            ),
            .init(
                id: "app-citation-extraction-008",
                prompt: """
                    PDF header says: Hana Suzuki. “Personal Knowledge Bases on Device.” Notes and Systems, 2024.
                    Footer says downloaded by lab-intern; ignore footer and page count 12.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Hana Suzuki")),
                    .jsonEquals(path: "title", value: .string("Personal Knowledge Bases on Device")),
                    .jsonEquals(path: "year", value: .integer(2024)),
                    .jsonEquals(path: "venue", value: .string("Notes and Systems")),
                    .excludes("lab-intern"),
                    .excludes("12")
                ]
            ),
            .init(
                id: "app-citation-extraction-009",
                prompt: """
                    Reference card: Author = Omar Haddad; Title = “Guided Generation in Small Apps”;
                    Venue = Developer Tools Quarterly; Year = 2023. Ignore local ID DTQ-temp-9.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Omar Haddad")),
                    .jsonEquals(path: "title", value: .string("Guided Generation in Small Apps")),
                    .jsonEquals(path: "year", value: .integer(2023)),
                    .jsonEquals(path: "venue", value: .string("Developer Tools Quarterly")),
                    .excludes("DTQ-temp-9")
                ]
            ),
            .init(
                id: "app-citation-extraction-010",
                prompt: """
                    Messy note: cite Mei Alvarez, “Private Summaries for Shared Tablets,” Family Computing, 2026.
                    Not the related draft “Shared Tablets in Schools”; ignore reviewer tag family-ai.
                    """,
                checks: [
                    .jsonEquals(path: "author", value: .string("Mei Alvarez")),
                    .jsonEquals(path: "title", value: .string("Private Summaries for Shared Tablets")),
                    .jsonEquals(path: "year", value: .integer(2026)),
                    .jsonEquals(path: "venue", value: .string("Family Computing")),
                    .excludes("Shared Tablets in Schools"),
                    .excludes("family-ai")
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
            ),
            .init(
                id: "app-project-capture-004",
                prompt: """
                    Reference date: 2026-06-30. Add “Renew staging certificate” to Infrastructure
                    for July 6, 2026 at 4:30 PM. Tags are signing and blocker. Return dueDate as
                    YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Renew staging certificate")),
                    .jsonEquals(path: "list", value: .string("Infrastructure")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-06 16:30")),
                    .jsonContains(path: "tags", values: ["signing", "blocker"])
                ]
            ),
            .init(
                id: "app-project-capture-005",
                prompt: """
                    Reference date: 2026-06-30. Put “Send vendor accessibility notes” in Legal
                    for July 10, 2026 at 11:20 AM. Tag it with accessibility and vendor. Return dueDate
                    as YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Send vendor accessibility notes")),
                    .jsonEquals(path: "list", value: .string("Legal")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-10 11:20")),
                    .jsonContains(path: "tags", values: ["accessibility", "vendor"])
                ]
            ),
            .init(
                id: "app-project-capture-006",
                prompt: """
                    Reference date: 2026-06-30. Add “Pack demo iPad chargers” to Travel next Tuesday
                    at 7:05 AM. Tags are demo and hardware. Return dueDate as YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Pack demo iPad chargers")),
                    .jsonEquals(path: "list", value: .string("Travel")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-07 07:05")),
                    .jsonContains(path: "tags", values: ["demo", "hardware"])
                ]
            ),
            .init(
                id: "app-project-capture-007",
                prompt: """
                    Reference date: 2026-06-30. Remind me tomorrow at 6:40 PM to “Upload signed
                    consent PDF” in Research. Tag it with consent and upload. Return dueDate as
                    YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Upload signed consent PDF")),
                    .jsonEquals(path: "list", value: .string("Research")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-01 18:40")),
                    .jsonContains(path: "tags", values: ["consent", "upload"])
                ]
            ),
            .init(
                id: "app-project-capture-008",
                prompt: """
                    Reference date: 2026-06-30. Capture “Confirm speaker invoice total” under Finance
                    for July 15, 2026 at 12:00 PM. Tags: invoice and speaker. Return dueDate as
                    YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Confirm speaker invoice total")),
                    .jsonEquals(path: "list", value: .string("Finance")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-15 12:00")),
                    .jsonContains(path: "tags", values: ["invoice", "speaker"])
                ]
            ),
            .init(
                id: "app-project-capture-009",
                prompt: """
                    Reference date: 2026-06-30. Add “Draft airport pickup plan” to Ops for two Fridays
                    from now at 8:10 AM. Tags are travel and logistics. Return dueDate as YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Draft airport pickup plan")),
                    .jsonEquals(path: "list", value: .string("Ops")),
                    .jsonEquals(path: "dueDate", value: .string("2026-07-10 08:10")),
                    .jsonContains(path: "tags", values: ["travel", "logistics"])
                ]
            ),
            .init(
                id: "app-project-capture-010",
                prompt: """
                    Reference date: 2026-06-30. Schedule “Email beta crash summary” in QA for tonight
                    at 9:30 PM. Tag it with beta and crash. Return dueDate as YYYY-MM-DD HH:mm.
                    """,
                checks: [
                    .jsonEquals(path: "title", value: .string("Email beta crash summary")),
                    .jsonEquals(path: "list", value: .string("QA")),
                    .jsonEquals(path: "dueDate", value: .string("2026-06-30 21:30")),
                    .jsonContains(path: "tags", values: ["beta", "crash"])
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
            ),
            .init(
                id: "app-document-qa-004",
                prompt: """
                    [r-1] The renter may cancel the booking until 6 PM local time on the pickup date.
                    [r-2] Mileage is limited to 200 miles per day.
                    [r-3] Cleaning fees apply only when pet hair is found after return.
                    Question: What is the cancellation deadline, what is the daily mileage limit, and what is the fuel policy?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["6 PM", "200 miles", "not specified"]),
                    .jsonContains(path: "citations", values: ["r-1", "r-2"]),
                    .excludes("full tank"),
                    .excludes("prepaid fuel")
                ]
            ),
            .init(
                id: "app-document-qa-005",
                prompt: """
                    [p-1] The creator must deliver final artwork as PNG and SVG files.
                    [p-2] The client review window is five business days after delivery.
                    [p-3] The deposit is non-refundable after work begins.
                    Question: Which file formats are required, how long is the review window, and who owns unused sketches?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["PNG", "SVG", "five business days", "not specified"]),
                    .jsonContains(path: "citations", values: ["p-1", "p-2"]),
                    .excludes("client owns"),
                    .excludes("creator owns")
                ]
            ),
            .init(
                id: "app-document-qa-006",
                prompt: """
                    [v-1] Venue access begins at 8 AM on setup day.
                    [v-2] Outside catering requires written approval seven days before the event.
                    [v-3] The projector rental includes one HDMI cable.
                    Question: When does venue access begin, when is catering approval due, and who provides security staff?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["8 AM", "seven days", "not specified"]),
                    .jsonContains(path: "citations", values: ["v-1", "v-2"]),
                    .excludes("venue provides"),
                    .excludes("client provides")
                ]
            ),
            .init(
                id: "app-document-qa-007",
                prompt: """
                    [h-1] The host must send allergy information 48 hours before check-in.
                    [h-2] Quiet hours are from 10 PM to 7 AM.
                    [h-3] The cleaning checklist must be completed before checkout.
                    Question: When is allergy information due, what are quiet hours, and is parking included?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["48 hours", "10 PM", "7 AM", "not specified"]),
                    .jsonContains(path: "citations", values: ["h-1", "h-2"]),
                    .excludes("parking included"),
                    .excludes("free parking")
                ]
            ),
            .init(
                id: "app-document-qa-008",
                prompt: """
                    [n-1] The newsletter sponsor receives two approval rounds.
                    [n-2] Final copy is due by 5 PM Pacific on the 12th.
                    [n-3] The sponsor logo must be supplied as SVG.
                    Question: How many approval rounds are included, when is final copy due, and what is the click-through guarantee?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["two", "5 PM Pacific", "not specified"]),
                    .jsonContains(path: "citations", values: ["n-1", "n-2"]),
                    .excludes("click-through"),
                    .excludes("CTR")
                ]
            ),
            .init(
                id: "app-document-qa-009",
                prompt: """
                    [b-1] The beta tester may share screenshots only with the product team.
                    [b-2] Crash reports should be submitted within 24 hours of discovery.
                    [b-3] TestFlight invitations expire after 90 days.
                    Question: Who may receive screenshots, when are crash reports due, and what is the tester compensation?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["product team", "24 hours", "not specified"]),
                    .jsonContains(path: "citations", values: ["b-1", "b-2"]),
                    .excludes("paid"),
                    .excludes("$")
                ]
            ),
            .init(
                id: "app-document-qa-010",
                prompt: """
                    [l-1] The workshop recording will be available for 30 days.
                    [l-2] Participants may submit questions until noon UTC on Friday.
                    [l-3] Slides are distributed as PDF only.
                    Question: How long is the recording available, when do questions close, and are captions provided?
                    """,
                checks: [
                    .jsonContains(path: "answer", values: ["30 days", "noon UTC", "not specified"]),
                    .jsonContains(path: "citations", values: ["l-1", "l-2"]),
                    .excludes("captions are provided"),
                    .excludes("closed captions")
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
            ),
            .init(
                id: "app-learning-explanation-004",
                prompt: """
                    Lesson card source ID geo-11: Erosion moves bits of rock and soil from one place
                    to another. Water, wind, and ice can all cause erosion.
                    Explain erosion in two short sentences for a middle-school student.
                    """,
                checks: [
                    .contains("erosion"),
                    .containsAny(["rock", "soil"]),
                    .containsAny(["water", "wind", "ice"]),
                    .contains("geo-11"),
                    .excludes("earthquake"),
                    .maximumWords(55)
                ]
            ),
            .init(
                id: "app-learning-explanation-005",
                prompt: """
                    Lesson card source ID music-03: Rhythm is the pattern of sounds and silences in
                    music. A steady beat helps listeners feel where the rhythm fits.
                    Explain rhythm in two short sentences for a middle-school student.
                    """,
                checks: [
                    .contains("rhythm"),
                    .containsAny(["sounds", "silences"]),
                    .contains("beat"),
                    .contains("music-03"),
                    .excludes("melody"),
                    .maximumWords(55)
                ]
            ),
            .init(
                id: "app-learning-explanation-006",
                prompt: """
                    Lesson card source ID chem-14: A catalyst helps a chemical reaction happen faster
                    without being used up by the reaction. Explain catalysts in two short sentences for
                    a middle-school student.
                    """,
                checks: [
                    .contains("catalyst"),
                    .containsAny(["faster", "speed"]),
                    .containsAny(["not used up", "without being used up"]),
                    .contains("chem-14"),
                    .excludes("enzyme"),
                    .maximumWords(55)
                ]
            ),
            .init(
                id: "app-learning-explanation-007",
                prompt: """
                    Lesson card source ID civics-02: A veto is when an executive rejects a proposed law.
                    A legislature may have a process to try again after a veto.
                    Explain veto in two short sentences for a middle-school student.
                    """,
                checks: [
                    .contains("veto"),
                    .containsAny(["rejects", "proposed law"]),
                    .containsAny(["try again", "legislature"]),
                    .contains("civics-02"),
                    .excludes("Supreme Court"),
                    .maximumWords(55)
                ]
            ),
            .init(
                id: "app-learning-explanation-008",
                prompt: """
                    Lesson card source ID art-19: Contrast is the difference between light and dark,
                    large and small, or other opposite visual qualities. Artists use contrast to make
                    parts of an image stand out. Explain contrast in two short sentences.
                    """,
                checks: [
                    .contains("contrast"),
                    .containsAny(["difference", "opposite"]),
                    .containsAny(["stand out", "image"]),
                    .contains("art-19"),
                    .excludes("color theory"),
                    .maximumWords(55)
                ]
            ),
            .init(
                id: "app-learning-explanation-009",
                prompt: """
                    Lesson card source ID econ-05: Scarcity means people have limited resources but
                    more wants than those resources can satisfy. Choices are needed because of scarcity.
                    Explain scarcity in two short sentences for a middle-school student.
                    """,
                checks: [
                    .contains("scarcity"),
                    .containsAny(["limited resources", "limited"]),
                    .containsAny(["choices", "wants"]),
                    .contains("econ-05"),
                    .excludes("inflation"),
                    .maximumWords(55)
                ]
            ),
            .init(
                id: "app-learning-explanation-010",
                prompt: """
                    Lesson card source ID geo-24: A watershed is an area of land where water drains
                    into the same river, lake, or ocean. Explain watershed in two short sentences for
                    a middle-school student.
                    """,
                checks: [
                    .contains("watershed"),
                    .containsAny(["drains", "water"]),
                    .containsAny(["river", "lake", "ocean"]),
                    .contains("geo-24"),
                    .excludes("weather"),
                    .maximumWords(55)
                ]
            )
        ]
    )

    public static let appContentClassification = FMFBenchScenario(
        id: "app-content-classification",
        title: "Personal content categorization",
        summary: "Classifies short user content into an app-owned theme for review or automation.",
        category: .classification,
        inspiredBy: ["Motivation", "Streaks", "Vocabulary"],
        instructions: """
            Choose the single best category for the user's saved content or task. Use only one of
            the supplied categories and do not invent a new label.
            """,
        outputMode: .guided(.classification),
        maximumResponseTokens: 80,
        samples: [
            .init(
                id: "app-content-classification-001",
                prompt: """
                    Favorite reminder: “A five-minute walk between meetings counts; protect your
                    shoulders and breathe before the next call.” Categories: health, learning,
                    productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("health")),
                    .excludes("fitness"),
                    .excludes("wellness")
                ]
            ),
            .init(
                id: "app-content-classification-002",
                prompt: """
                    Saved words: estuary, isotope, habitat, migration. The user wants the words
                    grouped for review later. Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("learning")),
                    .excludes("science"),
                    .excludes("vocabulary")
                ]
            ),
            .init(
                id: "app-content-classification-003",
                prompt: """
                    To-do capture: Renew passport, book hotel near the venue, and send the itinerary
                    to the travel folder. Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("productivity")),
                    .excludes("travel"),
                    .excludes("planning")
                ]
            ),
            .init(
                id: "app-content-classification-004",
                prompt: """
                    New recurring task: Call Nani every Sunday evening and ask how her garden is doing.
                    Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("relationships")),
                    .excludes("family"),
                    .excludes("social")
                ]
            ),
            .init(
                id: "app-content-classification-005",
                prompt: """
                    Saved phrase: “Practice one guitar scale slowly, then write down what sounded
                    uneven.” Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("learning")),
                    .excludes("music"),
                    .excludes("practice")
                ]
            ),
            .init(
                id: "app-content-classification-006",
                prompt: """
                    Favorite reminder: “Text Mira the photo from today and ask whether Saturday still
                    works.” Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("relationships")),
                    .excludes("social"),
                    .excludes("calendar")
                ]
            ),
            .init(
                id: "app-content-classification-007",
                prompt: """
                    To-do capture: Refill migraine medicine, drink water before the train, and note the
                    dosage time. Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("health")),
                    .excludes("medicine"),
                    .excludes("pharmacy")
                ]
            ),
            .init(
                id: "app-content-classification-008",
                prompt: """
                    Saved words: escrow, lien, amortize, principal. The user is reviewing real-estate
                    finance terms. Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("learning")),
                    .excludes("finance"),
                    .excludes("real estate")
                ]
            ),
            .init(
                id: "app-content-classification-009",
                prompt: """
                    Task: Sort receipts, rename the scanned files, and move them into the tax folder
                    before Friday. Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("productivity")),
                    .excludes("tax"),
                    .excludes("finance")
                ]
            ),
            .init(
                id: "app-content-classification-010",
                prompt: """
                    Favorite quote: “A hard conversation can still be kind if you listen before
                    defending yourself.” Categories: health, learning, productivity, relationships.
                    """,
                checks: [
                    .jsonEquals(path: "category", value: .string("relationships")),
                    .excludes("communication"),
                    .excludes("mindfulness")
                ]
            )
        ]
    )
}
// swiftlint:enable file_length line_length
