import ARKit

public class ExplodingCube
{
    var node: SCNNode
    var duration: Double
    var updateTimer: Timer!
    var ticks = 0
    
    public init()
    {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        self.node = SCNNode(geometry: box)
        self.duration = 20
        
        // start timer
        self.updateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateColor), userInfo: nil, repeats: true)
        
        // play music
        let musicSource = SCNAudioSource(fileNamed: "tickingbomb.wav")!
        musicSource.volume = 0.08
        self.node.runAction(SCNAction.repeatForever(SCNAction.playAudio(musicSource, waitForCompletion: true)))
    }
    
    @objc
    func updateColor()
    {
        ticks += 1
        let timeLeft = self.duration - Double(ticks) * 0.2
        let n = 100 - (timeLeft / self.duration * 100)
        let red = (255 * n) / 100
        let green = (255 * (100 - n)) / 100
        
        node.geometry?.firstMaterial?.diffuse.contents = UIColor(red: CGFloat(red / 255.0), green: CGFloat(green / 255.0), blue: CGFloat(0), alpha: 1.0)
    }
    
    
}
