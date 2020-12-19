//
//  AppDelegate.swift
//  StatBar Translate
//
//  Created by Kevin Manca on 19/12/20.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

	private var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusBar.system.thickness)
	private let popover = NSPopover()
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
	
	func applicationDidFinishLaunching(_ notification: Notification) {
	
		if let btn = statusItem.button {
			btn.isHidden = false
			btn.image = #imageLiteral(resourceName: "StatBarBtnImg")
			btn.image?.isTemplate = true
			btn.action = #selector(statusItemButtonActivated(sender:))
			btn.sendAction(on: [.leftMouseDown,.leftMouseUp, .rightMouseDown, .rightMouseUp])
		}
	  
		popover.contentViewController = TranslateCtrl()
	  
	  eventMonitor = EventMonitor(mask: [.leftMouseUp, .rightMouseUp]) { [unowned self] event in
		 if self.popover.isShown {
			self.showPopover(sender: event, toShow: false)
		 }
	  }
	  
		statusItem.isVisible = true
	
	  eventMonitor?.start()
	  
	  NSApplication.shared.servicesProvider = self
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

	@objc func removeCache() {
	  if let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
		 try? FileManager.default.removeItem(atPath: cacheDir)
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
		// 5 -Quit application
		m.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q"))
		
		s.menu = m
		s.button?.performClick(nil)
		s.menu = nil
	}
	
}
