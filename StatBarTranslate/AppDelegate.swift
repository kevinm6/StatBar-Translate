//
//  AppDelegate.swift
//  StatBar Translate
//
//  Created by Kevin Manca on 20/12/20.
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject,
                   NSApplicationDelegate,
                   NSMenuDelegate,
                   NSPopoverDelegate,
                   WKNavigationDelegate {
   
   
   // MARK: - Application Infos
   var appInfo: (name: String,
                 version: String,
                 build: String) {
      guard let n = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
            let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            else {
               return ("StatBarTranslate","#.#","######")
            }
      return (n, v, b)
   }
   
   
   // MARK: - vars
   private var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
   
   private var popv: NSPopover = {
      let p = NSPopover()
      p.behavior = .semitransient
      p.contentViewController?.view.window?.styleMask = .titled

      return p
    }()
   
   private var wkView: WKWebView = {
      let cnfg = WKWebViewConfiguration()
      let w = WKWebView(frame: NSRect(x: 0,
                                        y: 0,
                                        width: 600,
                                        height: 400),
                        configuration: cnfg)
      return w
   }()
	
   private var wind: NSWindow?
   
   private var timer: Timer?
   
   var eventMonitor: EventMonitor?
   
   
   // MARK: - Popover
   @objc func showPopover(sender: AnyObject?, show: Bool) {
      if show {
         if let button = statusItem.button {
            popv.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
         }
         
         timer?.invalidate()
         if wkView.url == nil || wkView.url?.absoluteString == "about:blank" {
            openWebPage(site: "https://translate.google.com")
         }
      } else {
         popv.performClose(sender)
      }
      
	}
 
   func popoverDidShow(_ notification: Notification) {eventMonitor?.start()}
   
   func popoverDidClose(_ notification: Notification) {
      eventMonitor?.stop()
      startTimer()
   }
   
   func popoverShouldDetach(_ popover: NSPopover) -> Bool {
      popover.contentViewController?.view.window?.standardWindowButton(.closeButton)?.contentTintColor = .systemGray
      eventMonitor?.stop()
      return true
   }
   
   func detachableWindow(for popover: NSPopover) -> NSWindow? {
      if let ctrl = popover.contentViewController {
         ctrl.title = ("appInfo.name")   // Window name
         
         wind? = NSWindow()
         wind?.contentViewController = ctrl
         wind?.isMovable = true
         wind?.styleMask = .titled
         wind?.tabbingMode = .disallowed
         wind?.titlebarAppearsTransparent = true
         
         return wind
      } else {return NSWindow()}
   }
   
   @objc func closePopover(_ sender:Any?) {popv.performClose(sender)}
   
   
   // MARK: - Timer
   func startTimer() {
      self.timer = Timer.scheduledTimer(timeInterval: 600,
                                        target: self,
                                        selector: #selector(fireTimer),
                                        userInfo: nil,
                                        repeats: false)
   }
   
   @objc func fireTimer() {
      timer?.invalidate()
      openWebPage(site: "about:blank")
   }
	
   
	//	MARK: - OBJC FUNC
	
	@objc func statusItemButtonActivated(sender: AnyObject?) {
		let ev = NSApp.currentEvent!
      
      if popv.isShown {closePopover(sender)}
      if (wind != nil) {wind?.performClose(sender)}
      
		switch ev.type {
		case .leftMouseUp:
			if !popv.isShown {
				showPopover(sender: sender, show: true)
         }
			if (ev.modifierFlags == .option) || (ev.modifierFlags == .control) {buildContextMenu()}
         
		case .rightMouseUp: buildContextMenu()
			
		default: break
		}
	}

	@objc func quitApp(_ sender: Any) {NSApplication.shared.terminate(self)}
   
   // cleaning func
   @objc func cleanCacheCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
      openWebPage(site: "about:blank")
    }
   
   
	// MARK: - construct menu
	func buildContextMenu() {
		let s = self.statusItem
		let m = NSMenu()
		// 0, 1 -App Info
      m.addItem(withTitle: appInfo.name, action: nil, keyEquivalent: "")
      m.addItem(withTitle: "Version \(appInfo.version), Build (\(appInfo.build))" , action: nil, keyEquivalent: "")
		// 2
		m.addItem(NSMenuItem.separator())
      // 3
      m.addItem(NSMenuItem(title: "Remove cache & cookies", action: #selector(cleanCacheCookies), keyEquivalent: ""))
      // 4
      m.addItem(NSMenuItem.separator())
		// 5 -Quit application
		m.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q"))
		
		s.menu = m
		s.button?.performClick(nil)
		s.menu = nil
	}

	
   // MARK: - helper funcs
   func translateService(pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
      popv.show(relativeTo: NSRect.init(x: 0,
                                        y: 0,
                                        width: 100,
                                        height: 100),
                of: (NSApp.mainWindow?.contentView)!, preferredEdge: NSRectEdge.minY)
   }
   
   private func openWebPage(site: String) {
      wkView.load(URLRequest(url: URL(string: site) ?? URL(string: "about:blank")!))
   }
   
   func infoPlistValue(forKey key: String) -> String {
      guard let v = Bundle.main.object(forInfoDictionaryKey: key) as? String else {return "#"}
      return v
}
   
   // MARK: - App Notifications
   
   func applicationDidFinishLaunching(_ notification: Notification) {
      // status item
      if let b = statusItem.button {
         b.isHidden = false
         b.image = NSImage(named: "StatBarBtnImg")
         b.image?.isTemplate = true
         b.action = #selector(statusItemButtonActivated(sender:))
         b.sendAction(on: [.leftMouseUp, .rightMouseUp])
         b.toolTip = "Drag the arrow of the window to pin"
      }
      statusItem.isVisible = true
      
      // wkview
      wkView.navigationDelegate = self
      
      let ctrl = NSViewController()
      
      ctrl.view = wkView
      // popover
      popv.delegate = self
      popv.behavior = .transient
      popv.animates = false
      popv.contentViewController = ctrl
      
      // event monitor
      eventMonitor = EventMonitor(mask: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
         if let strongSelf = self, strongSelf.popv.isShown {
            strongSelf.showPopover(sender: event, show: false)
         }
      }
      NSApplication.shared.servicesProvider = self
   }

   
} // END App Delegate


// MARK:- EventMonitor
public class EventMonitor {
   private var monitor: AnyObject?
   private let mask: NSEvent.EventTypeMask
   private let handler: (NSEvent?) -> ()

   public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> ()) {
      self.mask = mask
      self.handler = handler
   }

   deinit {
      self.stop()
   }

   public func start() {
      self.monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) as AnyObject?
   }

   public func stop() {
      if self.monitor != nil {
         NSEvent.removeMonitor(self.monitor!)
         self.monitor = nil
      }
   }
}



