import Foundation

enum LegalDocumentKind: Hashable {
    case privacyPolicy
    case termsOfService
}

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct LegalDocumentContent {
    let title: String
    let lastUpdated: String
    let sections: [LegalSection]
}

enum LegalDocuments {
    static func content(for kind: LegalDocumentKind, language: AppLanguage) -> LegalDocumentContent {
        switch resolvedLanguage(language) {
        case .zhHant:
            return kind == .privacyPolicy ? privacyPolicyZhHant : termsOfServiceZhHant
        case .zhHans:
            return kind == .privacyPolicy ? privacyPolicyZhHans : termsOfServiceZhHans
        case .en, .system:
            return kind == .privacyPolicy ? privacyPolicyEn : termsOfServiceEn
        }
    }

    private static func resolvedLanguage(_ language: AppLanguage) -> AppLanguage {
        guard language == .system else { return language }
        let locale = Locale.current
        guard let code = locale.language.languageCode?.identifier, code.hasPrefix("zh") else {
            return .en
        }
        if locale.language.script?.identifier == "Hant" {
            return .zhHant
        }
        let identifier = locale.identifier
        if identifier.contains("Hant") || identifier.contains("TW")
            || identifier.contains("HK") || identifier.contains("MO") {
            return .zhHant
        }
        return .zhHans
    }

    // MARK: - Privacy Policy (Simplified Chinese)

    private static let privacyPolicyZhHans = LegalDocumentContent(
        title: "隐私政策",
        lastUpdated: "最近更新：2026年7月9日",
        sections: [
            LegalSection(
                title: "引言",
                body: "欢迎使用艺绽（以下简称「本应用」）。我们重视您的隐私，并致力于以透明、负责的方式处理相关信息。本隐私政策说明我们在您使用本应用时如何收集、使用、存储及保护信息。"
            ),
            LegalSection(
                title: "我们收集的信息",
                body: """
                本应用以本地功能为主，不会要求您注册账号。我们可能处理以下信息：

                • 设备标识符：为区分设备并在本机持久化，我们会在系统钥匙串中保存匿名设备 ID，不会用于跨应用追踪。
                • 您创作的内容：包括绘画笔迹、导入的照片、作品标题、草稿及收藏记录，默认保存在您的设备本地。
                • 应用设置：如语言、外观主题及功能偏好，保存在本机。
                • 图片缓存：为提升加载速度，来自网络的示例图片可能缓存在本机，您可在设置中清除。
                """
            ),
            LegalSection(
                title: "权限说明",
                body: """
                • 相册访问：仅在您主动导入照片作为画布背景或参考图时请求，我们不会未经同意访问您的相册。
                • 网络访问：用于加载示例模板、社区展示图片等资源；除加载所需外，不会上传您的个人照片至我们的服务器。
                """
            ),
            LegalSection(
                title: "信息的使用",
                body: """
                我们收集的信息仅用于：

                • 提供绘画、编辑、保存与作品管理功能；
                • 记住您的语言与界面偏好；
                • 改善应用稳定性与使用体验。

                我们不会将您的个人信息出售给第三方，也不会将其用于与本应用无关的广告定向。
                """
            ),
            LegalSection(
                title: "本地存储与第三方",
                body: """
                您的作品与设置主要存储在设备本地。本应用使用 Unsplash 等平台提供的示例图片，相关服务可能根据其自身政策处理技术日志。

                若您删除应用，本地保存的作品、缓存及偏好设置将一并移除（钥匙串中的设备 ID 也可能被系统清除）。
                """
            ),
            LegalSection(
                title: "您的权利",
                body: """
                您可以通过应用内功能：

                • 删除作品、草稿及收藏；
                • 清除图片缓存与灵感收藏；
                • 在设置中切换语言与外观。

                如需进一步了解数据处理情况，可通过 App Store 页面提供的联系方式与我们取得联系。
                """
            ),
            LegalSection(
                title: "儿童隐私",
                body: "本应用不面向 13 周岁以下儿童主动收集个人信息。若您认为我们在未经监护人同意的情况下收集了儿童信息，请联系我们，我们将尽快删除相关数据。"
            ),
            LegalSection(
                title: "政策更新",
                body: "我们可能适时更新本隐私政策。重大变更时，我们会在应用内或通过其他合理方式提示您。继续使用本应用即表示您接受更新后的政策。"
            )
        ]
    )

    // MARK: - Privacy Policy (Traditional Chinese)

    private static let privacyPolicyZhHant = LegalDocumentContent(
        title: "隱私權政策",
        lastUpdated: "最近更新：2026年7月9日",
        sections: [
            LegalSection(
                title: "引言",
                body: "歡迎使用藝綻（以下簡稱「本應用」）。我們重視您的隱私，並致力於以透明、負責的方式處理相關資訊。本隱私權政策說明我們在您使用本應用時如何收集、使用、儲存及保護資訊。"
            ),
            LegalSection(
                title: "我們收集的資訊",
                body: """
                本應用以本地功能為主，不會要求您註冊帳號。我們可能處理以下資訊：

                • 裝置識別碼：為區分裝置並在本機持久化，我們會在系統鑰匙圈中保存匿名裝置 ID，不會用於跨應用追蹤。
                • 您創作的內容：包括繪畫筆跡、匯入的照片、作品標題、草稿及收藏記錄，預設保存在您的裝置本地。
                • 應用設定：如語言、外觀主題及功能偏好，保存在本機。
                • 圖片快取：為提升載入速度，來自網路的範例圖片可能快取在本機，您可在設定中清除。
                """
            ),
            LegalSection(
                title: "權限說明",
                body: """
                • 相簿存取：僅在您主動匯入照片作為畫布背景或參考圖時請求，我們不會未經同意存取您的相簿。
                • 網路存取：用於載入範例模板、社群展示圖片等資源；除載入所需外，不會上傳您的個人照片至我們的伺服器。
                """
            ),
            LegalSection(
                title: "資訊的使用",
                body: """
                我們收集的資訊僅用於：

                • 提供繪畫、編輯、保存與作品管理功能；
                • 記住您的語言與介面偏好；
                • 改善應用穩定性與使用體驗。

                我們不會將您的個人資訊出售給第三方，也不會將其用於與本應用無關的廣告定向。
                """
            ),
            LegalSection(
                title: "本地儲存與第三方",
                body: """
                您的作品與設定主要儲存在裝置本地。本應用使用 Unsplash 等平台提供的範例圖片，相關服務可能根據其自身政策處理技術日誌。

                若您刪除應用，本地保存的作品、快取及偏好設定將一併移除（鑰匙圈中的裝置 ID 也可能被系統清除）。
                """
            ),
            LegalSection(
                title: "您的權利",
                body: """
                您可以透過應用內功能：

                • 刪除作品、草稿及收藏；
                • 清除圖片快取與靈感收藏；
                • 在設定中切換語言與外觀。

                如需進一步了解資料處理情況，可透過 App Store 頁面提供的聯絡方式與我們取得聯繫。
                """
            ),
            LegalSection(
                title: "兒童隱私",
                body: "本應用不面向 13 週歲以下兒童主動收集個人資訊。若您認為我們在未經監護人同意的情況下收集了兒童資訊，請聯絡我們，我們將儘快刪除相關資料。"
            ),
            LegalSection(
                title: "政策更新",
                body: "我們可能適時更新本隱私權政策。重大變更時，我們會在應用內或透過其他合理方式提示您。繼續使用本應用即表示您接受更新後的政策。"
            )
        ]
    )

    // MARK: - Privacy Policy (English)

    private static let privacyPolicyEn = LegalDocumentContent(
        title: "Privacy Policy",
        lastUpdated: "Last updated: July 9, 2026",
        sections: [
            LegalSection(
                title: "Introduction",
                body: "Welcome to ArtBloom (\"the App\"). We respect your privacy and are committed to handling information in a transparent and responsible way. This Privacy Policy explains how we collect, use, store, and protect information when you use the App."
            ),
            LegalSection(
                title: "Information We Collect",
                body: """
                The App is primarily local and does not require account registration. We may process:

                • Device identifier: an anonymous device ID stored in the system Keychain for on-device persistence, not used for cross-app tracking.
                • Your creations: brush strokes, imported photos, artwork titles, drafts, and favorites, stored locally by default.
                • App settings: such as language, appearance, and preferences, stored on your device.
                • Image cache: sample images from the network may be cached locally to improve loading; you can clear the cache in Settings.
                """
            ),
            LegalSection(
                title: "Permissions",
                body: """
                • Photo Library: requested only when you choose to import a photo as a canvas background or reference. We do not access your library without your action.
                • Network: used to load sample templates and showcase images. We do not upload your personal photos to our servers for this purpose.
                """
            ),
            LegalSection(
                title: "How We Use Information",
                body: """
                We use information only to:

                • Provide drawing, editing, saving, and artwork management features;
                • Remember your language and interface preferences;
                • Improve stability and user experience.

                We do not sell your personal information to third parties or use it for unrelated ad targeting.
                """
            ),
            LegalSection(
                title: "Local Storage & Third Parties",
                body: """
                Your artworks and settings are stored mainly on your device. The App uses sample images from platforms such as Unsplash; those services may process technical logs under their own policies.

                If you delete the App, locally saved artworks, cache, and preferences are removed (the Keychain device ID may also be cleared by the system).
                """
            ),
            LegalSection(
                title: "Your Rights",
                body: """
                Within the App you can:

                • Delete artworks, drafts, and favorites;
                • Clear image cache and inspiration favorites;
                • Change language and appearance in Settings.

                For further questions, contact us via the App Store listing.
                """
            ),
            LegalSection(
                title: "Children's Privacy",
                body: "The App is not directed at children under 13, and we do not knowingly collect their personal information. If you believe we have done so without parental consent, please contact us and we will delete it promptly."
            ),
            LegalSection(
                title: "Policy Updates",
                body: "We may update this Privacy Policy from time to time. For material changes, we will notify you in the App or by other reasonable means. Continued use constitutes acceptance of the updated policy."
            )
        ]
    )

    // MARK: - Terms of Service (Simplified Chinese)

    private static let termsOfServiceZhHans = LegalDocumentContent(
        title: "用户协议",
        lastUpdated: "最近更新：2026年7月9日",
        sections: [
            LegalSection(
                title: "接受条款",
                body: "下载、安装或使用艺绽，即表示您同意本用户协议。若您不同意，请停止使用并卸载本应用。"
            ),
            LegalSection(
                title: "服务说明",
                body: """
                艺绽是一款创意绘画与图像编辑应用，提供画布绘制、模板风格、作品保存与管理等功能。我们会持续改进产品，可能对功能进行更新、调整或暂停，并将尽力保证服务的稳定性。
                """
            ),
            LegalSection(
                title: "用户内容",
                body: """
                您对自己导入、绘制或保存的内容享有相应权利，并应确保拥有合法使用权。您对上传或导入的内容承担全部责任，不得包含违法、侵权、骚扰或其他不当材料。

                您的作品默认保存在本地设备，我们不会在未经您操作的情况下将作品内容上传至服务器。
                """
            ),
            LegalSection(
                title: "知识产权",
                body: """
                本应用及其界面设计、标识、代码等知识产权归开发者所有。应用内提供的示例模板与展示图片可能来自第三方授权内容，仅供个人学习与非商业创作参考，请遵守相应授权条款。
                """
            ),
            LegalSection(
                title: "合理使用",
                body: """
                您同意不得：

                • 以任何方式破坏、反编译或干扰本应用正常运行；
                • 利用本应用从事违法活动或侵犯他人权益的行为；
                • 批量抓取、复制或传播应用内受保护的内容用于商业用途。
                """
            ),
            LegalSection(
                title: "免责声明",
                body: """
                本应用按「现状」提供。在法律允许的最大范围内，我们不对因使用或无法使用本应用而产生的间接、附带或特殊损害承担责任。您应自行备份重要作品，因设备故障、误删或系统原因造成的数据丢失，我们将在合理范围内协助，但不承担赔偿责任。
                """
            ),
            LegalSection(
                title: "协议变更",
                body: "我们可能修订本协议。更新后继续使用本应用，即视为您接受修订内容。重大变更将通过应用内提示或其他合理方式告知。"
            ),
            LegalSection(
                title: "联系我们",
                body: "如对本协议有任何疑问，请通过 App Store 应用页面提供的开发者联系方式与我们取得联系。"
            )
        ]
    )

    // MARK: - Terms of Service (Traditional Chinese)

    private static let termsOfServiceZhHant = LegalDocumentContent(
        title: "使用者協議",
        lastUpdated: "最近更新：2026年7月9日",
        sections: [
            LegalSection(
                title: "接受條款",
                body: "下載、安裝或使用藝綻，即表示您同意本使用者協議。若您不同意，請停止使用並解除安裝本應用。"
            ),
            LegalSection(
                title: "服務說明",
                body: """
                藝綻是一款創意繪畫與圖像編輯應用，提供畫布繪製、模板風格、作品保存與管理等功能。我們會持續改進產品，可能對功能進行更新、調整或暫停，並將盡力保證服務的穩定性。
                """
            ),
            LegalSection(
                title: "使用者內容",
                body: """
                您對自己匯入、繪製或保存的內容享有相應權利，並應確保擁有合法使用權。您對上傳或匯入的內容承擔全部責任，不得包含違法、侵權、騷擾或其他不當材料。

                您的作品預設保存在本地裝置，我們不會在未經您操作的情況下將作品內容上傳至伺服器。
                """
            ),
            LegalSection(
                title: "智慧財產權",
                body: """
                本應用及其介面設計、標識、程式碼等智慧財產權歸開發者所有。應用內提供的範例模板與展示圖片可能來自第三方授權內容，僅供個人學習與非商業創作參考，請遵守相應授權條款。
                """
            ),
            LegalSection(
                title: "合理使用",
                body: """
                您同意不得：

                • 以任何方式破壞、反編譯或干擾本應用正常運行；
                • 利用本應用從事違法活動或侵犯他人權益的行為；
                • 批量擷取、複製或傳播應用內受保護的內容用於商業用途。
                """
            ),
            LegalSection(
                title: "免責聲明",
                body: """
                本應用按「現狀」提供。在法律允許的最大範圍內，我們不對因使用或無法使用本應用而產生的間接、附帶或特殊損害承擔責任。您應自行備份重要作品，因裝置故障、誤刪或系統原因造成的資料遺失，我們將在合理範圍內協助，但不承擔賠償責任。
                """
            ),
            LegalSection(
                title: "協議變更",
                body: "我們可能修訂本協議。更新後繼續使用本應用，即視為您接受修訂內容。重大變更將透過應用內提示或其他合理方式告知。"
            ),
            LegalSection(
                title: "聯絡我們",
                body: "如對本協議有任何疑問，請透過 App Store 應用頁面提供的開發者聯絡方式與我們取得聯繫。"
            )
        ]
    )

    // MARK: - Terms of Service (English)

    private static let termsOfServiceEn = LegalDocumentContent(
        title: "Terms of Service",
        lastUpdated: "Last updated: July 9, 2026",
        sections: [
            LegalSection(
                title: "Acceptance",
                body: "By downloading, installing, or using ArtBloom, you agree to these Terms of Service. If you do not agree, please stop using and uninstall the App."
            ),
            LegalSection(
                title: "Service Description",
                body: """
                ArtBloom is a creative drawing and image editing app offering canvas tools, style templates, and artwork management. We may update, adjust, or temporarily suspend features as we improve the product, and we strive to maintain reliable service.
                """
            ),
            LegalSection(
                title: "Your Content",
                body: """
                You retain applicable rights to content you import, draw, or save, and you must have lawful rights to use it. You are solely responsible for imported or created content and must not include illegal, infringing, harassing, or otherwise inappropriate material.

                Your artworks are stored locally by default; we do not upload your artwork to servers without your action.
                """
            ),
            LegalSection(
                title: "Intellectual Property",
                body: """
                The App, including its design, branding, and code, is owned by the developer. Sample templates and showcase images may be licensed from third parties and are provided for personal, non-commercial creative reference. Please comply with applicable license terms.
                """
            ),
            LegalSection(
                title: "Acceptable Use",
                body: """
                You agree not to:

                • Disrupt, reverse engineer, or interfere with the App;
                • Use the App for unlawful activity or to infringe others' rights;
                • Scrape, copy, or redistribute protected in-app content for commercial purposes.
                """
            ),
            LegalSection(
                title: "Disclaimer",
                body: """
                The App is provided \"as is.\" To the fullest extent permitted by law, we are not liable for indirect, incidental, or special damages arising from use or inability to use the App. Please back up important artworks; we are not liable for loss due to device failure, accidental deletion, or system issues, though we will assist where reasonable.
                """
            ),
            LegalSection(
                title: "Changes",
                body: "We may revise these Terms. Continued use after updates constitutes acceptance. Material changes will be communicated in the App or by other reasonable means."
            ),
            LegalSection(
                title: "Contact",
                body: "For questions about these Terms, contact us via the developer information on the App Store listing."
            )
        ]
    )
}
