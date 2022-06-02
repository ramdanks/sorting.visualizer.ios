//
//  ViewController.swift
//  Sorting Visualizer
//
//  Created by Ramadhan Kalih Sewu on 30/05/22.
//

import UIKit

class ViewController: UIViewController
{
    enum Sort: Int { case bubble = 0, selection = 1, insertion = 2, quick = 3 }
    
    var initState: Bool = true
    var viewModel: ViewModel!
    
    var sortRadioManager: RadioButtonManager!
    var graphViews: Array<UIView> = []
    
    let dataSizeMax = 20
    let dataSizeMin = 6
    
    var cancellable: AnyObject!
    var cancellable2: AnyObject!
    var cancellable3: AnyObject!
    var cancellable4: AnyObject!
    var cancellable5: AnyObject!
    var cancellable6: AnyObject!
    
    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    let buttonFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
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
    let setColor: UIColor      = .systemYellow
    let doneColor: UIColor      = .systemGreen
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.dataSizeSlider.value = 0.0
        self.viewModel = ViewModel(dataSize: dataSizeMin)
        self.sortRadioManager = RadioButtonManager([bubbleCardButton, mergeCardButton, heapCardButton, quickCardButton])
        
        cancellable = self.viewModel.$dataSourceToggleChanged.sink(receiveValue: { [unowned self] _ in draw() })
        
        cancellable2 = self.viewModel.$dataIndexAccessed.sink(receiveValue: { [unowned self] in
            setGraphBarColor($0, color: accessColor)
        })
        
        cancellable3 = self.viewModel.$dataIndexSwapped.sink(receiveValue: { [unowned self] in
            if (initState) { return }
            setGraphBarColor([$0.0, $0.1], color: setColor)
            let view0 = graphViews[$0.0]
            let view1 = graphViews[$0.1]
            DispatchQueue.main.async {
                let view0Height = view0.frame.height
                let view1Height = view1.frame.height
                view0.constraints.first(where: { $0.firstAttribute == .height })?.constant = view1Height
                view1.constraints.first(where: { $0.firstAttribute == .height })?.constant = view0Height
            }
        })
        
        cancellable4 = self.viewModel.$buttonInteractionEnable.sink(receiveValue: { enable in
            DispatchQueue.main.async { [unowned self] in
                dataSizeSlider.isEnabled    = enable
                randomizeButton.isEnabled   = enable
                orderSegmented.isEnabled    = enable
                playButton.isEnabled        = enable
                sortRadioManager.views.forEach { $0.view.isEnabled = enable }
            }
        })
        
        cancellable5 = self.viewModel.$dataIndexSetReference.sink(receiveValue: { [unowned self] in
            if (initState) { return }
            setGraphBarColor([$0.0, $0.1], color: setColor)
            let viewMutated      = graphViews[$0.mutated]
            let viewReference    = graphViews[$0.from]
            DispatchQueue.main.async {
                let viewReferenceHeight = viewReference.frame.height
                viewMutated.constraints.first(where: { $0.firstAttribute == .height })?.constant = viewReferenceHeight
            }
        })
        
        cancellable6 = self.viewModel.$dataIndexSetForce.sink(receiveValue: { [unowned self] in
            if (initState) { return }
            setGraphBarColor([$0.index], color: setColor)
            let view = graphViews[$0.index]
            let height = getBarHeight($0.value)
            DispatchQueue.main.async {
                view.constraints.first(where: { $0.firstAttribute == .height })?.constant = height
            }
        })
        
        initState = false
    }

    
    private func draw()
    {
        let barSpacing: CGFloat = 8.0
        var prevBar: UIView?
        
        graphView.subviews.forEach { $0.removeFromSuperview() }
        graphViews.removeAll()
        
        for value in viewModel.dataSource
        {
            // most left (leading) bar
            let leadingBar = prevBar == nil
                
            let bar = UIView()
            graphViews.append(bar)
            graphView.addSubview(bar)
            bar.backgroundColor = .systemBlue
            
            bar.layer.cornerRadius = 60 / CGFloat(viewModel.dataSource.count)
            bar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            let barHeight = getBarHeight(value)
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
    
    private func getBarHeight(_ dataValue: Int) -> CGFloat
    {
        let topInset = 16.0
        return (graphView.frame.height - topInset) * CGFloat(dataValue) / CGFloat(viewModel.dataSize)
    }
    
    private func setGraphBarColor(_ range: Set<Int>, color: UIColor)
    {
        DispatchQueue.main.async { [unowned self] in
            for (i, view) in graphViews.enumerated() {
                view.backgroundColor = range.contains(i) ? color : neutralColor
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
        let clippedSize = dataSizeMin + Int(sender.value * Float(range))
        if (viewModel.dataSize != clippedSize)
        {
            viewModel.dataSize = clippedSize
            selectionFeedbackGenerator.selectionChanged()
        }
    }
    
    @IBAction func onOrderChanged(_ sender: UISegmentedControl)
    {
        setGraphBarColor([], color: accessColor)
        self.viewModel.orderAscending = sender.selectedSegmentIndex == 0
        let orderText = sender.selectedSegmentIndex == 0 ? "Ascending" : "Descending"
        orderLabel.text = "Order: \(orderText)"
    }
    
    @IBAction func onRandomizeButton(_ sender: UIButton)
    {
        buttonFeedbackGenerator.prepare()
        self.viewModel.randomize()
        buttonFeedbackGenerator.impactOccurred()
    }
    
    @IBAction func onBubbleSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.bubble.rawValue
    }
    
    @IBAction func onMergeSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.selection.rawValue
    }
    
    @IBAction func onHeapSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.insertion.rawValue
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
            case Sort.selection.rawValue:
                viewModel.selectionSort()
                break
            case Sort.insertion.rawValue:
                viewModel.insertionSort()
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
