//
//  ViewController.swift
//  Sorting Visualizer
//
//  Created by Ramadhan Kalih Sewu on 30/05/22.
//

import UIKit

class ViewController: UIViewController
{
    enum Sort: Int { case bubble = 0, merge = 1, heap = 2, quick = 3 }
    
    var viewModel: ViewModel!
    
    var sortRadioManager: RadioButtonManager!
    var graphViews: Array<UIView> = []
    
    let dataSizeMax = 20
    let dataSizeMin = 6
    
    var cancellable: AnyObject!
    var cancellable2: AnyObject!
    var cancellable3: AnyObject!
    var cancellable4: AnyObject!
    
    @IBOutlet weak var dataSizeSlider: UISlider!
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var randomizeButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var orderSegmented: UISegmentedControl!
    
    @IBOutlet weak var bubbleCardButton: CardButton!
    @IBOutlet weak var mergeCardButton: CardButton!
    @IBOutlet weak var heapCardButton: CardButton!
    @IBOutlet weak var quickCardButton: CardButton!
    
    let neutralColor: UIColor   = .systemBlue
    let accessColor: UIColor    = .systemRed
    let swapColor: UIColor      = .systemYellow
    let doneColor: UIColor      = .systemGreen
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.dataSizeSlider.value = 0.0
        self.viewModel = ViewModel(dataSize: dataSizeMin)
        self.sortRadioManager = RadioButtonManager([bubbleCardButton, mergeCardButton, heapCardButton, quickCardButton])
        
        cancellable4 = self.viewModel.$buttonInteractionEnable.sink(receiveValue: { enable in
            DispatchQueue.main.async { [unowned self] in
                dataSizeSlider.isEnabled    = enable
                randomizeButton.isEnabled   = enable
                orderSegmented.isEnabled    = enable
                playButton.isEnabled        = enable
                sortRadioManager.views.forEach { $0.view.isEnabled = enable }
            }
        })
        cancellable = self.viewModel.$dataSourceToggleChanged.sink(receiveValue: { [unowned self] _ in draw() })
        cancellable2 = self.viewModel.$dataIndexAccessed.sink(receiveValue: { [unowned self] in
            // restore previously accessed data to unhighlighted
            setGraphBarColor(viewModel.dataIndexAccessed, color: neutralColor)
            setGraphBarColor($0, color: accessColor)
        })
        cancellable3 = self.viewModel.$dataIndexSwapped.sink(receiveValue: { [unowned self] in
            if ($0.isEmpty) { return }
            setGraphBarColor($0, color: swapColor)
            let view0 = graphViews[$0[0]]
            let view1 = graphViews[$0[1]]
            DispatchQueue.main.async {
                let view0Height = view0.frame.height
                let view1Height = view1.frame.height
                view0.constraints.first(where: { $0.firstAttribute == .height })?.constant = view1Height
                view1.constraints.first(where: { $0.firstAttribute == .height })?.constant = view0Height
            }
        })
    }

    
    private func draw()
    {
        let barSpacing: CGFloat = 8.0
        var prevBar: UIView?
        
        graphView.subviews.forEach { $0.removeFromSuperview() }
        graphViews.removeAll()
        
        for height in viewModel.dataSource
        {
            // most left (leading) bar
            let leadingBar = prevBar == nil
                
            let bar = UIView()
            graphViews.append(bar)
            graphView.addSubview(bar)
            bar.backgroundColor = .systemBlue
            
            bar.layer.cornerRadius = 60 / CGFloat(viewModel.dataSource.count)
            bar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            let topInset = 16.0
            let barHeight = (graphView.frame.height - topInset) * CGFloat(height) / CGFloat(viewModel.dataSize)
            let leadingAnchor = leadingBar ? graphView.leadingAnchor : prevBar!.trailingAnchor
            
            bar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bar.heightAnchor.constraint(equalToConstant: barHeight),
                bar.bottomAnchor.constraint(equalTo: graphView.bottomAnchor),
                bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: barSpacing),
            ])
            prevBar?.widthAnchor.constraint(equalTo: bar.widthAnchor).isActive = true
            prevBar = bar
        }
        prevBar?.trailingAnchor.constraint(equalTo: graphView.trailingAnchor, constant: -barSpacing).isActive = true
    }
    
    private func setGraphBarColor(_ range: Array<Int>, color: UIColor)
    {
        DispatchQueue.main.async { [unowned self] in
            for i in range {
                graphViews[i].backgroundColor = color
            }
        }
    }
    
    @IBAction func onThemeChanged(_ sender: UISegmentedControl)
    {
        let style: UIUserInterfaceStyle = sender.selectedSegmentIndex == 0 ? .light : .dark
        self.overrideUserInterfaceStyle = style
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    @IBAction func onDataSizeChanged(_ sender: UISlider)
    {
        let range = dataSizeMax - dataSizeMin
        self.viewModel.dataSize = dataSizeMin + Int(sender.value * Float(range))
    }
    
    @IBAction func onOrderChanged(_ sender: UISegmentedControl)
    {
        setGraphBarColor([Int](0..<graphViews.count), color: neutralColor)
        self.viewModel.orderAscending = sender.selectedSegmentIndex == 0
        let orderText = sender.selectedSegmentIndex == 0 ? "Ascending" : "Descending"
        orderLabel.text = "Order: \(orderText)"
    }
    
    @IBAction func onRandomizeButton(_ sender: UIButton)
    {
        self.viewModel.randomize()
    }
    
    @IBAction func onBubbleSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.bubble.rawValue
    }
    
    @IBAction func onMergeSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.merge.rawValue
    }
    
    @IBAction func onHeapSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.heap.rawValue
    }
    
    @IBAction func onQuickSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.quick.rawValue
    }
    
    @IBAction func onPlayButton(_ sender: UIButton)
    {
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            switch (sortRadioManager.selectedIndex)
            {
            case Sort.bubble.rawValue:
                viewModel.bubbleSort()
                break
            case Sort.merge.rawValue:
                viewModel.mergeSort()
                break
            case Sort.heap.rawValue:
                viewModel.heapSort()
                break
            case Sort.quick.rawValue:
                viewModel.quickSort()
                break
            default:
                break;
            }
            // mark done if sort process has been completed
            DispatchQueue.main.async { [unowned self] in graphViews.forEach { $0.backgroundColor = doneColor } }
        }
    }
}
