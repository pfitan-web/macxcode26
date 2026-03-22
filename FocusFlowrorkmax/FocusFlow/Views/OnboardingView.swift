import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage: Int = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("brain.head.profile.fill", "Bienvenue sur NeuroAssist", "Votre assistant intelligent conçu pour les esprits neuroatypiques.", .indigo),
        ("calendar.badge.clock", "Planification Visuelle", "Visualisez votre journée en blocs de temps colorés pour combattre la cécité temporelle.", .blue),
        ("list.bullet.clipboard.fill", "Tâches Décomposées", "Transformez les objectifs complexes en étapes simples et actionnables.", .purple),
        ("timer", "Focus Immersif", "Timer Pomodoro avec sons d'ambiance pour maintenir votre concentration.", .orange),
        ("chart.line.uptrend.xyaxis", "Suivi de l'Humeur", "Comprenez vos patterns émotionnels et d'énergie au fil du temps.", .green),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 32) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(page.color.opacity(0.15))
                                .frame(width: 160, height: 160)

                            Circle()
                                .fill(page.color.opacity(0.08))
                                .frame(width: 220, height: 220)

                            Image(systemName: page.icon)
                                .font(.system(size: 64))
                                .foregroundStyle(page.color)
                                .symbolEffect(.bounce, value: currentPage == index)
                        }

                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)

                            Text(page.subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)

            VStack(spacing: 16) {
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Suivant" : "Commencer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                if currentPage < pages.count - 1 {
                    Button("Passer") {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
    }
}
