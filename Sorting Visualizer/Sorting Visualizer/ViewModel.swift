//
//  ViewModel.swift
//  Sorting Visualizer
//
//  Created by Ramadhan Kalih Sewu on 31/05/22.
//

import Foundation

class ViewModel
{
    public var dataSize: Int { didSet {
        if (oldValue != dataSize) { generate() }
    }}
    
    public var orderAscending: Bool = true
    
    private(set) var dataSource: Array<Int> = []
    
    @Published
    private(set) var dataSourceToggleChanged: Bool = false
    
    @Published
    private(set) var dataIndexAccessed: Array<Int> = []
    
    @Published
    private(set) var dataIndexSwapped: Array<Int> = []
    
    @Published
    private(set) var buttonInteractionEnable: Bool = true
    
    public init(dataSize: Int)
    {
        self.dataSize = dataSize
        generate()
    }
    
    public func randomize()
    {
        for _ in 1...dataSize
        {
            let i1 = Int(arc4random()) % dataSize
            let i2 = Int(arc4random()) % dataSize
            dataSource.swapAt(i1, i2)
        }
        dataSourceToggleChanged = !dataSourceToggleChanged
    }
    
    public func bubbleSort()
    {
        sortBegin()
        for i in 0..<dataSize
        {
            for j in i+1..<dataSize
            {
                doAccess([i, j])
                if
                (
                    orderAscending && dataSource[i] > dataSource[j] ||
                    !orderAscending && dataSource[i] < dataSource[j]
                )
                {
                    doSwap(i, j)
                }
            }
        }
        sortEnd()
    }
    
    public func mergeSort()
    {
        sortBegin()
        sortEnd()
    }
    
    public func heapSort()
    {
        sortBegin()
        sortEnd()
    }
    
    public func quickSort()
    {
        sortBegin()
        sortEnd()
    }
    
    private func doAccess(_ access: Array<Int>)
    {
        dataIndexAccessed = access
        usleep(useconds_t(1000000 / dataSize))
    }
    
    private func doSwap(_ a: Int, _ b: Int)
    {
        dataIndexSwapped = [a, b]
        let temp = dataSource[a]
        dataSource[a] = dataSource[b]
        dataSource[b] = temp
        usleep(useconds_t(1000000 / dataSize))
    }
    
    private func sortBegin()
    {
        buttonInteractionEnable = false
    }
    
    private func sortEnd()
    {
        dataIndexAccessed = []
        dataIndexSwapped = []
        buttonInteractionEnable = true
    }
    
    private func generate()
    {
        dataSource = []
        dataSource.reserveCapacity(dataSize)
        dataSource.append(contentsOf: 1...dataSize)
        dataSourceToggleChanged = !dataSourceToggleChanged
    }
}
