# Golf Swing Analysis — iOS (v1 scaffold)

Post-hoc swing analysis app: record a golf swing, extract body pose
on-device, detect swing phases, calculate biomechanics metrics, and
(later) get plain-language coaching. See the original project brief for
full v1 scope; this pass builds the pipeline described below and stops
before the review-screen overlay UI and the coaching API integration, per
the brief's own ordering ("get raw pose data flowing and metrics
calculating correctly ... before building the visual layer on top").

## What's built in this pass

1. **GolfSwingCore** (Swift package, no MediaPipe/AVFoundation/UIKit
   dependency) — the portable logic, since this is meant to survive an
   eventual Android port:
   - Pose data models (`PoseLandmarkType`, `PoseFrame`), swing phase/timing
     types, `SwingMetrics`, `MetricEvaluation`.
   - `SwingPhaseDetector` — **heuristic, velocity-threshold-based** phase
     detection (address / top of backswing / impact / finish). This is the
     explicit v1 fallback called out in the brief, not a learned model.
     See "Known v1 simplifications" below.
   - `SwingMetricsCalculator` / `AngleMath` — tempo ratio, X-factor,
     shoulder/hip rotation at top, spine angle at address vs. impact.
   - `ReferenceRangeProvider` — loads `reference_ranges.json` (config, not
     hardcoded in Swift) and evaluates computed metrics against it, with
     height-band scaling for spine angle at address.
   - `CoachingPayloadBuilder` — builds the small metrics-only JSON shape
     the (not-yet-built) coaching request will send. No networking here.
   - Unit tests for all of the above using synthetic pose data.
2. **GolfSwingAnalysis** (SwiftUI app target):
   - Setup flow (club category fixed to "Full Swing", camera angle
     picker, one-time height entry, stored locally via `UserDefaults`).
   - Camera recording (`CameraCaptureService` + `RecordingView`), preferring
     the highest frame rate the device's format supports (targeting 120fps+).
   - `VideoFrameSampler` — decodes the recorded `.mov` into per-frame
     `CVPixelBuffer`s via `AVAssetReader`.
   - `MediaPipePoseExtractor` — wraps MediaPipe's `PoseLandmarker` task and
     maps its output into `GolfSwingCore.PoseFrame` values.
   - `SwingProcessingPipeline` — wires sampler → extractor → phase
     detector → metrics calculator → reference evaluation.
   - `SwingSessionStore` — local JSON-file persistence of past analyses
     (no cloud sync/account, per v1 scope).
   - A deliberately minimal results screen (metric values + in/out-of-range
     flags) so the pipeline's output can be inspected. The slow-motion
     scrubber, skeleton overlay, synthetic reference skeleton, and
     coaching button are **not** built yet.

## Not built yet (next passes)

- Review screen: variable-speed scrubber, user skeleton overlay, synthetic
  "corrected" reference skeleton, angle-arc/spine-line annotations.
- Coaching API integration (the payload shape exists in `GolfSwingCore`;
  the network call and response caching do not).
- Everything explicitly out-of-scope for v1 per the brief (wedges/short
  game, dual-camera sync, real-time coaching, Android, cloud sync/accounts,
  pro-footage overlays, club/ball tracking).

## Project layout

```
GolfSwingCore/            Swift package — portable pose/metrics/reference logic
  Sources/GolfSwingCore/
    Models/                PoseFrame, SwingPhase, SwingMetrics, MetricEvaluation, ...
    PhaseDetection/         SwingPhaseDetector (heuristic)
    Metrics/                AngleMath, SwingMetricsCalculator
    ReferenceData/          HeightBand, ReferenceRangeProvider, reference_ranges.json
    Coaching/               CoachingPayloadBuilder (payload shape only)
  Tests/GolfSwingCoreTests/

GolfSwingAnalysis/        SwiftUI app target
  Setup/                   Club category + camera angle + height entry
  Recording/               AVFoundation capture
  PoseExtraction/          MediaPipe wrapper + AVAssetReader frame sampler
  Analysis/                Pipeline orchestration + minimal results view
  Persistence/             Local UserDefaults/JSON storage

project.yml                XcodeGen spec (generates the .xcodeproj)
Podfile                     CocoaPods spec (MediaPipeTasksVision)
```

## Setup (on a Mac, in Xcode)

This session ran in a Linux sandbox with no Xcode/Swift toolchain
available, so **none of this has been compiled or run** — see "Verification
status" below before relying on it.

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and
   [CocoaPods](https://cocoapods.org) if you don't have them:
   ```
   brew install xcodegen cocoapods
   ```
2. Generate the Xcode project from `project.yml`:
   ```
   xcodegen generate
   ```
3. Install MediaPipe via CocoaPods (wraps the generated project into a
   `.xcworkspace`):
   ```
   pod install
   ```
4. Download a MediaPipe **Pose Landmarker** `.task` model (e.g.
   `pose_landmarker_full.task`) from Google's MediaPipe model zoo and add
   it to the `GolfSwingAnalysis` target as a bundled resource. The binary
   isn't checked into this repo (`.gitignore` excludes `*.task`).
5. Open `GolfSwingAnalysis.xcworkspace` (not the `.xcodeproj` — CocoaPods
   requires the workspace), set your team/signing, and build on a physical
   device (the camera and, for best slow-motion, 120fps capture need real
   hardware — the simulator won't exercise the recording path).
6. Run the `GolfSwingCore` package's own tests independently of the app:
   ```
   cd GolfSwingCore && swift test
   ```

### Verification status

I don't have a macOS/Xcode/Swift toolchain in this sandbox, so **nothing
in this scaffold has been compiled or executed** — including the
`GolfSwingCore` unit tests, which are written to be correct but unverified.
Treat this as a from-scratch scaffold to open and build in Xcode, not
already-working code. The most likely rough edges:
- `MediaPipePoseExtractor.swift` is written against my best knowledge of
  the `MediaPipeTasksVision` Swift API surface (`PoseLandmarker`,
  `PoseLandmarkerOptions`, `NormalizedLandmark`); property names/types
  (especially `NormalizedLandmark.visibility`) should be checked against
  whatever pod version `pod install` resolves.
  - `project.yml`/`Podfile` wiring (XcodeGen + CocoaPods combo) hasn't been
  run through `xcodegen generate` + `pod install` for real.

## Architecture decisions and assumptions made without a live answer

The brief asked to raise ambiguous requirements before making
architectural assumptions. This ran as a non-interactive session, so
rather than blocking, here's what was assumed — flag any of these back if
you'd want it done differently:

- **XcodeGen instead of a hand-written `.pbxproj`.** A hand-authored Xcode
  project file is easy to corrupt and impossible for me to validate without
  Xcode. `project.yml` + `xcodegen generate` is a deterministic, common
  pattern for scaffolding iOS projects outside Xcode itself.
- **Rotation angles (X-factor, shoulder/hip rotation) computed from
  MediaPipe's estimated `z` depth**, not a true 3D capture. A single 2D
  camera can't directly observe transverse-plane rotation; using the
  shoulder/hip line's angle in the `(x, z)` plane as a proxy is a
  reasonable stand-in but hasn't been validated against real recordings —
  worth checking against a labeled clip once you have one.
- **Which wrist drives phase detection**: the detector averages both
  wrists' visible height rather than picking a "lead" wrist, since
  handedness isn't collected as a profile field in the brief. If you want
  left/right-handed setups to use the trail-arm wrist specifically, that's
  a small addition (a handedness field + wrist selection).
- **Reference ranges are placeholder values** assembled from
  golf-instruction/biomechanics literature I could find (TPI's tour-average
  X-factor and shoulder/hip turn norms, Jim McLean's long-vs-short-hitter
  X-factor figures, John Novosel's Tour Tempo 3:1 research, commonly cited
  35–45° address spine-angle guidance) — see `reference_ranges.json`'s
  `sourceNotes` field. These are a reasonable v1 starting point, not
  validated against primary research or labeled swing data, and the brief
  already flags this area as needing review.
- **App minimum deployment target: iOS 17**, to use the two-parameter
  `onChange` API. `GolfSwingCore` itself only requires iOS 16.

## Known v1 simplifications (flagged per the brief)

- **Phase detection is heuristic** (wrist-velocity thresholds), not a
  learned model. The brief's GolfDB/SwingNet reference architecture is the
  natural next step if heuristic accuracy proves insufficient — training
  data would come from your own labeled recordings, not GolfDB's clips
  (which aren't licensed for shipping in the app).
- **Height scaling uses three discrete bands** (short/average/tall) rather
  than a continuous formula. A precise scaling function is called out in
  the brief as a v2 refinement likely needing a biomechanics consultant or
  derived analysis from labeled data.
- **Only spine angle at address is height-scaled** in this pass; the other
  four metrics (tempo ratio, X-factor, shoulder rotation, hip rotation) use
  a single reference band regardless of height, matching how the
  literature these are drawn from reports them.
