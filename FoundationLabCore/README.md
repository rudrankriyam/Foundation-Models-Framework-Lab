# FoundationLabCore

`FoundationLabCore` is the first shared package for Foundation Lab.

Its job is narrow:

- define task-oriented capability boundaries
- own shared request and result models
- own shared domain models
- own domain-level errors
- define provider protocols and shared capability implementations

Its job is not to own delivery layers or UI concerns.

## Dependency rules

- `FoundationLabCore` must not import `SwiftUI`, `AppIntents`, or `ArgumentParser`.
- `FoundationLabCore` must not own navigation, tabs, routes, or screen-local state.
- App targets and App Intents adapters may depend on `FoundationLabCore`.
- Shared capability implementations may live here as long as they stay UI-free and reusable across adapters.

## Initial conventions

- `Capabilities/` contains task-oriented use case protocols and descriptors.
- `Models/` contains shared domain models used by capabilities.
- `Requests/` contains shared request models for core flows.
- `Results/` contains shared result models and execution metadata.
- `Errors/` contains domain-level errors surfaced by capabilities and providers.
- `Providers/` contains abstraction seams and shared concrete generators that capabilities compose.

This package is intentionally small. It creates the seam for later extraction work without moving major user-facing features yet.

See `ROADMAP.md` for the current shared-capability stack and next capability extractions.
