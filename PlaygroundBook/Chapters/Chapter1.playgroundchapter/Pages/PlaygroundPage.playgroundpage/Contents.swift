//#-hidden-code
//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  The Swift file containing the source code edited by the user of this playground book.
//
//#-end-hidden-code

/*:
 # **Hi and welcome to my playground for WWDC 2019!**
 
 For my submission, I utilized the ARKit framework to create an interactive augmented reality game, called Your Floor is Lava!
 My submission is inspired by the game [The Floor is Lava](https://en.wikipedia.org/wiki/The_floor_is_lava), where players pretend that their floor is lava and try to keep their feet off the ground.
 In this playground, your floor actually is lava 🌋.
 
 * callout(To get started:):
 Execute the code and point the camera to a plane. When it has found the plane, press the 🔥 to heat the room up and start the game!
 
 * callout(Game objective:):
 The objective of the game is to score by extinguishing (hitting) the cubes that are falling down as soon as possible with your water cannon. When these cubes hit the lava, they automatically explode after three seconds. Each round of the game lasts for **60 seconds**.
 
 You get **two points** if you extinguish a cube before it hits the lava. Extinguishing a cube after it hit the lava will result in **one point**.
 
  - - -
 **Good luck and have fun!**
 
 */

//#-hidden-code
import Foundation
import PlaygroundSupport
import UIKit

PlaygroundPage.current.needsIndefiniteExecution = true

if #available(iOS 11.0, *) {
    let game = ExplodingCubesView(frame: CGRect(x:0, y:0, width: 512, height:768))
    PlaygroundPage.current.liveView = game
}
//#-end-hidden-code
