import Foundation
import WebKit

/// 对齐 H5 归档 `index.html` + `runtimeConfigLoader.ts` 的 WebView 启动注入。
enum ArtBloomBSidePeachGenBootstrap {
    private static let runtimeConfigStorageKey = "peachgen_runtime_config_cache"

    static func install(on contentController: WKUserContentController, cfgURL: String) {
        guard let script = makeUserScript(cfgURL: cfgURL) else { return }
        contentController.addUserScript(script)
    }

    static func makeUserScript(cfgURL: String) -> WKUserScript? {
        guard isHTTPSURL(cfgURL) else { return nil }
        let escapedCfg = jsStringLiteral(cfgURL)
        let source = """
        (function () {
          var STORAGE_KEY = '\(runtimeConfigStorageKey)';
          var cfg = \(escapedCfg);

          function readCfgFromLocation() {
            try {
              var params = new URLSearchParams(window.location.search || "");
              var value = (params.get("cfg") || "").trim();
              if (value.indexOf("https://") === 0) return value;
              var hash = window.location.hash || "";
              var queryIndex = hash.indexOf("?");
              if (queryIndex < 0) return "";
              var hashParams = new URLSearchParams(hash.slice(queryIndex));
              value = (hashParams.get("cfg") || "").trim();
              return value.indexOf("https://") === 0 ? value : "";
            } catch (e) {
              return "";
            }
          }

          function ensureCfgQueryParam() {
            try {
              var current = readCfgFromLocation();
              var resolved = current || cfg;
              if (!resolved || resolved.indexOf("https://") !== 0) return resolved;
              var url = new URL(window.location.href);
              url.searchParams.set("cfg", resolved);
              window.history.replaceState(null, "", url.toString());
              return resolved;
            } catch (e) {
              return cfg;
            }
          }

          function invalidateStaleRuntimeConfigCache(resolvedCfgURL) {
            try {
              var parsed = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null");
              if (!parsed || !parsed.cfgURL || parsed.cfgURL === resolvedCfgURL) return;
              localStorage.removeItem(STORAGE_KEY);
            } catch (e) {}
          }

          function saveRuntimeConfigCache(resolvedCfgURL, config) {
            try {
              localStorage.setItem(STORAGE_KEY, JSON.stringify({
                cfgURL: resolvedCfgURL,
                config: config,
                savedAt: Date.now()
              }));
            } catch (e) {}
          }

          function prefetchRuntimeConfig(resolvedCfgURL) {
            if (!resolvedCfgURL) return;
            window.__peachgenRuntimeConfigPromise = fetch(resolvedCfgURL, {
              method: "GET",
              credentials: "omit",
              cache: "no-store",
              headers: { Accept: "application/json" }
            })
              .then(function (response) {
                if (!response.ok) throw new Error("HTTP " + response.status);
                return response.json();
              })
              .then(function (config) {
                if (!config || typeof config !== "object" || Array.isArray(config)) {
                  throw new Error("Invalid config JSON");
                }
                saveRuntimeConfigCache(resolvedCfgURL, config);
                return config;
              })
              .catch(function () {
                return null;
              });
          }

          var resolvedCfgURL = ensureCfgQueryParam();
          invalidateStaleRuntimeConfigCache(resolvedCfgURL);
          prefetchRuntimeConfig(resolvedCfgURL);
          window.__ARTBLOOM_RUNTIME_CFG_URL__ = resolvedCfgURL;
        })();
        """
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }

    private static func isHTTPSURL(_ value: String) -> Bool {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return url.scheme?.lowercased() == "https"
    }

    private static func jsStringLiteral(_ value: String) -> String {
        var escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return "'\(escaped)'"
    }
}
