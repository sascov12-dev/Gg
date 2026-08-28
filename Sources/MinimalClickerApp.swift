import SwiftUI
import UIKit

@main
struct MinimalClickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @AppStorage("coins") private var coins: Int = 0
    @State private var pressed = false
    @State private var showPlusOne = false

    private let green = Color(red: 0.12, green: 0.68, blue: 0.34)

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("\(coins) монет")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.top, 70)

                Spacer()

                ZStack {
                    if showPlusOne {
                        Text("+1")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(green)
                            .offset(y: -150)
                            .transition(.opacity.combined(with: .scale))
                    }

                    Button {
                        tap()
                    } label: {
                        Text("ЖМИ")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 220, height: 220)
                            .background(green)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(pressed ? 0.94 : 1)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                withAnimation(.easeOut(duration: 0.07)) { pressed = true }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) { pressed = false }
                            }
                    )
                }

                Spacer()

                Text("Нажимай и собирай монеты")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 38)
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.light)
    }

    private func tap() {
        coins += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.easeOut(duration: 0.12)) {
            showPlusOne = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.15)) {
                showPlusOne = false
            }
        }
    }
}
