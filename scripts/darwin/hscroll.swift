import AppKit
import ApplicationServices
import Darwin
import Foundation

/// Watches trackpad axis-2 and tells listening Neovim instances to sidescroll.
/// Warp and Terminal.app never forward horizontal wheel events; this talks to
/// nvim over a local socket instead of trusting the TTY.

private let bypassIds: Set<String> = [
  "dev.warp.Warp-Stable",
  "dev.warp.Warp",
  "dev.warp.Warp-Preview",
  "com.apple.Terminal",
  "com.googlecode.iterm2",
]

private func homeStateRoot() -> URL {
  FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".local", isDirectory: true)
    .appendingPathComponent("state", isDirectory: true)
}

private func socketDirs() -> [URL] {
  let env = ProcessInfo.processInfo.environment
  let app = env["NVIM_APPNAME"].flatMap { $0.isEmpty ? nil : $0 } ?? "nvim"
  var roots: [URL] = [homeStateRoot()]
  if let raw = env["XDG_STATE_HOME"], !raw.isEmpty {
    roots.append(URL(fileURLWithPath: raw, isDirectory: true))
  }
  return roots.map {
    $0.appendingPathComponent(app, isDirectory: true)
      .appendingPathComponent("nvim-setup-hscroll", isDirectory: true)
  }
}

private func isSafeSocket(_ name: String) -> Bool {
  let parts = name.split(separator: ".", omittingEmptySubsequences: false)
  guard parts.count == 2, parts[1] == "sock", !parts[0].isEmpty else {
    return false
  }
  return parts[0].allSatisfy(\.isNumber)
}

private func canConnect(_ path: String) -> Bool {
  guard path.utf8.count < 104 else {
    return false
  }
  let fd = socket(AF_UNIX, SOCK_STREAM, 0)
  guard fd >= 0 else {
    return false
  }
  defer { close(fd) }
  var addr = sockaddr_un()
  addr.sun_family = sa_family_t(AF_UNIX)
  path.withCString { src in
    withUnsafeMutablePointer(to: &addr.sun_path) { dst in
      dst.withMemoryRebound(to: CChar.self, capacity: 104) { buf in
        _ = strncpy(buf, src, 103)
      }
    }
  }
  return withUnsafePointer(to: &addr) { ptr in
    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
      connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0
    }
  }
}

private var cachedSockets: [String] = []
private var cachedAt = Date.distantPast

private func liveSockets() -> [String] {
  if Date().timeIntervalSince(cachedAt) < 0.25 {
    return cachedSockets
  }
  cachedSockets = sockets()
  cachedAt = Date()
  return cachedSockets
}

private func sockets() -> [String] {
  var paths: [String] = []
  let files = FileManager.default
  for folder in socketDirs() {
    guard let names = try? files.contentsOfDirectory(atPath: folder.path) else {
      continue
    }
    for name in names where isSafeSocket(name) {
      let path = folder.appendingPathComponent(name).path
      if canConnect(path) {
        paths.append(path)
      } else {
        try? files.removeItem(atPath: path)
      }
    }
  }
  return paths
}

private func nvimLaunchPath() -> String {
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  return [
    "\(home)/.local/bin",
    "\(home)/.local/opt/nvim/bin",
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
  ].joined(separator: ":")
}

private func nvimURL() -> URL? {
  let file = FileManager.default
  for dir in nvimLaunchPath().split(separator: ":") {
    let url = URL(fileURLWithPath: String(dir), isDirectory: true)
      .appendingPathComponent("nvim")
    if file.isExecutableFile(atPath: url.path) {
      return url
    }
  }
  return nil
}

private let notifyQueue = DispatchQueue(label: "com.nvimsetup.hscroll")
private var notifyBusy = false

private func notify(dir: Int) {
  let dir = dir > 0 ? 1 : -1
  notifyQueue.async {
    if notifyBusy {
      return
    }
    notifyBusy = true
    defer { notifyBusy = false }
    guard let nvim = nvimURL() else {
      return
    }
    for sock in liveSockets() {
      let proc = Process()
      proc.executableURL = nvim
      proc.arguments = [
        "--headless", "--server", sock, "--remote-expr",
        "luaeval(\"require('modules.hscroll').scroll(\(dir))\")",
      ]
      proc.environment = ["PATH": nvimLaunchPath()]
      proc.standardOutput = FileHandle.nullDevice
      proc.standardError = FileHandle.nullDevice
      do {
        try proc.run()
      } catch {
        continue
      }
      let done = DispatchSemaphore(value: 0)
      proc.terminationHandler = { _ in done.signal() }
      if done.wait(timeout: .now() + 0.8) == .timedOut {
        proc.terminate()
      }
    }
  }
}

private func terminalNeedsBypass() -> Bool {
  guard let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
    return false
  }
  return bypassIds.contains(id)
}

private var lastFire = Date.distantPast
private var pending = 0.0

private func horizontalDelta(_ event: CGEvent) -> Double {
  let axis1 = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
  let axis2 = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
  let point1 = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
  let point2 = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
  let fixed1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
  let fixed2 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
  let horiz = point2 != 0 ? point2 : (fixed2 != 0 ? fixed2 : axis2)
  let vert = point1 != 0 ? point1 : (fixed1 != 0 ? fixed1 : axis1)
  if horiz == 0 || abs(horiz) <= abs(vert) {
    return 0
  }
  return horiz
}

private func handle(_ event: CGEvent) -> Unmanaged<CGEvent>? {
  let delta = horizontalDelta(event)
  if delta == 0 || !terminalNeedsBypass() {
    return Unmanaged.passUnretained(event)
  }
  let live = liveSockets()
  if live.isEmpty {
    return Unmanaged.passUnretained(event)
  }
  pending += delta
  let now = Date()
  if now.timeIntervalSince(lastFire) < 0.03 {
    return nil
  }
  if pending == 0 {
    return nil
  }
  lastFire = now
  notify(dir: pending > 0 ? -1 : 1)
  pending = 0
  return nil
}

let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
var tap: CFMachPort?
var source: CFRunLoopSource?

func attachTap() -> Bool {
  if tap != nil {
    return true
  }
  guard let next = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: mask,
    callback: { _, _, event, _ in handle(event) },
    userInfo: nil
  ) else {
    return false
  }
  tap = next
  source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, next, 0)
  CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
  CGEvent.tapEnable(tap: next, enable: true)
  return true
}

if !attachTap() {
  FileHandle.standardError.write(
    Data("nvim-setup-hscroll: enable Accessibility for this binary in System Settings → Privacy & Security.\n".utf8)
  )
}

Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
  _ = attachTap()
}
CFRunLoopRun()
