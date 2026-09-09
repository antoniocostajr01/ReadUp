//
//  ReadingSessionLiveActivity.swift
//  ReadUpWidgets
//

import ActivityKit
import SwiftUI
import WidgetKit

/// A Live Activity da sessão de leitura. Figma `Screens` → `22 · Lock screen —
/// Live Activity` (nó `80:289`, card `83:299`).
///
/// O tempo é `Text(_:style: .timer)` sobre `attributes.startDate`: o sistema
/// redesenha o cronômetro sozinho, então a atividade não precisa de nenhum
/// `update` — nem local nem por push.
struct ReadingSessionLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingSessionAttributes.self) { context in
            ReadingSessionActivityCard(attributes: context.attributes)
                .activityBackgroundTint(Palette.surfaceRaised)
                .activitySystemActionForegroundColor(Palette.ink)
        } dynamicIsland: { context in
            dynamicIsland(for: context.attributes)
        }
    }

    // A Dynamic Island foi desligada: vazia em todas as regiões.
    //
    // Não dá para omiti-la — `ActivityConfiguration` exige o builder, e num aparelho
    // com ilha o sistema sempre reserva o pill enquanto a atividade existe. Sem
    // conteúdo ele fica preto e mudo, que é o mais perto de não existir que a API
    // permite. A sessão se lê no lock screen.
    private func dynamicIsland(for attributes: ReadingSessionAttributes) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.center) { EmptyView() }
        } compactLeading: {
            EmptyView()
        } compactTrailing: {
            EmptyView()
        } minimal: {
            EmptyView()
        }
    }
}

/// O card do lock screen: capa, sessão corrente, livro e cronômetro.
struct ReadingSessionActivityCard: View {
    let attributes: ReadingSessionAttributes

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            SessionCover(title: attributes.bookTitle)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Localization.LiveActivity.currentSession)
                    .textStyle(.overline)
                    .foregroundStyle(Palette.inkMeta)
                    // Uma linha, sempre: quebrada no meio ("CURRENT / SESSION") a
                    // etiqueta some como etiqueta e vira mais um bloco de texto.
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(attributes.bookTitle)
                    .textStyle(.headingRow)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(attributes.bookAuthor)
                    .textStyle(.authorRow)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.sm)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(Localization.LiveActivity.time)
                    .textStyle(.overline)
                    .foregroundStyle(Palette.inkMeta)
                    .lineLimit(1)

                SessionTimer(range: attributes.timerRange, role: .displayMetricXL)
                    .foregroundStyle(Palette.ink)
            }
        }
        .padding(Spacing.cardInset)
    }
}

/// A capa da sessão: a imagem real que o app deixou no App Group, e o placeholder
/// tipográfico quando o livro não tem capa (ou quando o arquivo ainda não chegou).
private struct SessionCover: View {
    let title: String
    var width: CGFloat = Spacing.coverActivityWidth
    var height: CGFloat = Spacing.coverActivityHeight

    var body: some View {
        Group {
            if let cover = SharedCoverStore.read() {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
            } else {
                CoverPlaceholder(title: title, author: nil, width: width)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: Radius.coverSm, style: .continuous))
    }
}

/// Cronômetro que o sistema anima sozinho a partir do início da sessão.
///
/// `Text(timerInterval:countsDown:)`, não `Text(_:style: .timer)`: no contexto de
/// widget o segundo cai para uma descrição relativa e o card mostra "<1 minute"
/// no lugar do relógio.
///
/// `showsHours: false` é o que mantém o relógio em mm:ss, como no artboard — e é
/// também o que o mantém estreito: o texto reserva a largura do maior valor que o
/// intervalo pode produzir, e com horas ligadas ele pede largura de "8:00:00" e
/// espreme as outras colunas do card até sumirem.
private struct SessionTimer: View {
    let range: ClosedRange<Date>
    let role: TypeRole

    var body: some View {
        Text(timerInterval: range, countsDown: false, showsHours: false)
            .textStyle(role)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            // O texto reserva a largura do maior valor que o intervalo pode
            // produzir, e desenhava os dígitos centrados nessa sobra — fora de
            // prumo com o rótulo acima. Alinhado à direita, os dois batem.
            .multilineTextAlignment(.trailing)
    }
}
