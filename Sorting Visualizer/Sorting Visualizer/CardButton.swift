//
//  CardButton.swift
//  Sorting Visualizer
//
//  Created by Ramadhan Kalih Sewu on 02/06/22.
//

import Foundation
import UIKit

@IBDesignable
class CardButton: UIControl
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBInspectable var image: UIImage! { didSet {
        imageView.image = image
    }}
    
    @IBInspectable var title: String! { didSet {
        titleLabel.text = title
    }}
    
    public override var isEnabled: Bool { didSet {
        imageView.tintColor = isEnabled ? .tintColor : .gray
        titleLabel.textColor = isEnabled ? .label : .gray
    }}
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        loadNib()
    }
    
    @discardableResult func loadNib() -> UIView
    {
        let bundle = Bundle(for: CardButton.self)
        let view = bundle.loadNibNamed(String(describing: CardButton.self), owner: self, options: nil)![0] as! UIView
        view.frame = self.bounds
        addSubview(view)
        return view
    }
}
