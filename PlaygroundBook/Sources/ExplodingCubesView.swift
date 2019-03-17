import ARKit
import Foundation
import UIKit

@available(iOS 11.0, *)
public class ExplodingCubesView: ARSCNView
{
    public override init(frame: CGRect, options: [String : Any]? = nil)
    {
        super.init(frame: frame, options: options)
        
        let scene = SCNScene()
        self.scene = scene
        
        self.session.run(ARWorldTrackingConfiguration())
        
        // listen for taps
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ExplodingCubesView.viewTapped(sender: )))
        self.addGestureRecognizer(recognizer)
        
        // add cube
        let cube = ExplodingCube()
        scene.rootNode.addChildNode(cube.node)
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    @objc
    func viewTapped(sender: UITapGestureRecognizer)
    {
        let p = sender.location(in: self)
        let hitResults = self.hitTest(p, options: [:])
        if hitResults.count > 0
        {
            let result: SCNHitTestResult = hitResults[0]
            result.node.removeFromParentNode()
        }
    }
}
