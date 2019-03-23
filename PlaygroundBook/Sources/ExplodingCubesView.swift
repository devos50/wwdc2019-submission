import ARKit
import Foundation
import UIKit

protocol CubeDelegate
{
    func didExplode()
}

@available(iOS 11.0, *)
public class ExplodingCubesView: ARSCNView, ARSCNViewDelegate, SCNPhysicsContactDelegate
{
    var trackerNode: SCNNode?
    var planes = [ARPlaneAnchor: Plane]()
    var canShootBullet = true
    var bulletTimer: Timer?
    var gameTimer: Timer?
    var didStartGame = false
    var activePlane: Plane?
    var score = 0
    var gameDuration = 60
    var timeLeft: Int
    
    var timeLeftLabel: UILabel?
    var scoreLabel: UILabel?
    var findPlaneLabel: UILabel?
    var finalScoreLabel: LTMorphingLabel?
    var restartButton: UIButton?
    
    public override init(frame: CGRect, options: [String : Any]? = nil)
    {
        timeLeft = gameDuration
        super.init(frame: frame, options: options)
        
        initWorld()
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        timeLeft = gameDuration
        super.init(coder: aDecoder)
        
        initWorld()
    }
    
    func initWorld()
    {
        let scene = SCNScene()
        scene.physicsWorld.gravity = SCNVector3(x: 0, y: -0.25, z: 0)
        scene.physicsWorld.contactDelegate = self
        self.scene = scene
        self.delegate = self
        
        //self.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showPhysicsShapes];
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        self.session.run(configuration)
        
        // listen for taps
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ExplodingCubesView.viewTapped(sender: )))
        self.addGestureRecognizer(recognizer)
        
        // add labels
        self.scoreLabel = UILabel(frame: CGRect(x: self.frame.size.width - 100, y: 30, width: 100, height: 30))
        scoreLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        scoreLabel?.isHidden = true
        scoreLabel?.textColor = UIColor.white
        self.addSubview(self.scoreLabel!)
        
        self.timeLeftLabel = UILabel(frame: CGRect(x: 20, y: 30, width: self.frame.size.width - 20, height: 30))
        timeLeftLabel?.text = "Time left: \(timeLeft) sec."
        timeLeftLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        timeLeftLabel?.isHidden = true
        timeLeftLabel?.textColor = UIColor.white
        self.addSubview(self.timeLeftLabel!)
        
        self.findPlaneLabel = UILabel(frame: CGRect(x: 20, y: 20, width: self.frame.size.width - 40, height: 60))
        findPlaneLabel?.text = "Find a flat surface and shoot with your extinguisher by tapping the screen!"
        findPlaneLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        findPlaneLabel?.numberOfLines = 0
        findPlaneLabel?.lineBreakMode = .byWordWrapping
        findPlaneLabel?.textAlignment = .center
        findPlaneLabel?.textColor = UIColor.white
        self.addSubview(self.findPlaneLabel!)
        
        self.restartButton = UIButton.init(type: .custom)
        self.restartButton?.setTitle("Restart game", for: .normal)
        self.restartButton?.backgroundColor = .red
        self.restartButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        self.restartButton?.frame = CGRect(x: self.frame.size.width / 2 - 100, y: self.frame.size.height / 2 + 100, width: 200, height: 60)
        self.restartButton?.isHidden = true
        self.restartButton?.addTarget(self, action: #selector(resetWorld), for: .touchUpInside)
        self.addSubview(self.restartButton!)
        
        self.updateLabels()
    }
    
    @objc
    func resetWorld()
    {
        self.restartButton?.isHidden = true
        self.findPlaneLabel?.isHidden = false
        self.finalScoreLabel?.isHidden = true
        self.finalScoreLabel = nil
        
        self.planes = [ARPlaneAnchor: Plane]()
        
        self.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
        self.session.pause()
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        self.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.1))
    }
    
    func projectedDirection(pt: CGPoint?) -> SCNVector3
    {
        guard pt != nil else {
            return SCNVector3(0, 0, 1)
        }
        
        let farPt  = self.unprojectPoint(SCNVector3(Float(pt!.x), Float(pt!.y), 1))
        let nearPt = self.unprojectPoint(SCNVector3(Float(pt!.x), Float(pt!.y), 0))
        
        return SCNVector3((farPt.x - nearPt.x)/300, (farPt.y - nearPt.y)/300, (farPt.z - nearPt.z)/300)
    }
    
    @objc
    func viewTapped(sender: UITapGestureRecognizer)
    {
        if canShootBullet
        {
            let bulletsNode = Bullet()
            bulletsNode.position = (self.pointOfView?.position)!
            bulletsNode.physicsBody?.applyForce(projectedDirection(pt: sender.location(in: self)), asImpulse: true)
            self.scene.rootNode.addChildNode(bulletsNode)
            self.scene.rootNode.runAction(SCNAction.playAudio(SCNAudioSource(fileNamed: "pew.wav")!, waitForCompletion: false))
            bulletsNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 3), SCNAction.removeFromParentNode()]))
            self.canShootBullet = false
            bulletTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer: Timer) in
                self.canShootBullet = true
            })
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        if let planeAnchor = anchor as? ARPlaneAnchor
        {
            self.addPlane(node: node, anchor: planeAnchor)
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    {
        if let planeAnchor = anchor as? ARPlaneAnchor
        {
            self.updatePlane(anchor: planeAnchor)
        }
    }
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor)
    {
        if !self.didStartGame
        {
            let plane = Plane(anchor)
            node.addChildNode(plane.node)
            planes[anchor] = plane
        }
    }
    
    func updatePlane(anchor: ARPlaneAnchor)
    {
        if let plane = planes[anchor]
        {
            plane.update(anchor)
        }
    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)
    {
        if (contact.nodeA.name == "bullet" && contact.nodeB.name == "cube") || (contact.nodeA.name == "cube" && contact.nodeB.name == "bullet")
        {
            let bullet = contact.nodeA.name == "bullet" ? contact.nodeA : contact.nodeB
            let cube = contact.nodeA.name == "bullet" ? contact.nodeB : contact.nodeA
            
            bullet.removeFromParentNode()
            cube.parent?.runAction(SCNAction.playAudio(SCNAudioSource(fileNamed: "extinguish.wav")!, waitForCompletion: false))
            cube.removeFromParentNode()
            
            if (cube as? ExplodingCube)!.isTicking { self.score += 1 }
            else { self.score += 2 }
            self.updateLabels()
        }
        else if (contact.nodeA.name == "plane" && contact.nodeB.name == "cube") || (contact.nodeA.name == "cube" && contact.nodeB.name == "plane")
        {
            let cube = contact.nodeA.name == "plane" ? (contact.nodeB as? ExplodingCube) : (contact.nodeA as? ExplodingCube)
            if !cube!.isTicking { cube?.startTicking() }
        }
        else if (contact.nodeA.name == "plane" && contact.nodeB.name == "bullet") || (contact.nodeA.name == "bullet" && contact.nodeB.name == "plane")
        {
            let bullet = contact.nodeA.name == "bullet" ? contact.nodeA : contact.nodeB
            let hitPlane = contact.nodeA.name == "bullet" ? contact.nodeB : contact.nodeA
            
            bullet.removeFromParentNode()
            
            if(self.didStartGame) { return }
            
            // which plane did we tap?
            for (_, plane) in self.planes
            {
                if plane.node == hitPlane
                {
                    self.activePlane = plane
                    break
                }
            }
            
            if let _ = self.activePlane
            {
                // remove other planes
                for (_, plane) in self.planes
                {
                    if plane.node != self.activePlane!.node
                    {
                        plane.node.removeFromParentNode()
                        plane.fireNode.removeFromParentNode()
                    }
                }
                
                DispatchQueue.main.async {
                    self.startGame()
                }
            }
        }
    }
    
    public func startGame()
    {
        self.didStartGame = true
        self.activePlane?.startGame()
        
        // stop plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        self.session.run(configuration)
        
        self.findPlaneLabel?.isHidden = true
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timer: Timer) in
            self.scoreLabel?.isHidden = false
            self.timeLeftLabel?.isHidden = false
            
            self.gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer: Timer) in
                self.timeLeft -= 1
                self.timeLeftLabel?.text = "Time left: \(self.timeLeft) sec."
                
                if self.timeLeft == 0
                {
                    self.stopGame()
                    timer.invalidate()
                }
            })
        }
    }
    
    public func stopGame()
    {
        self.scoreLabel?.isHidden = true
        self.timeLeftLabel?.isHidden = true
        self.activePlane?.stopGame()
        self.didStartGame = false
        
        self.activePlane?.node.removeFromParentNode()
        self.activePlane = nil
        
        DispatchQueue.main.async {
            self.finalScoreLabel = LTMorphingLabel(frame: CGRect(x: 0, y: self.frame.size.height / 2 - 60, width: self.frame.size.width, height: 50))
            self.finalScoreLabel?.textAlignment = .center
            self.finalScoreLabel?.morphingEffect = .burn
            self.finalScoreLabel?.morphingDuration = 1.5
            self.finalScoreLabel?.text = "Score: \(self.score)"
            self.finalScoreLabel?.font = UIFont.boldSystemFont(ofSize: 60)
            self.finalScoreLabel?.textColor = .white
            self.addSubview(self.finalScoreLabel!)
            self.restartButton?.isHidden = false
            
            self.score = 0
            self.timeLeft = self.gameDuration
        }
    }
    
    public func updateLabels()
    {
        DispatchQueue.main.async
            {
                self.scoreLabel?.text = "Score: \(self.score)"
        }
    }
}
