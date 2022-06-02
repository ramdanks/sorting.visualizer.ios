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
        dataSource = []
        dataSource.reserveCapacity(dataSize)
        dataSource.append(contentsOf: 1...dataSize)
        dataSourceToggleChanged = !dataSourceToggleChanged
    }}
    
    public var orderAscending: Bool = true
    
    private(set) var dataSource: Array<Int> = []
    
    @Published
    private(set) var dataSourceToggleChanged: Bool = false
    
    @Published
    private(set) var dataIndexAccessed: Set<Int> = []
    
    @Published
    private(set) var dataIndexSwapped: (Int, Int) = (-1, -1)
    
    @Published
    private(set) var dataIndexSetReference: (mutated: Int, from: Int) = (-1, -1)
    
    @Published
    private(set) var dataIndexSetForce: (index: Int, value: Int) = (-1, -1)
    
    @Published
    private(set) var buttonInteractionEnable: Bool = true
    
    public init(dataSize: Int)
    {
        self.dataSize = dataSize
        ({ self.dataSize = self.dataSize })()
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
    
    public func selectionSort()
    {
        sortBegin()
        guard dataSource.count > 1 else { return }
        for x in 0 ..< dataSource.count - 1
        {
            var wanted = x
            for y in x + 1 ..< dataSource.count
            {
                doAccess([y, wanted])
                if
                (
                    orderAscending && dataSource[y] < dataSource[wanted] ||
                    !orderAscending && dataSource[y] > dataSource[wanted]
                )
                { wanted = y }
            }
            doAccess([x, wanted])
            if (x != wanted)
                { doSwap(x, wanted) }
        }
        sortEnd()
    }
    
    public func insertionSort()
    {
        sortBegin()
        for x in 1..<dataSize
        {
            var y = x
            let temp = dataSource[y]
            while (true)
            {
                doAccess([y, y - 1])
                if
                (
                    orderAscending && (y <= 0 || temp > dataSource[y - 1]) ||
                    !orderAscending && (y <= 0 || temp < dataSource[y - 1])
                )
                { break }
                doSetReference(y, y - 1)
                y -= 1
            }
            doSetForce(y, value: temp)
        }
        sortEnd()
    }
    
    public func quickSort()
    {
        sortBegin()
        quickSort(startIndex: 0, endIndex: dataSize - 1)
        sortEnd()
    }
    
    private func doAccess(_ access: Set<Int>)
    {
        dataIndexAccessed = access
        usleep(useconds_t(1000000 / dataSize))
        dataIndexAccessed = []
    }
    
    private func doSwap(_ a: Int, _ b: Int)
    {
        if (a == b) { return }
        dataIndexSwapped = (a, b)
        (dataSource[a], dataSource[b]) = (dataSource[b], dataSource[a])
        usleep(useconds_t(1000000 / dataSize))
    }
    
    private func doSetReference(_ a: Int, _ b: Int)
    {
        if (a == b) { return }
        dataIndexSetReference = (a, b)
        dataSource[a] = dataSource[b]
        usleep(useconds_t(1000000 / dataSize))
    }
    
    private func doSetForce(_ index: Int, value: Int)
    {
        dataIndexSetForce = (index, value)
        dataSource[index] = value
        usleep(useconds_t(1000000 / dataSize))
    }
    
    private func sortBegin()
    {
        buttonInteractionEnable = false
    }
    
    private func sortEnd()
    {
        buttonInteractionEnable = true
    }
}


// MARK: Quick Sort
extension ViewModel
{
    private func quickSort(startIndex: Int, endIndex: Int)
    {
        if (startIndex >= endIndex) { return }
        let placedItemIndex = partition(startIndex: startIndex, endIndex: endIndex)
        quickSort(startIndex: startIndex, endIndex: placedItemIndex-1)
        quickSort(startIndex: placedItemIndex+1, endIndex: endIndex)
    }
    
    private func partition(startIndex: Int, endIndex: Int) -> Int
    {
        var q = startIndex
        for index in startIndex..<endIndex
        {
            doAccess([q, endIndex])
            if
            (
                orderAscending && dataSource[index] < dataSource[endIndex] ||
                !orderAscending && dataSource[index] > dataSource[endIndex]
            )
            {
                doSwap(q, index)
                q += 1
            }
        }
        doSwap(q, endIndex)
        return q
    }
}
