//
//  Custom2CombinedChartRenderer.swift
//  Charts
//
//  Created by Ricardo Paiva on 06/02/2021.
//

import Foundation
import CoreGraphics
import Charts

open class CustomCombinedChartRenderer: NSObject, DataRenderer
{
    public let viewPortHandler: ViewPortHandler
    
    public final var accessibleChartElements: [NSUIAccessibilityElement] = []
    
    public let animator: Animator
    
    @objc open weak var chart: CustomCombinedChartView?
    
    /// if set to true, all values are drawn above their bars, instead of below their top
    @objc open var drawValueAboveBarEnabled = true
    
    /// if set to true, a grey area is drawn behind each bar that indicates the maximum value
    @objc open var drawBarShadowEnabled = false
    
    internal var _renderers = [DataRenderer]()
    
    internal var _drawOrder: [CustomCombinedChartView.DrawOrder] = [.bar, .bubble, .line, .candle, .scatter]
    
    @objc public init(chart: CustomCombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler)
    {
        self.chart = chart
        self.viewPortHandler = viewPortHandler
        self.animator = animator
        
        super.init()
        
        createRenderers()
    }
    
    /// Creates the renderers needed for this combined-renderer in the required order. Also takes the DrawOrder into consideration.
    internal func createRenderers()
    {
        _renderers = [DataRenderer]()
        
        guard let chart = chart else { return }
        
        for order in drawOrder
        {
            switch (order)
            {
            case .bar:
                if chart.barData !== nil
                {
                    _renderers.append(BarChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .line:
                if chart.lineData !== nil
                {
                    _renderers.append(CustomLineChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .candle:
                if chart.candleData !== nil
                {
                    _renderers.append(CandleStickChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .scatter:
                if chart.scatterData !== nil
                {
                    _renderers.append(ScatterChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
                
            case .bubble:
                if chart.bubbleData !== nil
                {
                    _renderers.append(BubbleChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
                break
            }
        }
        
    }
    
    open func initBuffers()
    {
        _renderers.forEach { $0.initBuffers() }
    }
    
    open func drawData(context: CGContext)
    {
        // If we redraw the data, remove and repopulate accessible elements to update label values and frames
        accessibleChartElements.removeAll()
        
        if
            let combinedChart = chart,
            let data = combinedChart.data {
            // Make the chart header the first element in the accessible elements array
            let element = createAccessibleHeader(usingChart: combinedChart,
                                                 andData: data,
                                                 withDefaultDescription: "Combined Chart")
            accessibleChartElements.append(element)
        }
        
        // TODO: Due to the potential complexity of data presented in Combined charts, a more usable way
        // for VO accessibility would be to use axis based traversal rather than by dataset.
        // Hence, accessibleChartElements is not populated below. (Individual renderers guard against dataSource being their respective views)
        _renderers.forEach { $0.drawData(context: context) }
    }
    
    open func drawValues(context: CGContext)
    {
        _renderers.forEach { $0.drawValues(context: context) }
    }
    
    open func drawExtras(context: CGContext)
    {
        _renderers.forEach { $0.drawExtras(context: context) }
    }
    
    open func drawHighlighted(context: CGContext, indices: [Highlight])
    {
        for renderer in _renderers
        {
            var data: ChartData?
            
            if renderer is BarChartRenderer
            {
                data = (renderer as! BarChartRenderer).dataProvider?.barData
            }
            else if renderer is LineChartRenderer
            {
                data = (renderer as! LineChartRenderer).dataProvider?.lineData
            }
            else if renderer is CandleStickChartRenderer
            {
                data = (renderer as! CandleStickChartRenderer).dataProvider?.candleData
            }
            else if renderer is ScatterChartRenderer
            {
                data = (renderer as! ScatterChartRenderer).dataProvider?.scatterData
            }
            else if renderer is BubbleChartRenderer
            {
                data = (renderer as! BubbleChartRenderer).dataProvider?.bubbleData
            }
            
            let dataIndex = data == nil ? nil : (chart?.data as? CombinedChartData)?.allData.firstIndex(of: data!)
            
            let dataIndices = indices.filter{ $0.dataIndex == dataIndex || $0.dataIndex == -1 }
            
            renderer.drawHighlighted(context: context, indices: dataIndices)
        }
    }
    
    open func isDrawingValuesAllowed(dataProvider: ChartDataProvider?) -> Bool
    {
        guard let data = dataProvider?.data else { return false }
        return data.entryCount < Int(CGFloat(dataProvider?.maxVisibleCount ?? 0) * viewPortHandler.scaleX)
    }
    
    /// All sub-renderers.
    @objc open var subRenderers: [DataRenderer]
    {
        get { return _renderers }
        set { _renderers = newValue }
    }
    
    // MARK: Accessors
    
    /// `true` if drawing values above bars is enabled, `false` ifnot
    @objc open var isDrawValueAboveBarEnabled: Bool { return drawValueAboveBarEnabled }
    
    /// `true` if drawing shadows (maxvalue) for each bar is enabled, `false` ifnot
    @objc open var isDrawBarShadowEnabled: Bool { return drawBarShadowEnabled }
    
    /// the order in which the provided data objects should be drawn.
    /// The earlier you place them in the provided array, the further they will be in the background.
    /// e.g. if you provide [DrawOrder.Bar, DrawOrder.Line], the bars will be drawn behind the lines.
    open var drawOrder: [CustomCombinedChartView.DrawOrder]
    {
        get
        {
            return _drawOrder
        }
        set
        {
            if !newValue.isEmpty
            {
                _drawOrder = newValue
            }
        }
    }
    
    public func createAccessibleHeader(usingChart chart: ChartViewBase, andData data: ChartData, withDefaultDescription defaultDescription: String) -> NSUIAccessibilityElement {
        return AccessibleHeader.create(usingChart: chart, andData: data, withDefaultDescription: defaultDescription)
    }
    
    internal struct AccessibleHeader {
        static func create(usingChart chart: ChartViewBase,
                                    andData data: ChartData,
                                    withDefaultDescription defaultDescription: String = "Chart") -> NSUIAccessibilityElement
        {
            let chartDescriptionText = chart.chartDescription.text ?? defaultDescription
            let dataSetDescriptions = data.map { $0.label ?? "" }
            let dataSetDescriptionText = dataSetDescriptions.joined(separator: ", ")

            let element = NSUIAccessibilityElement(accessibilityContainer: chart)
            element.accessibilityLabel = chartDescriptionText + ". \(data.count) dataset\(data.count == 1 ? "" : "s"). \(dataSetDescriptionText)"
            element.accessibilityFrame = chart.bounds
            element.isHeader = true
            
            return element
        }
    }

}
