import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("LaserTool launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSLog("LaserTool terminating")
    }
}
