// Radar de sensores — native macOS shell around the catalog web UI.
// Build: swiftc -O main.swift -o RadarSensores -framework Cocoa -framework WebKit
import Cocoa
import WebKit

let fm = FileManager.default
let dataDir = fm.homeDirectoryForCurrentUser
    .appendingPathComponent("Applications/RadarSensores-datos", isDirectory: true)

// MARK: - Data files

func readJSON(_ url: URL) -> Any? {
    guard let d = try? Data(contentsOf: url) else { return nil }
    return try? JSONSerialization.jsonObject(with: d)
}

func readData(_ name: String) -> Any? { readJSON(dataDir.appendingPathComponent(name)) }

func writeData(_ name: String, _ obj: Any) {
    guard JSONSerialization.isValidJSONObject(obj),
          let d = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]) else { return }
    try? d.write(to: dataDir.appendingPathComponent(name), options: .atomic)
}

func stamp(_ cat: Any?) -> (String, Int) {
    let c = cat as? [String: Any]
    return (c?["actualizado"] as? String ?? "", c?["version"] as? Int ?? 0)
}

/// Returns the newest catalog, seeding or refreshing the data folder from the bundled copy when needed.
func loadCatalog() -> Any {
    try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
    let bundledURL = Bundle.main.url(forResource: "catalogo", withExtension: "json")
    let bundled = bundledURL.flatMap { readJSON($0) }
    let local = readData("catalogo.json")
    if let b = bundled, local == nil || stamp(b) > stamp(local) {
        writeData("catalogo.json", b)
        return b
    }
    if let l = local { return l }
    return bundled ?? ["sensores": [], "propios": [:], "fuentes": []]
}

func seedReadme() {
    for (name, ext) in [("LEEME", "md"), ("validar", "py")] {
        let dest = dataDir.appendingPathComponent("\(name).\(ext)")
        if let src = Bundle.main.url(forResource: name, withExtension: ext) {
            try? fm.removeItem(at: dest)
            try? fm.copyItem(at: src, to: dest)
        }
    }
}

func jsonString(_ obj: Any) -> String {
    guard let d = try? JSONSerialization.data(withJSONObject: obj), let s = String(data: d, encoding: .utf8) else { return "null" }
    return s
        .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
        .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        .replacingOccurrences(of: "</script", with: "<\\/script", options: .caseInsensitive)
}

// MARK: - Feed reading (RSS 2.0 and Atom)

final class FeedParser: NSObject, XMLParserDelegate {
    var items: [[String: String]] = []
    private var cur: [String: String]?
    private var text = ""
    private var depth = 0

    func parse(_ data: Data) -> [[String: String]] {
        let p = XMLParser(data: data)
        p.delegate = self
        p.shouldProcessNamespaces = false
        p.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName q: String?, attributes: [String: String] = [:]) {
        let el = name.lowercased()
        if cur == nil {
            if el == "item" || el == "entry" {
                cur = [:]
                depth = 0
                text = ""
            }
            return
        }
        depth += 1
        guard depth == 1 else { return }
        if el == "link", let href = attributes["href"] {
            let rel = attributes["rel"] ?? "alternate"
            if rel == "alternate" && cur?["l"] == nil { cur?["l"] = href }
        }
        text = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if cur != nil && depth >= 1 { text += string }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if cur != nil && depth >= 1, let s = String(data: CDATABlock, encoding: .utf8) { text += s }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName q: String?) {
        let el = name.lowercased()
        guard cur != nil else { return }
        if depth == 0 && (el == "item" || el == "entry") {
            if let c = cur, c["t"] != nil, c["l"] != nil { items.append(c) }
            cur = nil
            text = ""
            return
        }
        if depth == 1 {
            let v = text.trimmingCharacters(in: .whitespacesAndNewlines)
            switch el {
            case "title": if cur?["t"] == nil, !v.isEmpty { cur?["t"] = v }
            case "link": if cur?["l"] == nil, !v.isEmpty { cur?["l"] = v }
            case "pubdate", "published", "dc:date", "updated": if cur?["d"] == nil, !v.isEmpty { cur?["d"] = v }
            case "description", "summary", "content", "content:encoded":
                if cur?["s"] == nil, !v.isEmpty { cur?["s"] = String(v.prefix(2500)) }
            default: break
            }
            text = ""
        }
        if depth > 0 { depth -= 1 }
    }
}

func fetchFeeds(_ feeds: [[String: Any]], done: @escaping ([[String: Any]]) -> Void) {
    let cfg = URLSessionConfiguration.ephemeral
    cfg.timeoutIntervalForRequest = 20
    cfg.timeoutIntervalForResource = 30
    cfg.httpAdditionalHeaders = ["User-Agent": "RadarSensores/1.0 (macOS; lector de RSS personal)"]
    let session = URLSession(configuration: cfg)
    let group = DispatchGroup()
    let lock = NSLock()
    var results = [[String: Any]](repeating: [:], count: feeds.count)
    for (i, f) in feeds.enumerated() {
        let name = f["n"] as? String ?? "Fuente"
        guard let s = f["u"] as? String, let url = URL(string: s), url.scheme == "https" else {
            results[i] = ["n": name, "ok": false, "error": "Dirección no válida", "items": []]
            continue
        }
        group.enter()
        session.dataTask(with: url) { data, resp, err in
            var r: [String: Any] = ["n": name, "u": s, "tema": f["tema"] as? String ?? "general"]
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if let data = data, (200..<300).contains(code) {
                let items = FeedParser().parse(data)
                r["ok"] = true
                r["items"] = Array(items.prefix(60))
            } else {
                r["ok"] = false
                r["error"] = err?.localizedDescription ?? "Respuesta HTTP \(code)"
                r["items"] = []
            }
            lock.lock(); results[i] = r; lock.unlock()
            group.leave()
        }.resume()
    }
    group.notify(queue: .main) { done(results) }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    var window: NSWindow!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenu()
        let catalog = loadCatalog()
        seedReadme()
        let boot: [String: Any] = [
            "catalogo": catalog,
            "radar": readData("radar.json") ?? [],
            "novedades": readData("novedades.json") ?? [],
            "meta": readData("meta.json") ?? [:],
            "carpeta": dataDir.path
        ]

        let ucc = WKUserContentController()
        ucc.add(self, name: "radar")
        ucc.addUserScript(WKUserScript(source: "window.__RADAR__ = \(jsonString(boot));",
                                       injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let cfg = WKWebViewConfiguration()
        cfg.userContentController = ucc

        web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsMagnification = true

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1320, height: 900),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Radar de sensores"
        window.minSize = NSSize(width: 460, height: 520)
        window.contentView = web
        window.center()
        window.setFrameAutosaveName("RadarSensoresWindow")
        window.makeKeyAndOrderFront(nil)

        if let index = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // JS -> Swift
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let cmd = body["cmd"] as? String else { return }
        switch cmd {
        case "actualizar":
            let feeds = body["fuentes"] as? [[String: Any]] ?? []
            fetchFeeds(feeds) { [weak self] results in
                let payload: [String: Any] = ["catalogo": loadCatalog(), "fuentes": results]
                self?.web.evaluateJavaScript("window.radarRecibir(\(jsonString(payload)))", completionHandler: nil)
            }
        case "guardar":
            if let name = body["nombre"] as? String, ["radar", "novedades", "meta"].contains(name), let data = body["datos"] {
                writeData(name + ".json", data)
            }
        case "abrir":
            if let s = body["url"] as? String, let u = URL(string: s), ["http", "https"].contains(u.scheme ?? "") {
                NSWorkspace.shared.open(u)
            }
        case "copiar":
            if let t = body["texto"] as? String {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(t, forType: .string)
            }
        case "carpeta":
            NSWorkspace.shared.open(dataDir)
        default: break
        }
    }

    // External links open in the default browser.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let u = action.request.url, ["http", "https"].contains(u.scheme ?? "") {
            NSWorkspace.shared.open(u)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let u = action.request.url { NSWorkspace.shared.open(u) }
        return nil
    }

    @objc func runUpdate() { web.evaluateJavaScript("window.radarActualizar && window.radarActualizar()", completionHandler: nil) }
    @objc func openFolder() { NSWorkspace.shared.open(dataDir) }
    @objc func focusSearch() { web.evaluateJavaScript("document.getElementById('q').focus()", completionHandler: nil) }
    @objc func toggleTheme() { web.evaluateJavaScript("window.radarTema && window.radarTema()", completionHandler: nil) }

    func buildMenu() {
        let main = NSMenu()
        func add(_ title: String, _ build: (NSMenu) -> Void) {
            let item = NSMenuItem(); let m = NSMenu(title: title); build(m); item.submenu = m; main.addItem(item)
        }
        add("Radar de sensores") { m in
            m.addItem(withTitle: "Acerca de Radar de sensores", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
            m.addItem(.separator())
            m.addItem(withTitle: "Ocultar", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
            m.addItem(.separator())
            m.addItem(withTitle: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        }
        add("Edición") { m in
            m.addItem(withTitle: "Deshacer", action: Selector(("undo:")), keyEquivalent: "z")
            m.addItem(withTitle: "Rehacer", action: Selector(("redo:")), keyEquivalent: "Z")
            m.addItem(.separator())
            m.addItem(withTitle: "Cortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
            m.addItem(withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
            m.addItem(withTitle: "Pegar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
            m.addItem(withTitle: "Seleccionar todo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        }
        add("Radar") { m in
            let u = m.addItem(withTitle: "Actualizar", action: #selector(runUpdate), keyEquivalent: "r"); u.target = self
            let f = m.addItem(withTitle: "Buscar", action: #selector(focusSearch), keyEquivalent: "f"); f.target = self
            let t = m.addItem(withTitle: "Cambiar tema", action: #selector(toggleTheme), keyEquivalent: "t"); t.target = self
            m.addItem(.separator())
            let o = m.addItem(withTitle: "Abrir carpeta de datos", action: #selector(openFolder), keyEquivalent: "d"); o.target = self
        }
        add("Ventana") { m in
            m.addItem(withTitle: "Minimizar", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
            m.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        }
        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
