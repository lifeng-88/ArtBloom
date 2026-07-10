import SwiftUI

struct LegalDocumentView: View {
    @Environment(AppStore.self) private var appStore

    let kind: LegalDocumentKind

    private var document: LegalDocumentContent {
        LegalDocuments.content(for: kind, language: appStore.appLanguage)
    }

    var body: some View {
        let _ = appStore.appLanguage
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MSTypography.label(document.lastUpdated)
                    .foregroundStyle(MSColor.onSurfaceVariant)

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        MSTypography.headline(section.title)
                            .foregroundStyle(MSColor.primary)
                        Text(section.body)
                            .font(.system(size: 15))
                            .foregroundStyle(MSColor.onSurfaceVariant)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(MSSpacing.containerPadding)
            .padding(.bottom, 24)
        }
        .msBrandBackground()
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
