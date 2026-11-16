import Foundation

/// The P3 pages (hubs/product/plan/M2_REAL_SITES_WORK.md, R19-R26b). Each page sets its title to what
/// happened, so the readback reads the page through the window title:
///   /dialogs     #alert, #confirm, #prompt: "alert: closed", "confirm: true", "prompt: <text>"
///   /upload      #pick opens the file input's panel: "file: <name>", "file: cancel"
///   /auth        HTTP Basic: 401 until the user `user` gives `password`, then "auth test: signed in"
///   /mailto      #mail, a `mailto:` link
///   /media       #mic, #camera ask for the microphone, the camera: "media: granted", "media: <error name>";
///                "media: asking (hidden)" while it waits in a page WebKit counts as hidden
///   /fullscreen  #full: "fullscreen: on", then the page leaves fullscreen by itself: "fullscreen: off";
///                refused: "fullscreen: <WebKit's message>"
enum BasicPages {
    static let user = "nhetrinh"
    static let password = "readback-pass"  // a test page's password, not a secret
    static let dialogsTitle = "dialog test"
    static let uploadTitle = "upload test"
    static let signedInTitle = "auth test: signed in"
    static let mailtoTitle = "mailto test"
    static let mailto = "mailto:nobody@example.invalid"
    static let mediaTitle = "media test"
    static let fullscreenTitle = "fullscreen test"

    /// Big targets, so a click at an element's centre lands on it.
    private static let style = "<style>button,label,a{display:block;width:300px;height:60px;margin:12px}</style>"

    static func reply(path: String, authorization: String?) -> TestPageContent.Reply? {
        switch path {
        case "/dialogs": return page(dialogsTitle, dialogs)
        case "/upload": return page(uploadTitle, upload)
        case "/auth": return signIn(authorization)
        case "/mailto": return page(mailtoTitle, "<a id=\"mail\" href=\"\(mailto)\">write a mail</a>")
        case "/media": return page(mediaTitle, media)
        case "/fullscreen": return page(fullscreenTitle, fullscreen)
        default: return nil
        }
    }

    private static func page(_ title: String, _ body: String) -> TestPageContent.Reply {
        TestPageContent.html("<title>\(title)</title>\(style)\(body)")
    }

    static func signIn(_ authorization: String?) -> TestPageContent.Reply {
        let right = "Basic " + Data("\(user):\(password)".utf8).base64EncodedString()
        if authorization == right { return page(signedInTitle, "<p>signed in</p>") }
        var reply = page("auth test: refused", "<p>refused</p>")
        reply.status = "401 Unauthorized"
        reply.headers = ["WWW-Authenticate: Basic realm=\"nhetrinh test\""]
        return reply
    }

    private static let dialogs = """
        <button id="alert" onclick="alert('nhetrinh alert test'); document.title = 'alert: closed'">alert</button>
        <button id="confirm" onclick="document.title = 'confirm: ' + confirm('nhetrinh confirm test')">confirm</button>
        <button id="prompt" onclick="document.title = 'prompt: ' + prompt('nhetrinh prompt test', '')">prompt</button>
        """

    private static let upload = """
        <label id="pick" for="file">choose a file</label><input type="file" id="file">
        <script>
        file.onchange = () => { document.title = 'file: ' + (file.files[0] ? file.files[0].name : 'none') }
        file.addEventListener('cancel', () => { document.title = 'file: cancel' })
        </script>
        """

    private static let media = """
        <button id="mic">microphone</button><button id="camera">camera</button>
        <script>
        function ask(what) {
          document.title = 'media: asking' + (document.hidden ? ' (hidden)' : '')
          try {
            navigator.mediaDevices.getUserMedia(what)
              .then(s => { s.getTracks().forEach(t => t.stop()); document.title = 'media: granted' })
              .catch(e => { document.title = 'media: ' + e.name })
          } catch (e) { document.title = 'media: unavailable' }
        }
        mic.onclick = () => ask({audio: true})
        camera.onclick = () => ask({video: true})
        </script>
        """

    private static let fullscreen = """
        <video id="v" style="width:320px;height:180px;background:#000"></video><button id="full">fullscreen</button>
        <script>
        full.onclick = () => {
          const p = (v.requestFullscreen || v.webkitRequestFullscreen).call(v)
          if (p) p.catch(e => { document.title = 'fullscreen: ' + e.message })
        }
        const shown = () => document.fullscreenElement || document.webkitFullscreenElement
        const leave = () => (document.exitFullscreen || document.webkitExitFullscreen).call(document)
        const change = 'onfullscreenchange' in document ? 'fullscreenchange' : 'webkitfullscreenchange'
        document.addEventListener(change, () => {
          if (shown()) { document.title = 'fullscreen: on'; setTimeout(leave, 1500) }
          else if (document.title == 'fullscreen: on') document.title = 'fullscreen: off'
        })
        </script>
        """
}
