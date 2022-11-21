//
//  Area2FillFormatter.swift
//  Charts
//
//  Created by Ricardo Paiva on 06/02/2021.
//

import Foundation
import Charts

public class AreaFillFormatter: FillFormatter {
    var fillLineDataSet: LineChartDataSet?
    
    public init(fillLineDataSet: LineChartDataSet) {
        self.fillLineDataSet = fillLineDataSet
    }
    
    public func getFillLinePosition(dataSet: LineChartDataSetProtocol, dataProvider: LineChartDataProvider) -> CGFloat {
        return 0.0
    }
    
    public func getFillLineDataSet() -> LineChartDataSet {
        return fillLineDataSet ?? LineChartDataSet()
    }
}
