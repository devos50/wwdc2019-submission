import ARKit
import Foundation
import UIKit

@available(iOS 11.0, *)
public class ExplodingCubesView: ARSCNView, SCNPhysicsContactDelegate
{
    public override init(frame: CGRect, options: [String : Any]? = nil)
    {
        super.init(frame: frame, options: options)
        
        let scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        self.scene = scene
        
        //self.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints];
        
        self.session.run(ARWorldTrackingConfiguration())
        
        // listen for taps
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ExplodingCubesView.viewTapped(sender: )))
        self.addGestureRecognizer(recognizer)
        
        // add cube
        let cube = ExplodingCube()
        cube.node.position = SCNVector3(floatBetween(-0.5, and: 0.5), floatBetween(-0.5, and: 0.5), floatBetween(-0.5, and: 0.5))
        scene.rootNode.addChildNode(cube.node)
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    func floatBetween(_ first: Float,  and second: Float) -> Float
    {
        return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3)
    {
        if let frame = self.session.currentFrame
        {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    func projectedDirection(pt: CGPoint?) -> SCNVector3
    {
        guard pt != nil else {
            return SCNVector3(0, 0, 1)
        }
        
        let farPt  = self.unprojectPoint(SCNVector3(Float(pt!.x), Float(pt!.y), 1))
        let nearPt = self.unprojectPoint(SCNVector3(Float(pt!.x), Float(pt!.y), 0))
        
        return SCNVector3((farPt.x - nearPt.x)/400, (farPt.y - nearPt.y)/400, (farPt.z - nearPt.z)/400)
    }
    
    @objc
    func viewTapped(sender: UITapGestureRecognizer)
    {
        let bulletsNode = Bullet()
        bulletsNode.position = (self.pointOfView?.position)!
        bulletsNode.physicsBody?.applyForce(projectedDirection(pt: sender.location(in: self)), asImpulse: true)
        self.scene.rootNode.addChildNode(bulletsNode)
        bulletsNode.runAction(SCNAction.sequence([SCNAction.playAudio(SCNAudioSource(fileNamed: "pew.wav")!, waitForCompletion: false), SCNAction.wait(duration: 3), SCNAction.removeFromParentNode()]))
    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)
    {
        let bullet = contact.nodeA.name == "bullet" ? contact.nodeA : contact.nodeB
        let cube = contact.nodeA.name == "bullet" ? contact.nodeB : contact.nodeA
        
        bullet.removeFromParentNode()
        cube.runAction(SCNAction.sequence([SCNAction.playAudio(SCNAudioSource(fileNamed: "explosion.wav")!, waitForCompletion: true), SCNAction.removeFromParentNode()]))
        
        // go out with a blast
        let particleSystem = SCNParticleSystem(named: "fireexplosion", inDirectory: nil)
        let particleNode = SCNNode()
        particleNode.addParticleSystem(particleSystem!)
        particleNode.position = contact.contactPoint
        self.scene.rootNode.addChildNode(particleNode)
    }
}
