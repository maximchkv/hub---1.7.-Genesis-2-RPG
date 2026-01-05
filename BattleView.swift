// GPT_EDIT_TEST_001
import SwiftUI

struct BattleView: View {
    @EnvironmentObject private var store: GameStore

    // ... ваши константы ...

    var body: some View {
        ZStack {
            UIStyle.backgroundImage()
                .ignoresSafeArea()

            GeometryReader { geo in
                // ...
            }
            .padding(.vertical, 0)
        }
    }

    // ... остальной файл без изменений ...
}
