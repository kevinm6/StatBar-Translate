//
//  EventMonitor.swift
//  StatBar Translate
//
//  Created by Kevin Manca on 19/12/20.
//

import Cocoa

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
