import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: RootlyStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: RootlySheet?

    var body: some View {
        NavigationStack {
            ZStack {
                RLTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Rootly")
                                .font(RLTheme.titleFont)
                                .foregroundStyle(RLTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddCutting(isPro: purchases.isPro) {
                                    activeSheet = .addCutting
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(RLTheme.terracotta)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addCuttingButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        patienceCard

                        if store.activeCuttings.isEmpty {
                            emptyState
                        } else {
                            cuttingsList
                        }

                        if !store.pottedCuttings.isEmpty {
                            pottedSection
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addCutting:
                    CuttingFormView(existing: nil)
                case .editCutting(let cutting):
                    CuttingFormView(existing: cutting)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    /// Quirky signature feature: "Greenhouse Patience" — a running tally
    /// of total days spent waiting across all active cuttings, framed as
    /// a badge of gardener patience rather than a chore.
    private var patienceCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 30))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("GREENHOUSE PATIENCE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.75))
                    .tracking(1.0)
                Text("\(store.totalDaysWaiting) days waited across all cuttings")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .accessibilityIdentifier("patienceCard")
        .padding(16)
        .background(RLTheme.moss)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 18)
    }

    private var cuttingsList: some View {
        VStack(spacing: 12) {
            ForEach(store.activeCuttings) { cutting in
                CuttingCard(
                    cutting: cutting,
                    onAdvance: { store.advanceStage(cutting.id) },
                    onPot: { store.markPotted(cutting.id) },
                    onEdit: { activeSheet = .editCutting(cutting) }
                )
            }
        }
        .padding(.horizontal, 18)
    }

    private var pottedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Potted")
                .font(RLTheme.headlineFont)
                .foregroundStyle(RLTheme.ink)
                .padding(.horizontal, 18)
            ForEach(store.pottedCuttings) { cutting in
                HStack {
                    Text(cutting.plantName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RLTheme.ink)
                    Spacer()
                    Text("Potted")
                        .font(.caption)
                        .foregroundStyle(RLTheme.moss)
                }
                .padding(12)
                .background(RLTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RLTheme.rule, lineWidth: 1))
                .padding(.horizontal, 18)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundStyle(RLTheme.inkFaded)
            Text("No cuttings yet")
                .font(RLTheme.headlineFont)
                .foregroundStyle(RLTheme.ink)
            Text("Add a cutting to start tracking its root progress.")
                .font(.subheadline)
                .foregroundStyle(RLTheme.inkFaded)
        }
        .padding(.top, 24)
        .padding(.horizontal, 18)
    }
}

struct CuttingCard: View {
    let cutting: Cutting
    var onAdvance: () -> Void
    var onPot: () -> Void
    var onEdit: () -> Void

    private var isFinalStage: Bool { cutting.stage == .readyToPot }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Button(action: onEdit) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cutting.plantName)
                            .font(RLTheme.headlineFont)
                            .foregroundStyle(RLTheme.ink)
                        Text("\(cutting.method) · Day \(cutting.daysSinceStart)")
                            .font(.caption)
                            .foregroundStyle(RLTheme.inkFaded)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                RootJarView(stage: cutting.stage)
                    .frame(width: 64, height: 64)
                    .accessibilityIdentifier("rootJar_\(cutting.plantName)")
                    .accessibilityValue(cutting.stage.label)
            }

            Text(cutting.stage.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RLTheme.terracotta)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                if !isFinalStage {
                    Button("Advance Stage", action: onAdvance)
                        .buttonStyle(.plain)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RLTheme.terracotta)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("advanceStageButton_\(cutting.plantName)")
                } else {
                    Button("Mark Potted", action: onPot)
                        .buttonStyle(.plain)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RLTheme.moss)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("markPottedButton_\(cutting.plantName)")
                }
            }
        }
        .padding(14)
        .background(RLTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RLTheme.rule, lineWidth: 1))
    }
}

/// A literal propagation jar that visually grows root filaments as the
/// cutting advances through stages — more/longer roots at later stages.
struct RootJarView: View {
    let stage: RootStage

    var body: some View {
        ZStack(alignment: .top) {
            // jar body
            RoundedRectangle(cornerRadius: 8)
                .fill(RLTheme.terracotta.opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(RLTheme.terracotta, lineWidth: 2))
                .padding(.top, 18)

            // root filaments — count and length scale with stage
            HStack(spacing: 6) {
                ForEach(0..<rootCount, id: \.self) { i in
                    Capsule()
                        .fill(RLTheme.moss)
                        .frame(width: 3, height: rootLength(for: i))
                }
            }
            .padding(.top, 22)
            .animation(.easeOut(duration: 0.5), value: stage)
        }
    }

    private var rootCount: Int {
        switch stage {
        case .cut, .callusing: return 0
        case .rootingStarted: return 2
        case .rootsGrowing: return 4
        case .readyToPot: return 5
        }
    }

    private func rootLength(for index: Int) -> CGFloat {
        switch stage {
        case .rootsGrowing: return CGFloat(14 + (index % 2) * 8)
        case .readyToPot: return CGFloat(22 + (index % 3) * 6)
        default: return 10
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(RootlyStore())
        .environmentObject(PurchaseManager())
}
