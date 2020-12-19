//
//  TranslateCtrl.swift
//  StatBar Translate
//
//  Created by Kevin Manca on 19/12/20.
//

import Cocoa
import WebKit

class TranslateCtrl: NSViewController {
		
	private lazy var contentView = NSView()
	var urlLoaded = false
	
	// INIT
	init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError()
	}
	// END INIT
	
	
	override func loadView() {
		let wkv = WKWebView()
		view = wkv
		if (!self.urlLoaded) {
			self.urlLoaded = true
			wkv.load(NSURLRequest(url: NSURL(string: "https://translate.google.com")! as URL) as URLRequest)
		}
		
		view.setFrameSize(NSSize(width: 600, height: 400))
	}
	
}

