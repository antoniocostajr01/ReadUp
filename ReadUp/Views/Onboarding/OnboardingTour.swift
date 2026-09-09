import SwiftUI

/// O tour que abre o app na primeira execução, antes de qualquer conta existir.
/// Figma, section `Onboarding`: `04 · Three ways to add` → `05 · Live Activity`
/// → `01 · Welcome`.
///
/// As duas primeiras telas têm "Pular", que vai direto para a última — a Welcome,
/// que já é a porta do fluxo de auth e por isso não tem o botão. A seleção de
/// gêneros **não** faz parte daqui: ela acontece depois do login, na fase
/// `.onboarding` do `AuthManager`.
struct OnboardingTour: View {

    /// Visto uma vez, nunca mais: logout cai direto na Welcome.
    @AppStorage("hasSeenOnboardingTour") private var hasSeenTour = false
    @State private var step = 0

    var body: some View {
        ZStack {
            if hasSeenTour {
                WelcomeView()
                    .transition(.opacity)
            } else {
                page(at: step)
                    .id(step)
                    .transition(.opacity)
            }
        }
        .animation(Motion.easeStandard, value: step)
        .animation(Motion.easeStandard, value: hasSeenTour)
    }

    @ViewBuilder
    private func page(at index: Int) -> some View {
        switch index {
        case 0:
            OnboardingPage(
                title: Localization.Onboarding.addTitle.string,
                subtitle: Localization.Onboarding.addSubtitle.string,
                cta: Localization.Generic.continue.string,
                progress: 1,
                onSkip: finish,
                onContinue: advance
            ) {
                AddModesPreview()
            }

        default:
            OnboardingPage(
                title: Localization.Onboarding.liveTitle.string,
                subtitle: Localization.Onboarding.liveSubtitle.string,
                cta: Localization.Generic.continue.string,
                progress: 2,
                onSkip: finish,
                onContinue: advance
            ) {
                LiveActivityPreview()
            }
        }
    }

    private func advance() {
        if step + 1 < Self.pageCount { step += 1 } else { finish() }
    }

    private func finish() { hasSeenTour = true }

    static let pageCount = 2
}

// MARK: - Esqueleto de uma página

/// Barra com o "Pular", cabeçalho serifado, corpo centrado e a pílula no rodapé —
/// o mesmo osso das duas telas do tour.
private struct OnboardingPage<Content: View>: View {
    let title: String
    let subtitle: String
    let cta: String
    /// Passo atual, 1-based. A Welcome não conta: ela é a chegada do tour, não um
    /// passo dele — e continua servindo de porta de auth depois do tour aposentado.
    let progress: Int
    /// `nil` esconde o botão: é assim que a última tela some com ele.
    let onSkip: (() -> Void)?
    let onContinue: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ProgressTrack(value: Double(progress) / Double(OnboardingTour.pageCount))
                    .frame(width: 88)

                Spacer()

                if let onSkip {
                    Button(action: onSkip) {
                        Text(Localization.Onboarding.skip.string)
                            .textStyle(.label)
                            .foregroundStyle(.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, Spacing.sm)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .textStyle(.titleScreen)
                    .foregroundStyle(.ink)
                    // Sem isto o título serifado ganha uma linha só e trunca:
                    // o corpo do meio, que estica, come a altura do cabeçalho.
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .textStyle(.bodySupporting)
                    .foregroundStyle(.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ReadUpButton(title: cta, variant: .primary, action: onContinue)
        }
        .padding(.top, Spacing.xl - 4)
        .padding(.horizontal, Spacing.gutterDetail)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// MARK: - Corpo 1: os três modos de registro

/// Os mesmos três caminhos que o `addOptionsSheet` da Library oferece — se um for
/// adicionado lá, tem que aparecer aqui também.
private struct AddModesPreview: View {

    private struct Mode: Identifiable {
        let icon: String
        let title: String
        let body: String
        var id: String { icon }
    }

    private let modes: [Mode] = [
        Mode(icon: "barcode.viewfinder",
             title: Localization.Onboarding.addScanTitle.string,
             body: Localization.Onboarding.addScanBody.string),
        Mode(icon: "magnifyingglass",
             title: Localization.Onboarding.addSearchTitle.string,
             body: Localization.Onboarding.addSearchBody.string),
        Mode(icon: "square.and.pencil",
             title: Localization.Onboarding.addManualTitle.string,
             body: Localization.Onboarding.addManualBody.string),
    ]

    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(modes) { mode in
                HStack(spacing: 14) {
                    Image(systemName: mode.icon)
                        .font(.iconLabel)
                        .foregroundStyle(.ink)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Palette.surfaceControl))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(mode.title)
                            .textStyle(.headingRow)
                            .foregroundStyle(.ink)

                        Text(mode.body)
                            .textStyle(.captionFine)
                            .foregroundStyle(.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(Spacing.lg)
                .cardSurface(radius: Radius.card)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Palette.border, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Corpo 2: a Live Activity na tela de bloqueio

/// Uma maquete estática do card do widget. Não dá para reusar
/// `ReadingSessionActivityCard`: ele vive na extensão `ReadUpWidgets`, que o app
/// não importa — então o card é redesenhado aqui com os mesmos tokens.
private struct LiveActivityPreview: View {

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: 20) {
                VStack(spacing: 2) {
                    // Data e hora do aparelho: a maquete fica coerente com o relógio
                    // real e não precisa de string traduzida.
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .textStyle(.captionDefault)

                    Text(Date.now, format: .dateTime.hour().minute())
                        .textStyle(.displayMetricXL)
                }
                .foregroundStyle(Palette.inkOnArt)

                activityCard
            }
            .padding(.vertical, 26)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous)
                    .fill(Palette.surfaceNight)
            )

            Text(Localization.Onboarding.liveNote.string)
                .textStyle(.captionFine)
                .foregroundStyle(.inkFaint)
                .multilineTextAlignment(.center)
        }
    }

    private var activityCard: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image("1984book")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Spacing.coverActivityWidth, height: Spacing.coverActivityHeight)
                .clipShape(RoundedRectangle(cornerRadius: Radius.coverSm, style: .continuous))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Localization.Onboarding.liveCurrentSession.string)
                    .textStyle(.overline)
                    .foregroundStyle(.inkMeta)
                    // Uma linha, sempre — mesma regra do card real no widget.
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("1984")
                    .textStyle(.headingRow)
                    .foregroundStyle(.ink)

                Text("George Orwell")
                    .textStyle(.authorRow)
                    .foregroundStyle(.inkMuted)
            }

            Spacer(minLength: Spacing.sm)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(Localization.Onboarding.liveTimeLabel.string)
                    .textStyle(.overline)
                    .foregroundStyle(.inkMeta)

                Text("42:15")
                    .textStyle(.displayMetricXL)
                    .foregroundStyle(.ink)
            }
        }
        .padding(Spacing.lg)
        .cardSurface(radius: Radius.panel)
    }
}

#Preview {
    NavigationStack {
        OnboardingTour()
            .environment(AuthManager())
    }
}
