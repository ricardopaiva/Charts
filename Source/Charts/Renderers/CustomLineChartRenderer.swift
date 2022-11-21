//
//  CustomLineChartRenderer.swift
//  Charts
//
//  Created by Ricardo Paiva on 06/02/2021.
//

import Foundation
import CoreGraphics

open class CustomLineChartRenderer: LineChartRenderer {
    override open func drawLinearFill(context: CGContext, dataSet: LineChartDataSetProtocol, trans: Transformer, bounds: XBounds) {
        guard let dataProvider = dataProvider else { return }
        
        let areaFillFormatter = dataSet.fillFormatter as? AreaFillFormatter
        
        let filled = generateFilledPath(
            dataSet: dataSet,
            fillMin: dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0,
            fillLineDataSet: areaFillFormatter?.getFillLineDataSet(),
            bounds: bounds,
            matrix: trans.valueToPixelMatrix)
        
        if dataSet.fill != nil
        {
            drawFilledPath(context: context, path: filled, fill: dataSet.fill!, fillAlpha: dataSet.fillAlpha)
        }
        else
        {
            drawFilledPath(context: context, path: filled, fillColor: dataSet.fillColor, fillAlpha: dataSet.fillAlpha)
        }
    }
    
    fileprivate func generateFilledPath(dataSet: LineChartDataSetProtocol, fillMin: CGFloat, fillLineDataSet: LineChartDataSet?, bounds: XBounds, matrix: CGAffineTransform) -> CGPath
    {
        let phaseY = animator.phaseY
        let isDrawSteppedEnabled = dataSet.mode == .stepped
        let matrix = matrix
        
        var e: ChartDataEntry!
        var fillLineE: ChartDataEntry?
        
        let filled = CGMutablePath()
        
        e = dataSet.entryForIndex(bounds.min)
        fillLineE = fillLineDataSet?.entryForIndex(bounds.min)
        
        if e != nil
        {
            if let fillLineE = fillLineE
            {
                filled.move(to: CGPoint(x: CGFloat(e.x), y: CGFloat(fillLineE.y * phaseY)), transform: matrix)
            }
            else
            {
                filled.move(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
            }
            
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
        }
        
        // Create the path for the data set entries
        for x in stride(from: (bounds.min + 1), through: bounds.range + bounds.min, by: 1)
        {
            guard let e = dataSet.entryForIndex(x) else { continue }
            
            if isDrawSteppedEnabled
            {
                guard let ePrev = dataSet.entryForIndex(x-1) else { continue }
                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(ePrev.y * phaseY)), transform: matrix)
            }
            
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
        }
        
        // Draw a path to the start of the fill line
        e = dataSet.entryForIndex(bounds.range + bounds.min)
        fillLineE = fillLineDataSet?.entryForIndex(bounds.range + bounds.min)
        if e != nil
        {
            if let fillLineE = fillLineE
            {
                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(fillLineE.y * phaseY)), transform: matrix)
            }
            else
            {
                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
            }
        }
        
        // Draw the path for the fill line (backwards)
        if let fillLineDataSet = fillLineDataSet {
            for x in stride(from: (bounds.min + 1), through: bounds.range + bounds.min, by: 1).reversed()
            {
                guard let e = fillLineDataSet.entryForIndex(x) else { continue }
                
                if isDrawSteppedEnabled
                {
                    guard let ePrev = fillLineDataSet.entryForIndex(x-1) else { continue }
                    filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(ePrev.y * phaseY)), transform: matrix)
                }
                
                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
            }
        }
        
        filled.closeSubpath()
        
        return filled
    }

}
