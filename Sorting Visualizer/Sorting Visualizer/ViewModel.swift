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
    
    public func sort()
    {
        buttonInteractionEnable = false
        let sleepTimeMicro = useconds_t(1000000 / dataSize)
        
        for i in 0..<dataSize
        {
            for j in i+1..<dataSize
            {
                dataIndexAccessed = [i, j]
                usleep(sleepTimeMicro)
                if
                (
                    orderAscending && dataSource[i] > dataSource[j] ||
                    !orderAscending && dataSource[i] < dataSource[j]
                )
                {
                    dataIndexSwapped = [i, j]
                    let temp = dataSource[i]
                    dataSource[i] = dataSource[j]
                    dataSource[j] = temp
                    usleep(sleepTimeMicro)
                }
            }
        }
        
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
