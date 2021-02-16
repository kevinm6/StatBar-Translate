//
//  AppDelegate.swift
//  StatBar Translate
//
//  Created by Kevin Manca on 20/12/20.
//

import Foundation
import WebKit
import Carbon

@NSApplicationMain
class AppDelegate: NSObject,
                   NSApplicationDelegate,
                   NSMenuDelegate,
                   NSPopoverDelegate,
                   WKNavigationDelegate {


   // MARK: - App Infos
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
      p.contentViewController?.view.window?.styleMask = .hudWindow
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
   
   var eventMonitor: EventMonitor?
   
   
   // MARK: - Popover
   func showPopover(sender: AnyObject?, show: Bool) {
      if show {
         if let b = statusItem.button {
            popv.show(relativeTo: b.bounds,
                      of: b,
                      preferredEdge: NSRectEdge.minY)
         }
         
         if wkView.url == nil || wkView.url?.absoluteString == "about:blank" {
            openWebPage(site: "https://translate.google.com/")
         }
      } else {popv.performClose(sender)}
      
	}
 
   func popoverDidShow(_ notification: Notification) {eventMonitor?.start()}
   
   func popoverDidClose(_ notification: Notification) {
      eventMonitor?.stop()
      
      _ = Timer.scheduledTimer(withTimeInterval: 600,
                               repeats: false,
                               block: { (t) in
                                 t.invalidate()
                                 self.openWebPage(site: "about:blank")
                               })
   }
   
   func popoverShouldDetach(_ popover: NSPopover) -> Bool {
      popover.contentViewController?.view.window?.standardWindowButton(.closeButton)?.contentTintColor = .systemGray
      eventMonitor?.stop()
      return true
   }
   
   func detachableWindow(for popover: NSPopover) -> NSWindow? {
      if let ctrl = popover.contentViewController {
         ctrl.title = appInfo.name   // Window name

         wind? = NSWindow()
         wind?.contentViewController = ctrl
         wind?.isMovable = true
         wind?.styleMask = .titled
         wind?.tabbingMode = .disallowed
         wind?.titlebarAppearsTransparent = true
         
         return wind
      } else {return NSWindow()}
   }
   
   
	//	MARK: - OBJC FUNC
	
	@objc func statusItemButtonActivated(sender: AnyObject?) {
		let ev = NSApp.currentEvent!
      
      if popv.isShown {popv.performClose(sender)}
      if (wind != nil) {wind?.performClose(sender)}
      
		switch ev.type {
		case .leftMouseUp:
			if !popv.isShown {
				showPopover(sender: sender, show: true)
         }
			if (ev.modifierFlags == .option) || (ev.modifierFlags == .control) {buildMenu()}
         
		case .rightMouseUp: buildMenu()
			
		default: break
		}
	}
   
   /// Clean all the caches and cookies stored
   @objc func cleanCacheCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
      openWebPage(site: "about:blank")
    }
 
   
	// MARK: - Construct Menu
	func buildMenu() {
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
      m.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q"))
		
      self.statusItem.menu = m
      self.statusItem.button?.performClick(nil)
      self.statusItem.menu = nil
	}

	
   // MARK: - helper funcs
   func translateService(pboard: NSPasteboard,
                         userData: String,
                         error: AutoreleasingUnsafeMutablePointer<NSString?>) {
    NSLog("Opening StatBarTranslate")
//    showPopover(sender: NSApp.currentEvent, show: true)
    if !popv.isShown {
        popv = NSPopover()
    }
    popv.show(relativeTo: NSRect(x: 0,
                               y: 0,
                               width: 100,
                               height: 100),
    of: (NSApp.mainWindow?.contentView)!, preferredEdge: NSRectEdge.minY)
   }
   
   private func openWebPage(site: String) {
      wkView.load(URLRequest(url: URL(string: site) ?? URL(string: "about:blank")!))
   }

   
   // MARK: - App Notifications
   
   func applicationDidFinishLaunching(_ notification: Notification) {
      // status item
      statusItem.isVisible = true
      
      guard let b = statusItem.button else {fatalError("Can't get status item.")}
      b.isHidden = false
      b.image = NSImage(named: "StatBarBtnImg")
      b.image?.isTemplate = true
      b.action = #selector(statusItemButtonActivated(sender:))
      b.sendAction(on: [.leftMouseUp, .rightMouseUp])
      b.toolTip = "Drag the arrow of the window to pin.\nCmd+g to show the app."
      
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
