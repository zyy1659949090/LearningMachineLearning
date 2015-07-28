//
//  BaseChartView.swift
//  LearningMachineLearning
//
//  Created by Grace on 7/26/15.
//  Copyright (c) 2015 Grace Avery. All rights reserved.
//

import UIKit
import SwiftCharts

struct ChartPadding : OptionSetType {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    
    static var PadNone: ChartPadding { return ChartPadding(rawValue: 0) }
    static var PadBottom: ChartPadding { return ChartPadding(rawValue: 1 << 0) }
    static var PadTop: ChartPadding { return ChartPadding(rawValue: 1 << 1) }
    static var PadLeft: ChartPadding { return ChartPadding(rawValue: 1 << 2) }
    static var PadRight: ChartPadding { return ChartPadding(rawValue: 1 << 3) }
    static var PadAll: ChartPadding { return ChartPadding(rawValue: 15) }
}

class BaseChartView: UIView {
    var chartFrame: CGRect!
    var chart: Chart?
    var pointSize: Int?
    var minX, minY, maxX, maxY, xInterval, yInterval: Double!
    var xAxisLabel: String!
    var yAxisLabel: String!
    var labelSettings = ChartLabelSettings(font: ExamplesDefaults.labelFont)
    var paddingOptions = ChartPadding.PadNone

    func baseChartLayers(labelSettings: ChartLabelSettings, minX: Double, maxX: Double, minY: Double, maxY: Double, xInterval: Double, yInterval: Double, xAxisLabel: String, yAxisLabel: String) -> (ChartAxisLayer, ChartAxisLayer, CGRect) {
        let xValues = Array(stride(from: minX, through: maxX, by: xInterval)).map { ChartAxisValueFloat(CGFloat($0), labelSettings: labelSettings)}
        let yValues = Array(stride(from: minY, through: maxY, by: yInterval)).map {ChartAxisValueFloat(CGFloat($0), labelSettings: labelSettings)}
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: xAxisLabel, settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: yAxisLabel, settings: labelSettings))
        
        let chartFrame = ExamplesDefaults.chartFrame(self.chartFrame)
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: ExamplesDefaults.chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        return (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
    }
    
    func baseChartLayers(xAxisLabel xAxisLabel: String, yAxisLabel: String) -> (ChartAxisLayer, ChartAxisLayer, CGRect) {
        return baseChartLayers(labelSettings, minX: minX, maxX: maxX, minY: minY, maxY: maxY, xInterval: xInterval, yInterval: yInterval, xAxisLabel: xAxisLabel, yAxisLabel: yAxisLabel)
    }
    
    func toLayers(models: [LabeledInput], layerSpecifications: [DataType : UIColor], xAxis: ChartAxisLayer, yAxis: ChartAxisLayer, chartInnerFrame: CGRect) -> [ChartLayer] {
        
        // group chartpoints by type
        let groupedChartPoints: Dictionary<DataType, [ChartPoint]> = models.reduce(Dictionary<DataType, [ChartPoint]>()) {(var dict, model) in
            let points = model.0
            let type = model.1
            let x = CGFloat(points[0])
            let y = CGFloat(points[1])
            let chartPoint = ChartPoint(x: ChartAxisValueFloat(x), y: ChartAxisValueFloat(y))
            if dict[type] != nil {
                dict[type]!.append(chartPoint)
            } else {
                dict[type] = [chartPoint]
            }
            return dict
        }
        
        // create layer for each group
        var dim: CGFloat = Env.iPad ? 14 : 7
        if let d = pointSize {
            dim = CGFloat(d)
        }
        let size = CGSizeMake(dim, dim)
        let layers: [ChartLayer] = groupedChartPoints.map {(type, chartPoints) in
            let color = layerSpecifications[type]!
            return ChartPointsScatterCirclesLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: chartInnerFrame, chartPoints: chartPoints, itemSize: size, itemFillColor: color)
        }
        
        return layers
    }
    
    func setDataMinMaxInterval(data: [LabeledInput]) {
        chartFrame = frame
        var minX = Double(UINT32_MAX)
        var minY = Double(UINT32_MAX)
        var maxX = -Double(UINT32_MAX)
        var maxY = -Double(UINT32_MAX)
        
        for input in data {
            let x = input.0[0]
            let y = input.0[1]
            
            if x < minX {
                minX = x
            } else if x > maxX {
                maxX = x
            }
            if y < minY {
                minY = y
            } else if y > maxY {
                maxY = y
            }
        }
        
        let xDiff = abs(maxX - minX)
        let yDiff = abs(maxY - minY)
        
        xInterval = xDiff/10
        yInterval = yDiff/8

        
        if paddingOptions.contains(.PadBottom) {
            minY -= yInterval
        }
        if paddingOptions.contains(.PadTop) {
            maxY += yInterval
        }
        
        if paddingOptions.contains(.PadLeft) {
            minX -= xInterval
        }
        if paddingOptions.contains(.PadRight) {
            maxX += xInterval
        }
        // the stride sometimes misses the top value if this is not included
        maxY += (yInterval / 5)
        maxX += (xInterval / 5)

     
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }
    
    

}