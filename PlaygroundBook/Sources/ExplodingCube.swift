import ARKit

public class ExplodingCube: SCNNode
{
    var updateTimer: Timer!
    var explodeTime = 3.0
    var explodeTimer: Timer!
    var ticks = 0
    var isTicking = false
    
    public init(size: CGFloat)
    {
        super.init()
        
        let box = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        self.geometry = box
        self.name = "cube"
        self.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "dynamite.jpg")
        let shape = SCNPhysicsShape(geometry: box, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.categoryBitMask = CubeCategoryBitmask
        self.physicsBody?.collisionBitMask = BulletCategoryBitmask | PlaneCategoryBitmask | CubeCategoryBitmask | WallCategoryBitmask
        self.physicsBody?.contactTestBitMask = BulletCategoryBitmask | PlaneCategoryBitmask
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startTicking()
    {
        if isTicking { return }
        
        // play music
        let musicSource = SCNAudioSource(fileNamed: "tickingbomb.wav")!
        musicSource.volume = 0.3
        self.runAction(SCNAction.repeatForever(SCNAction.playAudio(musicSource, waitForCompletion: true)))
        
        self.isTicking = true
        DispatchQueue.main.async {
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer: Timer) in
                self.ticks += 1
                let timeLeft = self.explodeTime - Double(self.ticks) * 0.1
                //let n = 100 - (timeLeft / self.explodeTime * 100)
                //let red = (255 * n) / 100
                //let green = (255 * (100 - n)) / 100
                
                let color = UIColor(hue: CGFloat(timeLeft / self.explodeTime / 3), saturation: 1, brightness: 1, alpha: 1)
                
                self.geometry?.firstMaterial?.diffuse.contents = color
            })
            
            self.explodeTimer = Timer.scheduledTimer(withTimeInterval: self.explodeTime, repeats: false, block: { (timer: Timer) in
                // go out with a blast
                self.parent?.runAction(SCNAction.playAudio(SCNAudioSource(fileNamed: "explosion.wav")!, waitForCompletion: false))
                let particleSystem = SCNParticleSystem(named: "fireexplosion", inDirectory: nil)
                let particleNode = SCNNode()
                particleNode.addParticleSystem(particleSystem!)
                particleNode.position = self.presentation.position
                self.parent?.addChildNode(particleNode)
                self.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.2), SCNAction.removeFromParentNode()]))
                self.updateTimer.invalidate()
            })
        }
    }
}
