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

    // A Dynamic Island não está no artboard 22 — a API a exige, então ela é
    // montada com os mesmos tokens. Fundo da ilha é sempre preto: a tinta aqui é
    // `ink/inverse`, não `ink`.
    private func dynamicIsland(for attributes: ReadingSessionAttributes) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                CoverPlaceholder(title: attributes.bookTitle, author: nil, width: Spacing.coverRowWidth)
                    .frame(width: Spacing.coverRowWidth, height: Spacing.coverRowHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.coverSm, style: .continuous))
            }

            DynamicIslandExpandedRegion(.trailing) {
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(Localization.LiveActivity.time)
                        .textStyle(.overline)
                        .foregroundStyle(Palette.inkInverse.opacity(0.6))

                    SessionTimer(startDate: attributes.startDate, role: .displayMetric)
                        .foregroundStyle(Palette.inkInverse)
                }
            }

            DynamicIslandExpandedRegion(.bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(attributes.bookTitle)
                        .textStyle(.headingRow)
                        .foregroundStyle(Palette.inkInverse)
                        .lineLimit(1)

                    Text(attributes.bookAuthor)
                        .textStyle(.authorRow)
                        .foregroundStyle(Palette.inkInverse.opacity(0.65))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } compactLeading: {
            Image(systemName: "book")
                .foregroundStyle(Palette.accentProgress)
        } compactTrailing: {
            SessionTimer(startDate: attributes.startDate, role: .captionDefault)
                .foregroundStyle(Palette.inkInverse)
        } minimal: {
            Image(systemName: "book")
                .foregroundStyle(Palette.accentProgress)
        }
    }
}

/// O card do lock screen: capa, sessão corrente, livro e cronômetro.
struct ReadingSessionActivityCard: View {
    let attributes: ReadingSessionAttributes

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Placeholder tipográfico, não a capa real: a extensão renderiza fora do
            // processo do app e não baixa `coverUrl`. Para a capa de verdade seria
            // preciso um App Group — o app grava a imagem no container compartilhado
            // ao abrir a sessão e passa o caminho nos attributes.
            CoverPlaceholder(title: attributes.bookTitle, author: nil, width: Spacing.coverActivityWidth)
                .frame(width: Spacing.coverActivityWidth, height: Spacing.coverActivityHeight)
                .clipShape(RoundedRectangle(cornerRadius: Radius.coverSm, style: .continuous))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Localization.LiveActivity.currentSession)
                    .textStyle(.overline)
                    .foregroundStyle(Palette.inkMeta)

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

                SessionTimer(startDate: attributes.startDate, role: .displayMetricXL)
                    .foregroundStyle(Palette.ink)
            }
        }
        .padding(Spacing.cardInset)
    }
}

/// Cronômetro que o sistema anima sozinho a partir do início da sessão.
private struct SessionTimer: View {
    let startDate: Date
    let role: TypeRole

    var body: some View {
        Text(startDate, style: .timer)
            .textStyle(role)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
