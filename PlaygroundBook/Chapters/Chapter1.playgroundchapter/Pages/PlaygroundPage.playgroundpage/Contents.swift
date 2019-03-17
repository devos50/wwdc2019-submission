//#-hidden-code
//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  The Swift file containing the source code edited by the user of this playground book.
//
//#-end-hidden-code
import Foundation
import PlaygroundSupport
import UIKit

//#-hidden-code
if #available(iOS 11.0, *)
{
    let scene = ExplodingCubesView(frame: CGRect(x:0, y:0, width: 512, height:768))
    PlaygroundPage.current.liveView = scene
}
else
{
/*:
     This Playground requires iOS 11 and ARKit support to run :(
 */
}
//#-end-hidden-code
