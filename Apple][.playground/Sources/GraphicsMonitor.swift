

import SwiftUI

/**
 A view to handle color output (40x40 pixels)
 */
public class GraphicsMonitor: UIView {
    public var colorGrids: [[CGRect]] = Array(repeating: [], count: 5)
    public var colors: [CGColor] = [#colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0), #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.9254901960784314, green: 0.23529411764705882, blue: 0.10196078431372549, alpha: 1.0),#colorLiteral(red: 0.4666666666666667, green: 0.7647058823529411, blue: 0.26666666666666666, alpha: 1.0),#colorLiteral(red: 0.23921568627450981, green: 0.6745098039215687, blue: 0.9686274509803922, alpha: 1.0)]
    var rectGrid: [[CGRect]] = [[]]
    
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        
        setupRects()
        
        
        // draw each color layer
        for colorN in 0..<colors.count {
            context.setFillColor(colors[colorN])
            context.addRects(colorGrids[colorN])
            context.drawPath(using: .fill)
        }
    }
    
    // set the color at the indicated location and flag for the view to redraw
    func drawRect(color: Int, at x: Int, _ y: Int) {
        let rect = rectGrid[x][y]
        
        for colorN in 0..<colors.count {
            if color == colorN {
                if !colorGrids[colorN].contains(rect) {
                    colorGrids[colorN].append(rect)
                }
            } else {
                if colorGrids[colorN].contains(rect) {
                    colorGrids[colorN].remove(at: colorGrids[colorN].firstIndex(of: rect)!)
                }
            }
        }
        
        self.setNeedsDisplay()
    }
    
    // calculate the rects that are the pixels
    func setupRects() {
        for x in 0..<40 {
            rectGrid.append([])
            for y in 0..<40 {
                print(x)
                print(y)
                print(frame.width)
                print(frame.height)
                print(frame)
                rectGrid[x].append(CGRect(x: CGFloat(x)*bounds.width/40, y: CGFloat(y)*bounds.height/40, width: bounds.width/40, height: bounds.height/40))
            }
        }
    }
}
