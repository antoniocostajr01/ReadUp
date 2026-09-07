import SwiftUI

/// As sete barras da semana no topo do History. Figma `21:58`.
///
/// Âmbar é a única cor cromática do sistema e vive em dois lugares: o preenchimento de
/// progresso e estas barras. Um dia sem leitura não some — vira um toco em
/// `surface/sunken`, que é o que faz a semana ser legível como uma forma.
///
/// A altura é proporcional ao dia mais alto da própria semana, não a uma meta fixa: a
/// barra maior sempre encosta no teto, então a silhueta compara os dias entre si.
struct WeekBars: View {
    /// Sete valores, do primeiro dia da semana do usuário ao último.
    let minutes: [Int]
    let labels: [String]

    private var peak: Int { max(minutes.max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            ForEach(Array(minutes.enumerated()), id: \.offset) { index, value in
                VStack(spacing: Spacing.sm) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(value > 0 ? Palette.accentProgress : Palette.surfaceSunken)
                        .frame(height: height(for: value))

                    Text(labels.indices.contains(index) ? labels[index] : "")
                        .textStyle(.overline)
                        .foregroundStyle(Palette.inkFaint)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Spacing.weekBarMaxHeight + Spacing.sm + Spacing.lg, alignment: .bottom)
        .accessibilityElement(children: .combine)
    }

    private func height(for value: Int) -> CGFloat {
        guard value > 0 else { return Spacing.weekBarEmptyHeight }
        let scaled = Spacing.weekBarMaxHeight * CGFloat(value) / CGFloat(peak)
        return max(Spacing.weekBarEmptyHeight, scaled)
    }
}

#Preview {
    WeekBars(
        minutes: [58, 88, 32, 66, 48, 0, 0],
        labels: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    )
    .padding(Spacing.gutterList)
    .background(Palette.surface)
}
