//
//  AppDelegate.swift
//  StatBar Translate
//
//  Created by Kevin Manca on 19/12/20.
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate, WKNavigationDelegate {

   private var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
	private let popover = NSPopover()
   var wkView: WKWebView?
	var eventMonitor: EventMonitor?
   
	
	var appInfo: (name: String, version: String, build: String) {
		if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
			let ver = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
			let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
			return (name, ver, build)
		} else {
			return ("StatBar Translate", "#.#", "#.#")
		}
	}
	
   
	func showPopover(sender: AnyObject?, toShow: Bool) {
		if toShow {
			if let button = statusItem.button {
				popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
         }
			eventMonitor?.start()
		} else {
			popover.performClose(sender)
			eventMonitor?.stop()
		}
		
	}
	
	func translateService(pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {

		NSLog("Opening StatBar Translate. . .")
		
		popover.show(relativeTo: NSRect.init(x: 0, y: 0, width: 100, height: 100), of: (NSApp.mainWindow?.contentView)!, preferredEdge: NSRectEdge.minY)
	}
	
	
	//	MARK: - OBJC FUNC
	
	@objc func statusItemButtonActivated(sender: AnyObject?) {
		let ev = NSApp.currentEvent!
		
		switch ev.type {
		case .leftMouseUp:
			if popover.isShown {
				showPopover(sender: sender,
								toShow: false)
			} else {
				showPopover(sender: sender,
									  toShow: true)
			}
			if (ev.modifierFlags == .option) || (ev.modifierFlags == .control) {
				menuConfig()
			}
		case .rightMouseUp:
			menuConfig()
			
		default: showPopover(sender: sender,
									toShow: false)
		}
	}


	@objc func quitApp(_ sender: Any) {
			NSApplication.shared.terminate(self)
	}

   // MARK: - cleaning funcs
   
	@objc func removeCache() {
     if let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
      try? FileManager.default.removeItem(atPath: cacheDir)
     }
   }
    
   @objc func removeCookies() {
     if let w = self.wkView {
         w.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
             for cookie in cookies {
                 if cookie.name == "authentication" {
                     w.configuration.websiteDataStore.httpCookieStore.delete(cookie)
                 }
             }
         }
     }
   }
    

	// MARK: - menuConfig
	func menuConfig() {
		let s = self.statusItem
		let m = NSMenu()
		// 0, 1 -App Info
		m.addItem(withTitle: appInfo.name, action: nil, keyEquivalent: "")
		m.addItem(withTitle: "Version \(appInfo.version), Build (\(appInfo.build))" , action: nil, keyEquivalent: "")
		// 2
		m.addItem(NSMenuItem.separator())
		// 3
		m.addItem(NSMenuItem(title: "Remove cache", action: #selector(removeCache), keyEquivalent: ""))
		// 4
        m.addItem(NSMenuItem.separator())
        // 5
        m.addItem(NSMenuItem(title: "Remove cookie", action: #selector(self.removeCookies), keyEquivalent: ""))
        // 6
        m.addItem(NSMenuItem.separator())
		// 7 -Quit application
		m.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q"))
		
		s.menu = m
		s.button?.performClick(nil)
		s.menu = nil
	}

	
   
   // MARK: - App Notifications
   
   func applicationDidFinishLaunching(_ notification: Notification) {
   
      // status item
      if let btn = statusItem.button {
         btn.isHidden = false
         btn.image = #imageLiteral(resourceName: "StatBarBtnImg")
         btn.image?.isTemplate = true
         btn.action = #selector(statusItemButtonActivated(sender:))
         btn.sendAction(on: [.leftMouseDown,.leftMouseUp, .rightMouseDown, .rightMouseUp])
      }
      statusItem.isVisible = true
      
      // wkview
      wkView = WKWebView(frame: NSRect(x: 0,
                                        y: 0,
                                        width: 600,
                                        height: 400))
      if let w = self.wkView {
         w.navigationDelegate = self
         if let url = URL(string: "https://translate.google.com") {
            let req = URLRequest(url: url)
            w.load(req)
         }
         
         let ctrl = NSViewController()
         ctrl.view = w
         popover.contentViewController = ctrl
      }
      
      // popover
      popover.delegate = self
      popover.behavior = .transient
     
      // event monitor
      eventMonitor = EventMonitor(mask: [.leftMouseUp, .rightMouseUp]) { [unowned self] event in
         if self.popover.isShown {
         self.showPopover(sender: event, toShow: false)
       }
      }
   
      eventMonitor?.start()
     
      NSApplication.shared.servicesProvider = self
   
   }

   
} // END CLASS


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
