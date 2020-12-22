//
//  AppDelegate.swift
//  StatBar Translate
//
//  Created by Kevin Manca on 19/12/20.
//

import Foundation
import Cocoa
import WebKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate, WKNavigationDelegate {
   
   // MARK: - vars
   private var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
	private let popover = NSPopover()
   private var wkView: WKWebView?
	var eventMonitor: EventMonitor?
   private var timer: Timer?
   
   
   // MARK: - Application Infos
	var appInfo: (name: String, version: String, build: String) {
      let bndl = Bundle.main
		if let name = bndl.object(forInfoDictionaryKey: "CFBundleName") as? String,
			let ver = bndl.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
			let build = bndl.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
			return (name, ver, build)
		} else {
			return ("StatBar Translate", "#.#", "#.#")
		}
	}
	
   
   // MARK: - Popover
   func showPopover(sender: AnyObject?, show: Bool) {
      if show {
         if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
         }
         
         timer?.invalidate()
         if wkView?.url == nil || wkView?.url?.absoluteString == "about:blank" {
            if let url = URL(string: "https://translate.google.com") {
               let req = URLRequest(url: url)
               wkView?.load(req)
            }
         }
         eventMonitor?.start()
      } else {
         popover.performClose(sender)
         eventMonitor?.stop()
         startTimer()
      }
      
	}
 
   
   // MARK: - Timer
   func startTimer() {
      self.timer = Timer.scheduledTimer(timeInterval: 600,target: self,
                                   selector: #selector(fireTimer),
                                   userInfo: nil, repeats: false)
   }
   
   @objc func fireTimer() {
      timer?.invalidate()
      if let url = URL(string: "about:blank"){
      let req = URLRequest(url: url)
         wkView?.load(req)
      }
   }
	
	//	MARK: - OBJC FUNC
	
	@objc func statusItemButtonActivated(sender: AnyObject?) {
		let ev = NSApp.currentEvent!
		
      if popover.isShown {
         showPopover(sender: sender, show: false)
         startTimer()
         eventMonitor?.stop()
      }
      
		switch ev.type {
		case .leftMouseUp:
			if !popover.isShown {
				showPopover(sender: sender, show: true)
         }
			if (ev.modifierFlags == .option) || (ev.modifierFlags == .control) {
            eventMonitor?.stop()
            menuConfig()
            startTimer()
			}
		case .rightMouseUp:
         eventMonitor?.stop()
			menuConfig()
			
		default: break
		}
	}

	@objc func quitApp(_ sender: Any) {
			NSApplication.shared.terminate(self)
	}

   
   // cleaning func
   @objc func clean() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
   
   
	// MARK: - construct menu
	func menuConfig() {
		let s = self.statusItem
		let m = NSMenu()
		// 0, 1 -App Info
		m.addItem(withTitle: appInfo.name, action: nil, keyEquivalent: "")
		m.addItem(withTitle: "Version \(appInfo.version), Build (\(appInfo.build))" , action: nil, keyEquivalent: "")
		// 2
		m.addItem(NSMenuItem.separator())
      // 5
      m.addItem(NSMenuItem(title: "Remove cache & cookies", action: #selector(clean), keyEquivalent: ""))
      // 6
      m.addItem(NSMenuItem.separator())
		// 7 -Quit application
		m.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q"))
		
		s.menu = m
		s.button?.performClick(nil)
		s.menu = nil
	}

	
   // MARK: - helper
   func translateService(pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
      popover.show(relativeTo: NSRect.init(x: 0, y: 0, width: 100, height: 100), of: (NSApp.mainWindow?.contentView)!, preferredEdge: NSRectEdge.minY)
   }
   
   
   // MARK: - App Notifications
   
   func applicationDidFinishLaunching(_ notification: Notification) {
   
      // status item
      if let btn = statusItem.button {
         btn.isHidden = false
         btn.image = #imageLiteral(resourceName: "StatBarBtnImg")
         btn.image?.isTemplate = true
         btn.action = #selector(statusItemButtonActivated(sender:))
         btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
      }
      statusItem.isVisible = true
      
      // wkview
      wkView = WKWebView(frame: NSRect(x: 0,
                                        y: 0,
                                        width: 600,
                                        height: 400))
      if let w = self.wkView {
         w.navigationDelegate = self
         
         let ctrl = NSViewController()
         ctrl.view = w
         popover.contentViewController = ctrl
      }
      
      // popover
      popover.delegate = self
      popover.behavior = .transient
     
      // event monitor
      eventMonitor = EventMonitor(mask: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
         if let strongSelf = self, strongSelf.popover.isShown {
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

