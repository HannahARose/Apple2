
import SpriteKit
import UIKit
import SwiftUI
import PlaygroundSupport

import Foundation

/**
 A view controller to coordinate the visual io
 */

public class AppleII : UIViewController {
    var bgImageContainer: UIView!
    var bgImage: UIImageView!
    var keyboard: Keyboard!
    var monitor: TextMonitor!
    public var os: IntegerBasic!
    var gm: GraphicsMonitor!
    
    public override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        os = IntegerBasic(height: 24, width: 40)
        
        // setup views
        bgImage = UIImageView(image: UIImage(named: "AppleII.png"))
        bgImageContainer = UIView()
        bgImageContainer.addSubview(bgImage)
        view.addSubview(bgImageContainer)
        
        
        monitor = TextMonitor()
        monitor.backgroundColor = #colorLiteral(red: 0.3, green: 0.3, blue: 0.3, alpha: 0)
        monitor.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        view.addSubview(monitor)
        let font = UIFont(name: "Courier", size: 10.7)
        monitor.font = font
        monitor.isScrollEnabled = false
        
        
        keyboard = Keyboard()
        keyboard.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        view.addSubview(keyboard)
        keyboard.addComp(comp: self)
        
        gm = GraphicsMonitor()
        gm.backgroundColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        gm.isHidden = true
        view.addSubview(gm)
        
        // link the monitors to the "operating system"
        keyboard.setOS(os)
        os.setTextMonitor(monitor)
        os.setGM(gm)
        
        
        // position the views
        bgImageContainer.translatesAutoresizingMaskIntoConstraints = false
        bgImage.translatesAutoresizingMaskIntoConstraints = false
        monitor.translatesAutoresizingMaskIntoConstraints = false
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        gm.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bgImage.centerXAnchor.constraint(equalTo: bgImageContainer.centerXAnchor),
            bgImage.centerYAnchor.constraint(equalTo: bgImageContainer.centerYAnchor),
            bgImage.widthAnchor.constraint(equalToConstant: 500),
            bgImage.heightAnchor.constraint(equalToConstant: 500),
            
            bgImageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bgImageContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            bgImageContainer.widthAnchor.constraint(equalToConstant: 500),
            bgImageContainer.heightAnchor.constraint(equalToConstant: 500),
            
            monitor.centerXAnchor.constraint(equalTo:view.centerXAnchor,constant: 0),
            monitor.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -85),
            monitor.widthAnchor.constraint(equalToConstant: 280),
            monitor.heightAnchor.constraint(equalToConstant: 280),
            
            keyboard.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -3),
            keyboard.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 160),
            keyboard.widthAnchor.constraint(equalToConstant:326),
            keyboard.heightAnchor.constraint(equalToConstant: 125),
            
            gm.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            gm.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -105),
            gm.widthAnchor.constraint(equalToConstant:280),
            gm.heightAnchor.constraint(equalToConstant: 210)
        ])
        
        self.view = view
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
