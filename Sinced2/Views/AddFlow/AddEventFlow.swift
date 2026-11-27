//
//  AddEventFlow.swift
//  Sinced2
//
//  Adding or editing an event as one floating card. It grows out of what was
//  tapped (the + tile, an event's card, or the Edit button), reads as a
//  sentence ("Since … started … goal … on …"), opens each bold word's editor
//  inside the same card, and on save becomes the event's card on the home
//  grid. Closing folds it back into where it came from.
//

import SwiftUI
import Combine

// MARK: - Coordinator

/// Shared between the screen underneath (which knows where the + tile and
/// the event cards are) and the overlay that draws the card. The home screen
/// uses `shared`; the event page keeps its own, since it's a sheet of its own.
final class AddFlow: ObservableObject {
    static let shared = AddFlow()

    enum Request {
        case add
        /// `fromCard`: grows out of the event's card on the home grid, rather
        /// than out of `sourceFrame` (a button)
        case edit(SinceEvent, openGoal: Bool, fromCard: Bool)
    }

    @Published private(set) var isPresented = false
    /// The + tile hides while the card is out, since the card is the tile
    @Published var hidesSource = false
    /// The event card hidden under the floating card: the one being edited,
    /// or the new one waiting for the card to land on it
    @Published var hiddenEventID: UUID?

    private(set) var request: Request = .add
    /// Where the + tile, the empty state's button or the Edit button is, in window coordinates
    var sourceFrame: CGRect = .zero
    /// Where each home card sits, in window coordinates
    var cardFrames: [UUID: CGRect] = [:]
    /// Runs after the card has gone, whether it was saved or closed
    var onFinish: (() -> Void)?

    /// A name the add card starts with, like an idea tapped on the empty home
    var presetName: String?

    func present(name: String? = nil) {
        guard !isPresented else { return }
        presetName = name
        request = .add
        hidesSource = true
        isPresented = true
    }

    /// Edit an event. With no `from`, the card grows out of the event's home card.
    func presentEdit(_ event: SinceEvent, openGoal: Bool = false, from frame: CGRect? = nil) {
        guard !isPresented else { return }
        let fromCard = frame == nil && cardFrames[event.id] != nil
        if let frame { sourceFrame = frame }
        request = .edit(event, openGoal: openGoal, fromCard: fromCard)
        hiddenEventID = fromCard ? event.id : nil
        isPresented = true
    }

    func finish() {
        isPresented = false
        hiddenEventID = nil
        onFinish?()
    }

    /// For a notification or widget tap that needs the screen straight away
    func dismissImmediately() {
        guard isPresented else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isPresented = false
        hidesSource = false
        hiddenEventID = nil
    }
}

// MARK: - Draft

enum AddStep: Hashable {
    case sentence, name, date, goal, theme
}

struct EventDraft {
    var name = ""
    var start = Date()
    var goal = 0
    var theme: CardTheme
    var imageData: Data?
    /// A photo was picked here, so an unchanged photo isn't saved again
    var pickedNewImage = false

    /// Each new event starts on a different card, so the grid stays varied
    static func fresh() -> EventDraft {
        EventDraft(theme: CardTheme.displayThemes.randomElement() ?? .mosaic)
    }

    /// `openGoal` ("Set the next goal") moves a goal that's been reached on to the next useful stop
    init(event: SinceEvent, openGoal: Bool) {
        name = event.title
        start = event.startedAt
        theme = event.cardTheme
        imageData = event.cardTheme == .custom ? event.imageData : nil
        var goal = event.goalDays ?? 0
        if openGoal {
            let days = event.daysElapsed()
            if goal <= days { goal = Milestones.goalStops.first { $0 > days } ?? 0 }
        }
        self.goal = goal
    }

    init(theme: CardTheme) {
        self.theme = theme
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var resolvedTheme: CardTheme { theme == .custom && imageData == nil ? .mosaic : theme }

    func makeEvent(id: UUID = UUID()) -> SinceEvent {
        SinceEvent(
            id: id,
            title: trimmedName,
            // A start in the future would give negative counts
            startedAt: min(start, Date()),
            goalDays: goal > 0 ? goal : nil,
            imageData: resolvedTheme == .custom ? imageData : nil,
            cardTheme: resolvedTheme
        )
    }

    func differs(from event: SinceEvent) -> Bool {
        trimmedName != event.title
            || abs(start.timeIntervalSince(event.startedAt)) >= 1
            || resolvedTheme != event.cardTheme
            || pickedNewImage
            || goal != (event.goalDays ?? 0)
    }

    /// The edits laid over what's saved now, not over the event as it was when
    /// the card opened, so a reset made from a widget meanwhile isn't undone.
    /// Keeps the id, history, reminders and widget unit.
    func applied(to original: SinceEvent) -> SinceEvent {
        var updated = StorageManager.shared.getEvent(byId: original.id) ?? original
        updated.title = trimmedName
        if abs(start.timeIntervalSince(original.startedAt)) >= 1 {
            updated.startedAt = min(start, Date())
        }
        updated.cardTheme = resolvedTheme
        updated.goalDays = goal > 0 ? goal : nil
        if resolvedTheme != .custom {
            updated.imageData = nil
        } else if pickedNewImage {
            updated.imageData = imageData
        }
        return updated
    }

    /// The card as it would look, for the theme editor's preview
    var preview: SinceEvent {
        var event = makeEvent(id: Self.previewID)
        if event.title.isEmpty { event.title = "Something" }
        return event
    }
    private static let previewID = UUID()

    var daysElapsed: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: Date())).day ?? 0
    }

    var dateWord: String {
        let days = daysElapsed
        switch days {
        case ...0: return "today"
        case 1: return "yesterday"
        case 2..<7: return "\(days) days ago"
        default:
            let sameYear = Calendar.current.isDate(start, equalTo: Date(), toGranularity: .year)
            return sameYear
                ? start.formatted(.dateTime.day().month(.abbreviated))
                : start.formatted(.dateTime.day().month(.abbreviated).year())
        }
    }

    static func goalWord(_ goal: Int) -> String { goal > 0 ? "\(goal) days" : "not set" }
    var goalWord: String { Self.goalWord(goal) }

    /// Where the goal wheel rolls to the first time it opens with no goal:
    /// a month for something new, otherwise the next stop still ahead
    var suggestedGoal: Int {
        let floor = max(30, daysElapsed + 1)
        return Milestones.goalStops.first { $0 >= floor } ?? Milestones.goalStops.last ?? 30
    }

    var themeWord: String { resolvedTheme == .custom ? "Photo" : resolvedTheme.rawValue }

    var goalNote: String {
        guard goal > 0 else { return "Just counting, no finish line." }
        let reached = start.addingTimeInterval(TimeInterval(goal) * 86400)
        guard reached > Date() else { return "You're already past this one." }
        return "You'll get there on \(reached.formatted(.dateTime.day().month(.abbreviated).year()))"
    }
}

// MARK: - Overlay

struct AddEventOverlay: View {
    @ObservedObject var viewModel: EventViewModel
    @ObservedObject var flow: AddFlow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Shell: Equatable {
        case source
        case open
        case landing(CGRect)
    }

    private enum Face {
        case none, plus, card(SinceEvent)
    }

    /// The event being edited; nil when adding
    private let original: SinceEvent?
    /// Grows out of a tile or card (true), or out of a button (false)
    private let fromTile: Bool

    @State private var draft: EventDraft
    @State private var step: AddStep
    /// The editor we just came back from, whose words fly instead of fading in
    @State private var anchor: AddStep?
    @State private var shell: Shell = .source
    @State private var face: Face
    @State private var faceOpacity: Double = 1
    @State private var contentShown = false
    @State private var scrimShown = false
    @State private var shellOpacity: Double
    @State private var heights: [AddStep: CGFloat] = [:]
    @State private var keyboard: CGFloat = 0
    @State private var dragY: CGFloat = 0
    @State private var saving = false
    @State private var closing = false
    @State private var nameShakes = 0
    @State private var pickingPhoto = false
    /// The goal wheel rolls to a suggestion once, the first time it opens empty
    @State private var goalSuggested = false
    @Namespace private var words

    init(viewModel: EventViewModel, flow: AddFlow = .shared) {
        self.viewModel = viewModel
        self.flow = flow
        switch flow.request {
        case .add:
            original = nil
            fromTile = true
            var fresh = EventDraft.fresh()
            if let name = flow.presetName { fresh.name = name }
            flow.presetName = nil
            _draft = State(initialValue: fresh)
            _step = State(initialValue: .sentence)
            _face = State(initialValue: .plus)
            _shellOpacity = State(initialValue: 1)
        case .edit(let event, let openGoal, let fromCard):
            original = event
            fromTile = fromCard
            _draft = State(initialValue: EventDraft(event: event, openGoal: openGoal))
            _step = State(initialValue: openGoal ? .goal : .sentence)
            _face = State(initialValue: fromCard ? .card(event) : .none)
            // Out of a button there's no tile to grow from, so it fades up as it grows
            _shellOpacity = State(initialValue: fromCard ? 1 : 0)
        }
    }

    private var isEditing: Bool { original != nil }

    private let inset: CGFloat = 8
    private let topPadding: CGFloat = 30
    /// Gap above the button, the button, and the gap under it
    private let footerHeight: CGFloat = 20 + 52 + 22
    private let tileRadius: CGFloat = 24
    /// Concentric with the screen's own corners, `inset` in from them
    private var openRadius: CGFloat { DisplayCorners.concentric(inset: inset) }
    private var sourceRadius: CGFloat { fromTile ? tileRadius : 14 }

    // Motion. Springs for anything that moves or resizes, so a tap mid-way
    // retargets from where it is; strong ease-out for fades.
    private var openSpring: Animation { .spring(duration: 0.46, bounce: 0.14) }
    private var closeSpring: Animation { .spring(duration: 0.38, bounce: 0) }
    private var stepSpring: Animation { reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.42, bounce: 0.08) }
    private var landSpring: Animation { .spring(duration: 0.5, bounce: 0.16) }
    private static func easeOut(_ duration: Double) -> Animation { .timingCurve(0.23, 1, 0.32, 1, duration: duration) }

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let frame = shellFrame(in: proxy.size, origin: origin)
            let contentWidth = proxy.size.width - inset * 2

            ZStack(alignment: .topLeading) {
                Color.black
                    .opacity(scrimShown ? 0.22 * scrimFollowingDrag : 0)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: scrimTapped)
                    .allowsHitTesting(scrimShown)
                    .accessibilityHidden(true)

                card(frame: frame, contentWidth: contentWidth)
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: open)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let height = max(0, Self.windowBounds.height - end.minY)
            withAnimation(.spring(duration: 0.38, bounce: 0)) { keyboard = height }
        }
        .sheet(isPresented: $pickingPhoto) {
            ImagePicker(image: Binding(
                get: { nil },
                set: { image in
                    guard let data = image?.jpegData(compressionQuality: 0.8) else { return }
                    draft.imageData = data
                    draft.pickedNewImage = true
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) { draft.theme = .custom }
                }
            ), sourceType: .photoLibrary, requireSquareAspect: true)
        }
    }

    // MARK: Card

    private func card(frame: CGRect, contentWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.white

            steps
                .frame(width: contentWidth, alignment: .topLeading)
                .opacity(contentShown ? 1 : 0)
                .blur(radius: contentShown || reduceMotion ? 0 : 6)

            footer
                .frame(width: contentWidth - 40)
                .padding(.bottom, 22)
                .frame(width: frame.width, height: frame.height, alignment: .bottom)
                .opacity(contentShown ? 1 : 0)

            faceView
                .frame(width: frame.width, height: frame.height)
                .opacity(faceOpacity)
                .allowsHitTesting(false)
        }
        .frame(width: frame.width, height: frame.height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: shell == .open ? openRadius : sourceRadius, style: .continuous))
        .shadow(color: .black.opacity(contentShown ? 0.16 : 0), radius: 30, y: 16)
        .opacity(shellOpacity)
        .offset(x: frame.minX, y: frame.minY + dragY)
        .gesture(step == .sentence && !saving ? dismissDrag : nil)
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private var faceView: some View {
        switch face {
        case .none:
            EmptyView()
        case .plus:
            ZStack {
                Color.white
                RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.black.opacity(0.85))
            }
        case .card(let event):
            HomeEventCardView(event: event)
        }
    }

    // MARK: Steps

    private var steps: some View {
        ZStack(alignment: .topLeading) {
            if step == .sentence {
                SentenceStep(draft: draft, words: words, anchor: anchor, nameShakes: nameShakes, onOpen: go)
                    .measured { set(height: $0, for: .sentence) }
                    .transition(stepTransition)
            }
            if step == .name {
                NameStep(draft: $draft, words: words, onDone: { go(.sentence) })
                    .measured { set(height: $0, for: .name) }
                    .transition(stepTransition)
            }
            if step == .date {
                DateStep(draft: $draft, words: words)
                    .measured { set(height: $0, for: .date) }
                    .transition(stepTransition)
            }
            if step == .goal {
                GoalStep(
                    draft: $draft,
                    words: words,
                    suggests: !goalSuggested && draft.goal == 0,
                    onSuggested: { goalSuggested = true }
                )
                .measured { set(height: $0, for: .goal) }
                .transition(stepTransition)
            }
            if step == .theme {
                ThemeStep(draft: $draft, words: words, onPickPhoto: { pickingPhoto = true })
                    .measured { set(height: $0, for: .theme) }
                    .transition(stepTransition)
            }
        }
        .padding(.top, topPadding)
        .padding(.horizontal, 26)
    }

    /// The old editor blurs away quickly; the new one brings its own parts in
    /// one by one (see `stepEntrance`), so its anchored words can fly in crisp
    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .identity,
            removal: .modifier(active: StepExit(gone: true), identity: StepExit(gone: false))
                .animation(Self.easeOut(0.16))
        )
    }

    private var footer: some View {
        Button(action: primaryTapped) {
            ZStack {
                MorphText(text: step == .sentence ? "Save" : "Done", font: .allo(16, weight: .semibold), color: .white)
                    .opacity(saving ? 0 : 1)
                    .blur(radius: saving ? 4 : 0)
                TickShape()
                    .trim(from: 0, to: saving ? 1 : 0)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule().fill(canSave || step != .sentence ? Color.primaryGreen : Color.mutedGreen))
            .animation(.easeOut(duration: 0.2), value: canSave)
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(saving)
        .accessibilityLabel(step == .sentence ? (isEditing ? "Save changes" : "Save event") : "Done")
    }

    private var canSave: Bool { !draft.trimmedName.isEmpty }

    // MARK: Geometry

    /// What the card grows out of and folds back into, in window coordinates
    private var sourceInWindow: CGRect {
        if case .edit(let event, _, true) = flow.request, let frame = flow.cardFrames[event.id] {
            return frame
        }
        return flow.sourceFrame
    }

    private func shellFrame(in size: CGSize, origin: CGPoint) -> CGRect {
        switch shell {
        case .source:
            let source = sourceInWindow.offsetBy(dx: -origin.x, dy: -origin.y)
            if source.width > 0 { return source }
            return CGRect(x: size.width / 2 - 60, y: size.height / 2 - 60, width: 120, height: 120)
        case .open:
            let bottomGap = keyboard > 0 ? keyboard + inset : inset
            let available = size.height - Self.safeTop - 12 - bottomGap
            let height = min(available, topPadding + (heights[step] ?? 200) + footerHeight)
            return CGRect(x: inset, y: size.height - bottomGap - height, width: size.width - inset * 2, height: height)
        case .landing(let frame):
            return frame.offsetBy(dx: -origin.x, dy: -origin.y)
        }
    }

    private func set(height: CGFloat, for measuredStep: AddStep) {
        guard heights[measuredStep] != height else { return }
        if heights[measuredStep] == nil || shell != .open {
            heights[measuredStep] = height
        } else {
            withAnimation(stepSpring) { heights[measuredStep] = height }
        }
    }

    private var scrimFollowingDrag: Double { 1 - min(1, max(0, dragY) / 500) }

    // MARK: Actions

    private func open() {
        Task { @MainActor in
            // Let the card lay out over its source first, so it grows out of it
            try? await Task.sleep(for: .milliseconds(20))
            if reduceMotion {
                shellOpacity = 0
                shell = .open
                face = .none
                withAnimation(.easeOut(duration: 0.2)) { shellOpacity = 1; contentShown = true; scrimShown = true }
                return
            }
            withAnimation(openSpring) { shell = .open }
            withAnimation(.easeOut(duration: 0.14)) { faceOpacity = 0 }
            withAnimation(Self.easeOut(0.2)) { shellOpacity = 1 }
            withAnimation(Self.easeOut(0.3).delay(0.08)) { contentShown = true }
            withAnimation(Self.easeOut(0.3)) { scrimShown = true }
        }
    }

    private func close() {
        guard !closing, !saving else { return }
        closing = true
        dismissKeyboard()
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.18)) { shellOpacity = 0; scrimShown = false } completion: { finish() }
            return
        }
        foldIntoSource(face: original.map { Face.card($0) } ?? .plus, then: finish)
    }

    /// Back into the tile, card or button it came out of
    private func foldIntoSource(face newFace: Face, then completion: @escaping () -> Void) {
        withAnimation(Self.easeOut(0.12)) { contentShown = false }
        withAnimation(Self.easeOut(0.25)) { scrimShown = false }
        if fromTile {
            face = newFace
            withAnimation(Self.easeOut(0.18).delay(0.1)) { faceOpacity = 1 }
        } else {
            // A button has no face to become, so the card fades as it shrinks into it
            withAnimation(Self.easeOut(0.22).delay(0.08)) { shellOpacity = 0 }
        }
        withAnimation(closeSpring) {
            shell = .source
            dragY = 0
        } completion: {
            completion()
        }
    }

    /// The card has become the tile again, or the event's card
    private func finish() {
        let added = saving && !isEditing
        var quiet = Transaction()
        quiet.disablesAnimations = true
        withTransaction(quiet) {
            flow.finish()
            if !added { flow.hidesSource = false }
        }
        if added {
            // The + tile has moved along to the next slot; it fades in there
            withAnimation(.spring(duration: 0.4, bounce: 0.2).delay(0.05)) { flow.hidesSource = false }
        }
    }

    private func go(_ next: AddStep) {
        guard !saving, next != step else { return }
        if next != .name { dismissKeyboard() }
        HapticManager.shared.light()
        anchor = next == .sentence ? step : nil
        withAnimation(stepSpring) { step = next }
    }

    private func primaryTapped() {
        if step == .sentence { save() } else { go(.sentence) }
    }

    private func scrimTapped() {
        if step != .sentence { go(.sentence) } else { close() }
    }

    private func save() {
        guard canSave else {
            HapticManager.shared.warning()
            withAnimation(.linear(duration: 0.36)) { nameShakes += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { go(.name) }
            return
        }
        // Nothing changed: there's nothing to save, so just put it away
        if let original, !draft.differs(from: original) {
            close()
            return
        }
        HapticManager.shared.medium()
        withAnimation(Self.easeOut(0.32)) { saving = true }

        Task { @MainActor in
            // Let the tick draw before the card moves
            try? await Task.sleep(for: .seconds(0.38))
            let event: SinceEvent
            if let original {
                event = draft.applied(to: original)
                guard viewModel.updateEvent(event) else { return failSave() }
            } else {
                event = draft.makeEvent()
                flow.hiddenEventID = event.id
                guard viewModel.addEvent(event) else { return failSave() }
                viewModel.completeOnboarding()
            }

            if isEditing && !fromTile {
                // Back into the Edit button; the page underneath shows the change
                foldIntoSource(face: .none) {
                    HapticManager.shared.success()
                    finish()
                }
                return
            }

            face = .card(event)
            // The home grid reports where the card sits once it has laid out
            for _ in 0..<12 where flow.cardFrames[event.id] == nil {
                try? await Task.sleep(for: .milliseconds(16))
            }
            land(on: flow.cardFrames[event.id])
        }
    }

    /// The app shows why; the card stays open with everything kept
    private func failSave() {
        if !isEditing { flow.hiddenEventID = nil }
        HapticManager.shared.warning()
        withAnimation(Self.easeOut(0.2)) { saving = false }
    }

    private func land(on target: CGRect?) {
        let bounds = Self.windowBounds
        guard !reduceMotion, let target, bounds.insetBy(dx: -20, dy: -20).contains(target) else {
            // Card scrolled out of view: settle away in place instead
            withAnimation(.easeOut(duration: 0.22)) { shellOpacity = 0; scrimShown = false } completion: {
                HapticManager.shared.success()
                finish()
            }
            return
        }
        withAnimation(Self.easeOut(0.16)) { contentShown = false }
        withAnimation(.easeOut(duration: 0.2)) { faceOpacity = 1 }
        withAnimation(Self.easeOut(0.3)) { scrimShown = false }
        withAnimation(landSpring) { shell = .landing(target) } completion: {
            HapticManager.shared.success()
            finish()
        }
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let y = value.translation.height
                // Free downward; upward resists more the further it goes
                dragY = y > 0 ? y : -pow(-y, 0.7)
            }
            .onEnded { value in
                let flicked = value.velocity.height > 700 && value.translation.height > 16
                if value.translation.height > 110 || flicked {
                    close()
                } else {
                    withAnimation(.spring(duration: 0.4, bounce: 0.25)) { dragY = 0 }
                }
            }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: Window

    static var window: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow
    }
    static var windowBounds: CGRect { window?.bounds ?? CGRect(x: 0, y: 0, width: 393, height: 852) }
    static var safeTop: CGFloat { window?.safeAreaInsets.top ?? 47 }
}

// MARK: - Display corners

/// The radius of the screen's own rounded corners, so a card floating `inset`
/// in from the edges can follow them exactly
enum DisplayCorners {
    private static var cached: CGFloat = 0
    static var radius: CGFloat {
        // Read once there's a screen to ask; asked too early it would stay at zero
        if cached > 0 { return cached }
        let screen = AddEventOverlay.window?.windowScene?.screen
        // UIKit knows the hardware radius but only exposes it by key
        let key = ["_display", "Corner", "Radius"].joined()
        cached = CGFloat((screen?.value(forKey: key) as? NSNumber)?.doubleValue ?? 0)
        return cached
    }

    static func concentric(inset: CGFloat) -> CGFloat {
        // Square-cornered screens (Home button iPhones) still get soft corners
        radius > inset ? radius - inset : 28
    }
}

// MARK: - Shared pieces

private struct StepExit: ViewModifier {
    let gone: Bool
    func body(content: Content) -> some View {
        content
            .opacity(gone ? 0 : 1)
            .blur(radius: gone ? 6 : 0)
            .scaleEffect(gone ? 0.97 : 1, anchor: .top)
    }
}

/// A part of an editor arriving: faded, blurred and a touch low, then in
/// place. Staggered by `index` so the editor builds up rather than popping.
private struct StepEntrance: ViewModifier {
    let index: Int
    let enabled: Bool
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if !enabled {
            content
        } else {
            content
                .opacity(shown ? 1 : 0)
                .blur(radius: shown || reduceMotion ? 0 : 6)
                .offset(y: shown || reduceMotion ? 0 : 8)
                .scaleEffect(shown || reduceMotion ? 1 : 0.98, anchor: .topLeading)
                .onAppear {
                    let delay = 0.06 + min(Double(index) * 0.025, 0.26)
                    withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.34).delay(delay)) { shown = true }
                }
        }
    }
}

extension View {
    func stepEntrance(_ index: Int, enabled: Bool = true) -> some View {
        modifier(StepEntrance(index: index, enabled: enabled))
    }

    fileprivate func measured(_ action: @escaping (CGFloat) -> Void) -> some View {
        fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { action($0.rounded(.up)) }
    }
}

struct TickShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.54))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.4, y: rect.minY + rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.9, y: rect.minY + rect.height * 0.22))
        return path
    }
}

/// Side-to-side shake, one per increment of `shakes`
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = 7 * sin(shakes * .pi * 4) * (1 - shakes.truncatingRemainder(dividingBy: 1) * 0.6)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}
