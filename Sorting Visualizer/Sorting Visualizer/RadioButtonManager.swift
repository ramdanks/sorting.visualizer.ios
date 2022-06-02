//
//  RadioButtonManager.swift
//  Sorting Visualizer
//
//  Created by Ramadhan Kalih Sewu on 02/06/22.
//

import Foundation
import UIKit

class RadioButtonManager
{
    public let selectedBorderColor: CGColor = UIColor.tintColor.cgColor
    public let selectedBorderWidth: CGFloat = 2
    
    public var views: Array<ViewSetting>
    
    public var selectedIndex: Int { didSet {
        for (i, setting) in views.enumerated()
        {
            let selected = i == selectedIndex
            setting.view.layer.borderColor = selected ? selectedBorderColor : setting.borderColor
            setting.view.layer.borderWidth = selected ? selectedBorderWidth : setting.borderWidth
        }
    }}
    
    struct ViewSetting
    {
        var view: UIControl
        var borderColor: CGColor?
        var borderWidth: CGFloat
    }
    
    public init(_ views: Array<UIControl>)
    {
        self.views = views.map { return ViewSetting(view: $0, borderColor: $0.layer.borderColor, borderWidth: $0.layer.borderWidth) }
        self.selectedIndex = 0
        ({ selectedIndex = selectedIndex })()
    }
}
