//
//  ViewController.swift
//  Sorting Visualizer
//
//  Created by Ramadhan Kalih Sewu on 30/05/22.
//

import Combine
import UIKit

class ViewController: UIViewController
{
    // enum provide an index for sortRadioManager
    enum Sort: Int { case bubble = 0, selection = 1, insertion = 2, quick = 3 }
    
    // enum provide an index for Segmented Control (See Storyboard)
    enum ThemeStyle: Int { case light = 0, dark = 1 }
    var themeOverride = false
    
    // MARK: View Model and Data Binding
    var initState: Bool = true
    var viewModel: ViewModel!
    var viewModelSubscribers: [AnyCancellable]?
    
    // MARK: Sorting Content View and Manager
    var sortRadioManager: RadioButtonManager!
    var graphViews: Array<UIView> = []
    
    // MARK: Graph Data Size
    let dataSizeMax = 20
    let dataSizeMin = 6
    
    // MARK: Haptic Feedback
    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    let buttonFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: IBOutlet
    @IBOutlet weak var themeSegmentedControl: UISegmentedControl!
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
    
    // MARK: Bar Color
    let neutralColor: UIColor   = .systemBlue
    let accessColor: UIColor    = .systemRed
    let setColor: UIColor       = .systemYellow
    let doneColor: UIColor      = .systemGreen
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.dataSizeSlider.value = 0.0
        self.viewModel = ViewModel(dataSize: dataSizeMin)
        
        // arranged based on enum Sort
        self.sortRadioManager = RadioButtonManager([
            bubbleCardButton,
            mergeCardButton,
            heapCardButton,
            quickCardButton
        ])
        
        // provide data binding between view model to our view controller
        self.viewModelSubscribers = [
            // when the data source changed it's value
            self.viewModel.$dataSourceToggleChanged.sink(receiveValue: { [unowned self] _ in
                // view needs to be updated on main thread
                DispatchQueue.main.async { [unowned self] in draw() }
            }),
            // data that currently accessed by the sort function
            self.viewModel.$dataIndexAccessed.sink(receiveValue: { [unowned self] value in
                // view needs to be updated on main thread
                DispatchQueue.main.async { [unowned self] in setGraphBarColor(value, color: accessColor) }
            }),
            // data that needs to be swapped by the sort function
            self.viewModel.$dataIndexSwapped.sink(receiveValue: { [unowned self] value in
                if (initState) { return }
                // swap the bar height (view needs to be updated on main thread)
                DispatchQueue.main.async { [unowned self] in
                    let view0 = graphViews[value.0]
                    let view1 = graphViews[value.1]
                    view0.constraints.first(where: { $0.firstAttribute == .height })?.constant = view1.frame.height
                    view1.constraints.first(where: { $0.firstAttribute == .height })?.constant = view0.frame.height
                    setGraphBarColor([value.0, value.1], color: setColor)
                }
            }),
            // a specific data that needs to be set and equal with the reference data
            self.viewModel.$dataIndexSetReference.sink(receiveValue: { [unowned self] value in
                if (initState) { return }
                // view needs to be updated on main thread
                DispatchQueue.main.async { [unowned self] in
                    let view = graphViews[value.mutated]
                    let viewReferenceHeight = graphViews[value.from].frame.height
                    view.constraints.first(where: { $0.firstAttribute == .height })?.constant = viewReferenceHeight
                    setGraphBarColor([value.mutated, value.from], color: setColor)
                }
            }),
            // a specific data that needs to be set with some value
            self.viewModel.$dataIndexSetForce.sink(receiveValue: { [unowned self] value in
                if (initState) { return }
                // view needs to be updated on main thread
                DispatchQueue.main.async { [unowned self] in
                    let view = graphViews[value.index]
                    view.constraints.first(where: { $0.firstAttribute == .height })?.constant = getBarHeight(value.value)
                    setGraphBarColor([value.index], color: setColor)
                }
            }),
            // view model wants to enable or disable user input (because sort is in progress / done)
            self.viewModel.$buttonInteractionEnable.sink(receiveValue: { enable in
                // view needs to be updated on main thread
                DispatchQueue.main.async { [unowned self] in
                    dataSizeSlider.isEnabled    = enable
                    randomizeButton.isEnabled   = enable
                    orderSegmented.isEnabled    = enable
                    playButton.isEnabled        = enable
                    sortRadioManager.views.forEach { $0.view.isEnabled = enable }
                }
            }),
        ]
        initState = false
    }
    
    public func adjustThemeSegmentedControl()
    {
        if (themeOverride) { return }
        let currStyle = UIScreen.main.traitCollection.userInterfaceStyle
        themeSegmentedControl.selectedSegmentIndex = currStyle == .light ?
            ThemeStyle.light.rawValue : ThemeStyle.dark.rawValue
    }
    
    @IBAction func onThemeChanged(_ sender: UISegmentedControl)
    {
        self.themeOverride = true
        self.overrideUserInterfaceStyle = sender.selectedSegmentIndex == ThemeStyle.light.rawValue ? .light : .dark
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
    
    //MARK: Radio Button Selection
    
    @IBAction func onBubbleSortButton(_ sender: CardButton)
    {
        self.sortRadioManager.selectedIndex = Sort.bubble.rawValue
    }
    
    @IBAction func onSelectionSortButton(_ sender: CardButton)
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
    
    // MARK: Play Button
    
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
            // view needs to be updated on main thread
            DispatchQueue.main.async { [unowned self] in graphViews.forEach { $0.backgroundColor = doneColor } }
        }
    }
    
    // MARK: Internal Function
    
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
        for (i, view) in graphViews.enumerated() {
            view.backgroundColor = range.contains(i) ? color : neutralColor
        }
    }
}
