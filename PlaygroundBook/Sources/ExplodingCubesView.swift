import ARKit
import Foundation
import UIKit

@available(iOS 11.0, *)
public class ExplodingCubesView: ARSCNView, ARSCNViewDelegate, SCNPhysicsContactDelegate
{
    var tracking = true
    var foundSurface = false
    var trackerNode: SCNNode?
    
    public override init(frame: CGRect, options: [String : Any]? = nil)
    {
        super.init(frame: frame, options: options)
        
        let scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        self.scene = scene
        self.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        self.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints];
        
        self.session.run(configuration)
        
        // listen for taps
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ExplodingCubesView.viewTapped(sender: )))
        self.addGestureRecognizer(recognizer)
        
        // add cube
        //let cube = ExplodingCube()
        //cube.node.position = SCNVector3(floatBetween(-0.5, and: 0.5), floatBetween(-0.5, and: 0.5), floatBetween(-0.5, and: 0.5))
        //scene.rootNode.addChildNode(cube.node)
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
        let particleSystem = SCNParticleSystem(named: "explosion", inDirectory: nil)
        let particleNode = SCNNode()
        particleNode.addParticleSystem(particleSystem!)
        particleNode.position = contact.contactPoint
        self.scene.rootNode.addChildNode(particleNode)
    }
    
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        if let planeAnchor = anchor as? ARPlaneAnchor
        {
            self.addPlane(node: node, anchor: planeAnchor)
        }
    }
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor)
    {
        let plane = Plane(anchor)
        node.addChildNode(plane)
    }
    
//    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
//    {
//        guard tracking else { return }
//        let hitTest = self.hitTest(CGPoint(x: self.frame.midX, y: self.frame.midY), types: .featurePoint)
//        guard let result = hitTest.first else { return }
//        let translation = SCNMatrix4(result.worldTransform)
//        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43)
//
//        if trackerNode == nil {
//            let plane = SCNPlane(width: 0.15, height: 0.15)
//            plane.firstMaterial?.diffuse.contents = UIImage(named: "tracker.png")
//            plane.firstMaterial?.isDoubleSided = true
//            trackerNode = SCNNode(geometry: plane)
//            trackerNode?.eulerAngles.x = -.pi * 0.5
//            self.scene.rootNode.addChildNode(self.trackerNode!)
//            foundSurface = true
//        }
//        self.trackerNode?.position = position
//    }
}
