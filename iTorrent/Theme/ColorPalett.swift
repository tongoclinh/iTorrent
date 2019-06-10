//
//  ColorPalett.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class Themes {
    public static let updateNotification = NSNotification.Name("ThemeUpdated")
	
	static let shared = Themes()
	
	var theme : [ColorPalett] = []
	
	private init() {
		let darkTheme = ColorPalett()
		
		darkTheme.mainText = UIColor.white
		darkTheme.secondaryText = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
		darkTheme.tertiaryText = UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1)
		darkTheme.selectedText = UIColor(red: 255/255, green: 255/255, blue: 120/255, alpha: 1)
		darkTheme.backgroundMain = UIColor.black
		darkTheme.backgroundSecondary = UIColor(red: 55/255, green: 55/255, blue: 55/255, alpha: 1)
		darkTheme.backgroundTertiary = UIColor(red: 55/255, green: 55/255, blue: 55/255, alpha: 1)
		darkTheme.tableHeaderColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.9)
		darkTheme.actionCancelButtonColor = UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        darkTheme.progressBarBackground = UIColor(red: 0.24, green: 0.24, blue: 0.25, alpha: 1)
		darkTheme.actionButtonColor = .orange
		darkTheme.statusBarStyle = .lightContent
		darkTheme.barStyle = .blackTranslucent
		darkTheme.blurEffect = .dark
		darkTheme.keyboardAppearence = .dark
		darkTheme.loadingIndicatorStyle = .white
        
        if #available(iOS 12.0, *) {
            darkTheme.overrideUserInterfaceStyle = UIUserInterfaceStyle.dark.rawValue
        }
		
		theme.append(ColorPalett())
		theme.append(darkTheme)
	}
	
	static func current() -> ColorPalett {
		return shared.theme[UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)]
	}
	
}

class ColorPalett {
	var mainText = UIColor.black
	var secondaryText = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
	var tertiaryText = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1)
	var selectedText = UIColor(red: 0/255, green: 0/255, blue: 135/255, alpha: 1)
	var backgroundMain = UIColor.white
	var backgroundSecondary = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
	var backgroundTertiary = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
	var tableHeaderColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.9)
	var actionCancelButtonColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    var progressBarBackground = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1)
	var actionButtonColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
	var statusBarStyle : UIStatusBarStyle = .default
	var barStyle : UIBarStyle = .default
	var blurEffect : UIBlurEffectStyle = .extraLight
	var keyboardAppearence : UIKeyboardAppearance = .default
	var loadingIndicatorStyle : UIActivityIndicatorViewStyle = .gray
    var overrideUserInterfaceStyle : Int!
    
    init() {
        if #available(iOS 12.0, *) {
            overrideUserInterfaceStyle = UIUserInterfaceStyle.light.rawValue
        }
    }
}
