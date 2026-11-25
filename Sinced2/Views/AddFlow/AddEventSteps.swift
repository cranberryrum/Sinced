//
//  AddEventSteps.swift
//  Sinced2
//
//  What the add card shows: the sentence, and an editor for each of its
//  bold words. Each editor repeats its line of the sentence at the top
//  ("Since …", "started …"), and those words are matched across, so they
//  fly between the sentence and the editor instead of fading.
//

import SwiftUI

private enum Style {
    static let size: CGFloat = 26
    static let connector = Color(hex: "a3a1a3")
    static let word = Color(hex: "1a1a1a")
    static let placeholder = Color(hex: "c4c2c4")
    static let label = Color(hex: "8a888a")
    static let fill = Color(hex: "F2F2F4")

    static var connectorFont: Font { .allo(size, weight: .medium) }
    static var wordFont: Font { .allo(size, weight: .semibold) }

    /// One copy per line, so the sentence and its editors always say the same thing
    static func connector(_ step: AddStep) -> String {
        switch step {
        case .name: return "Since"
        case .date: return "started"
        case .goal: return "goal"
        case .theme: return "on"
        case .sentence: return ""
        }
    }
}

private struct Connector: View {
    let step: AddStep
    let words: Namespace.ID
    var body: some View {
        Text(Style.connector(step))
            .font(Style.connectorFont)
            .foregroundStyle(Style.connector)
            .fixedSize()
            .matchedGeometryEffect(id: "connector-\(step)", in: words)
    }
}

// MARK: - Word contents (shared by the sentence and the editor headers)

private struct DateWord: View {
    let draft: EventDraft
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 19, weight: .semibold))
            MorphText(text: draft.dateWord, font: Style.wordFont, color: Style.word)
        }
        .foregroundStyle(Style.word)
    }
}

private struct GoalWord: View {
    let draft: EventDraft
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flag")
                .font(.system(size: 18, weight: .semibold))
            MorphText(text: draft.goalWord, font: Style.wordFont, color: Style.word)
        }
        .foregroundStyle(Style.word)
    }
}

private struct ThemeWord: View {
    let draft: EventDraft
    var body: some View {
        HStack(spacing: 7) {
            ThemeSwatch(draft: draft)
                .frame(width: 21, height: 21)
            MorphText(text: draft.themeWord, font: Style.wordFont, color: Style.word)
        }
    }
}

private struct ThemeSwatch: View {
    let draft: EventDraft
    var body: some View {
        ZStack {
            if draft.resolvedTheme == .custom, let data = draft.imageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                draft.resolvedTheme.backgroundColor
                if let asset = draft.resolvedTheme.svgAssetName {
                    Image(asset).resizable().scaledToFill()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
        .id(draft.resolvedTheme.rawValue + (draft.imageData == nil ? "" : "-photo"))
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
}

/// A tappable bold word: dips and gets a soft fill under the finger
private struct WordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Style.fill)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .padding(.horizontal, -6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Sentence

struct SentenceStep: View {
    let draft: EventDraft
    let words: Namespace.ID
    /// The editor just closed; its line flies back rather than fading in
    let anchor: AddStep?
    let nameShakes: Int
    let onOpen: (AddStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            line(.name, index: 0) {
                if draft.name.isEmpty {
                    Text("something")
                        .font(Style.wordFont)
                        .foregroundStyle(Style.placeholder)
                        .overlay(alignment: .bottom) {
                            Line()
                                .stroke(Style.placeholder, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                .frame(height: 2)
                                .offset(y: -2)
                        }
                        .fixedSize()
                } else {
                    MorphText(text: draft.trimmedName, font: Style.wordFont, color: Style.word)
                }
            }
            .modifier(ShakeEffect(shakes: CGFloat(nameShakes)))

            line(.date, index: 1) { DateWord(draft: draft) }
            line(.goal, index: 2) { GoalWord(draft: draft) }
            line(.theme, index: 3) { ThemeWord(draft: draft) }
        }
    }

    private func line<Word: View>(_ step: AddStep, index: Int, @ViewBuilder word: () -> Word) -> some View {
        let flies = anchor == step
        return WrapLayout(spacing: 7, lineSpacing: 2) {
            Connector(step: step, words: words)
                .stepEntrance(index * 2, enabled: !flies)
            Button { onOpen(step) } label: { word() }
                .buttonStyle(WordButtonStyle())
                .matchedGeometryEffect(id: "word-\(step)", in: words)
                .stepEntrance(index * 2 + 1, enabled: !flies)
                .accessibilityLabel(accessibilityLabel(step))
                .accessibilityHint("Double tap to change")
        }
    }

    private func accessibilityLabel(_ step: AddStep) -> String {
        switch step {
        case .name: return "Name, \(draft.name.isEmpty ? "not set" : draft.trimmedName)"
        case .date: return "Started \(draft.dateWord)"
        case .goal: return "Goal, \(draft.goalWord)"
        case .theme: return "Card, \(draft.themeWord)"
        case .sentence: return ""
        }
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { $0.move(to: CGPoint(x: rect.minX, y: rect.midY)); $0.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)) }
    }
}

// MARK: - Name

struct NameStep: View {
    @Binding var draft: EventDraft
    let words: Namespace.ID
    let onDone: () -> Void

    @FocusState private var focused: Bool
    @State private var ideas: [String] = NameIdeas.pick(6, avoiding: [])
    @State private var shuffles = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Connector(step: .name, words: words)
                TextField("", text: $draft.name, prompt: Text("something").foregroundColor(Style.placeholder))
                    .font(Style.wordFont)
                    .foregroundStyle(Style.word)
                    .tint(.primaryGreen)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit(onDone)
                    .onChange(of: draft.name) { _, value in
                        if value.count > AddEventBottomSheet.maxTitleLength {
                            draft.name = String(value.prefix(AddEventBottomSheet.maxTitleLength))
                        }
                    }
                    .matchedGeometryEffect(id: "word-\(AddStep.name)", in: words)
                    .accessibilityLabel("Event name")
            }

            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
                .padding(.top, 8)
                .padding(.bottom, 14)
                .stepEntrance(0)

            HStack {
                Text("Need an idea?")
                    .font(.allo(14))
                    .foregroundStyle(Style.label)
                Spacer()
                shuffleButton
            }
            .stepEntrance(1)

            WrapLayout(spacing: 8, lineSpacing: 8) {
                ForEach(ideas.indices, id: \.self) { i in
                    ideaChip(ideas[i])
                        .stepEntrance(2 + i)
                }
            }
            .padding(.top, 10)
        }
        .onAppear {
            // Straight to typing, once the card has started to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
        }
    }

    private var shuffleButton: some View {
        Button(action: shuffle) {
            Image(systemName: "shuffle")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "4a484a"))
                .symbolEffect(.bounce.down, value: shuffles)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Style.fill))
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Shuffle name ideas")
    }

    private func ideaChip(_ idea: String) -> some View {
        let selected = draft.trimmedName == idea
        return Button {
            HapticManager.shared.light()
            draft.name = idea
            // A beat to see it land in the field, then back to the sentence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14, execute: onDone)
        } label: {
            MorphText(text: idea, font: .allo(14), color: selected ? .primaryGreen : Color(hex: "4a484a"))
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(Capsule().fill(selected ? Color.primaryGreen.opacity(0.08) : Color.white))
                .overlay(
                    Capsule().strokeBorder(
                        selected ? Color.primaryGreen : Color.black.opacity(0.28),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                )
                .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(idea)
    }

    /// New ideas roll in chip by chip, each morphing out of the one before
    /// it, with a tick per chip like a slot machine settling
    private func shuffle() {
        HapticManager.shared.light()
        let next = NameIdeas.pick(ideas.count, avoiding: Set(ideas + [draft.trimmedName]))
        shuffles += 1
        for i in next.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.045 * Double(i)) {
                guard i < ideas.count else { return }
                withAnimation(MorphText.animation) { ideas[i] = next[i] }
                HapticManager.shared.selection()
            }
        }
    }
}

enum NameIdeas {
    static func pick(_ count: Int, avoiding: Set<String>) -> [String] {
        let pool = AddEventBottomSheet.nameIdeas.filter { !avoiding.contains($0) }
        return Array((pool.count >= count ? pool : AddEventBottomSheet.nameIdeas).shuffled().prefix(count))
    }
}

// MARK: - Date

struct DateStep: View {
    @Binding var draft: EventDraft
    let words: Namespace.ID

    private let quick: [(String, Int)] = [("Today", 0), ("Yesterday", 1), ("A week ago", 7)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Connector(step: .date, words: words)
                DateWord(draft: draft)
                    .matchedGeometryEffect(id: "word-\(AddStep.date)", in: words)
            }

            HStack(spacing: 8) {
                ForEach(quick, id: \.1) { label, days in
                    let on = daysAgo == days
                    Button {
                        HapticManager.shared.selection()
                        let now = Date()
                        withAnimation(.spring(duration: 0.3, bounce: 0)) {
                            draft.start = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
                        }
                    } label: {
                        Text(label)
                            .font(.allo(14, weight: .medium))
                            .foregroundStyle(on ? Color.white : Color(hex: "3a383a"))
                            .padding(.horizontal, 13)
                            .frame(height: 34)
                            .background(Capsule().fill(on ? Style.word : Style.fill))
                            .animation(.easeOut(duration: 0.18), value: on)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .stepEntrance(0)

            DatePicker("Started", selection: $draft.start, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.primaryGreen)
                .font(.allo(16))
                .stepEntrance(1)
        }
    }

    private var daysAgo: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: draft.start), to: calendar.startOfDay(for: Date())).day ?? -1
    }
}

// MARK: - Goal

struct GoalStep: View {
    @Binding var draft: EventDraft
    let words: Namespace.ID
    /// Opened with no goal: roll the wheel to a suggestion, so it's clear the
    /// list moves and there's something to pick ("not set" stays one row up)
    let suggests: Bool
    let onSuggested: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 10) {
                Connector(step: .goal, words: words)
                GoalWheel(goal: $draft.goal, suggestion: suggests ? draft.suggestedGoal : nil, onSuggested: onSuggested)
                    .stepEntrance(0)
            }
            .frame(height: GoalWheel.height)

            MorphText(text: draft.goalNote, font: .allo(14), color: Style.label)
                .stepEntrance(1)
        }
    }
}

/// A scroll wheel of goal stops, the chosen one centred and the rest fading
/// and softening with distance, ticking as each one passes the middle
private struct GoalWheel: View {
    @Binding var goal: Int
    let suggestion: Int?
    let onSuggested: () -> Void
    @State private var position: Int?

    static let row: CGFloat = 44
    static let height: CGFloat = 220

    init(goal: Binding<Int>, suggestion: Int?, onSuggested: @escaping () -> Void) {
        self._goal = goal
        self.suggestion = suggestion
        self.onSuggested = onSuggested
        let start = Milestones.goalStops.contains(goal.wrappedValue) ? goal.wrappedValue : 0
        self._position = State(initialValue: start)
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Milestones.goalStops, id: \.self) { stop in
                    Text(EventDraft.goalWord(stop))
                        .font(Style.wordFont)
                        .foregroundStyle(Style.word)
                        .frame(height: Self.row)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.35, bounce: 0)) { position = stop }
                        }
                        .visualEffect { content, proxy in
                            // The wheel's middle, in this row's own coordinates
                            let middle = proxy.bounds(of: .scrollView)?.midY ?? proxy.size.height / 2
                            let distance = min(2.5, abs(middle - proxy.size.height / 2) / Self.row)
                            return content
                                .opacity(1 - distance * 0.3)
                                .scaleEffect(1 - min(distance, 2) * 0.06, anchor: .leading)
                                .blur(radius: max(0, distance - 0.6) * 0.9)
                        }
                        .accessibilityLabel(stop == 0 ? "No goal" : "\(stop) days")
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $position, anchor: .center)
        .contentMargins(.vertical, (Self.height - Self.row) / 2, for: .scrollContent)
        .frame(height: Self.height)
        .mask(
            LinearGradient(
                stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.32),
                        .init(color: .black, location: 0.68), .init(color: .clear, location: 1)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .sensoryFeedback(.selection, trigger: position)
        .onChange(of: position) { _, stop in
            if let stop { goal = stop }
        }
        .task {
            guard let suggestion else { return }
            // Once the editor has built up, so the roll reads as a hint
            try? await Task.sleep(for: .seconds(0.35))
            onSuggested()
            withAnimation(.spring(duration: 0.7, bounce: 0.12)) { position = suggestion }
        }
    }
}

// MARK: - Theme

struct ThemeStep: View {
    @Binding var draft: EventDraft
    let words: Namespace.ID
    let onPickPhoto: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Connector(step: .theme, words: words)
                ThemeWord(draft: draft)
                    .matchedGeometryEffect(id: "word-\(AddStep.theme)", in: words)
            }

            ZStack {
                HomeEventCardView(event: draft.preview)
                    .id(draft.resolvedTheme.rawValue + (draft.imageData == nil ? "" : "-photo"))
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 1.04))
                    ))
            }
            .frame(width: 136, height: 136)
            .frame(maxWidth: .infinity)
            .stepEntrance(0)

            LazyVGrid(columns: columns, spacing: 10) {
                photoTile.stepEntrance(1)
                ForEach(Array(CardTheme.displayThemes.enumerated()), id: \.element) { i, theme in
                    tile(theme).stepEntrance(2 + i)
                }
            }
        }
    }

    private func tile(_ theme: CardTheme) -> some View {
        Button {
            guard draft.theme != theme else { return }
            HapticManager.shared.light()
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) { draft.theme = theme }
        } label: {
            ZStack {
                theme.backgroundColor
                if let asset = theme.svgAssetName {
                    Image(asset).resizable().scaledToFill()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(selectionRing(draft.resolvedTheme == theme))
        }
        .buttonStyle(ThemeCardButtonStyle())
        .accessibilityLabel(theme.rawValue)
        .accessibilityAddTraits(draft.resolvedTheme == theme ? .isSelected : [])
    }

    private var photoTile: some View {
        Button {
            HapticManager.shared.light()
            if draft.imageData != nil, draft.theme != .custom {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) { draft.theme = .custom }
            } else {
                onPickPhoto()
            }
        } label: {
            ZStack {
                if let data = draft.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Color.white
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Style.word)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(selectionRing(draft.resolvedTheme == .custom))
        }
        .buttonStyle(ThemeCardButtonStyle())
        .accessibilityLabel(draft.imageData == nil ? "Choose a photo" : "Photo")
    }

    private func selectionRing(_ on: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Style.word, lineWidth: on ? 3 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: on ? 2 : 0)
                    .padding(3)
            )
            .animation(.spring(duration: 0.3, bounce: 0.3), value: on)
    }
}
