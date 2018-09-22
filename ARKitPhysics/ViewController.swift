//
//  ViewController.swift
//  ARKitPhysics
//
//  Created by Jayven Nhan on 12/24/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var planeNodes = [SCNNode]()
    var longPressGestureRecognizer = UILongPressGestureRecognizer()
    var tapGestureRecognizer = UITapGestureRecognizer()
    var ballNode : SCNNode!
    var ballExists = false
    
    // TODO: Declare rocketship node name constant
    let ballNodeName =  "ball"
   // let golfBallNodeName = "golfball"
    
    // TODO: Initialize an empty array of type SCNNode
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTapGestureToSceneView()
        configureLighting()
        addLongPressGesturesToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.delegate = self
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func addTapGestureToSceneView() {
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addBallToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    
    
    // Add swipe gestures to scene view method
    func addLongPressGesturesToSceneView() {
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.applyForceToBall(withGestureRecognizer:)))
        self.longPressGestureRecognizer.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(self.longPressGestureRecognizer)
    }
    
    //******************************************************************* Add ball node to scene **********************************

    @objc func addBallToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        if ballExists == false {
            let pressLocation = recognizer.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(pressLocation, types: .existingPlaneUsingExtent)
            guard let hitTestResult = hitTestResults.first else { return }
            
            let translation = hitTestResult.worldTransform.translation
            let x = translation.x
            let y = translation.y + 0.1
            let z = translation.z

            let ballScene = SCNScene(named: "ball.scn")
            ballNode  = ballScene!.rootNode.childNode(withName: "ball", recursively: false)
            ballNode.position = SCNVector3(x,y,z)
            ballNode.name = ballNodeName
            sceneView.scene.rootNode.addChildNode(ballNode)
            ballExists = true
        }
    }
    
    //*********************************************************************** get location of ball node ****************************
    
    // Get ball node from long press location method
    func getBallNode(from longPressLocation: CGPoint) -> SCNNode? {
        let hitTestResults = sceneView.hitTest(longPressLocation)
        guard let parentNode  = hitTestResults.first?.node.parent
            else { return nil }
        for child in parentNode.childNodes {
            if child.name == "ball" {
                return child
            }
        }
        return nil
    }
    
    //*************************************************************************** direction and force for ball path *********************************
    
    // Get user vector
    
    func getUserVector() -> (SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            //let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir)
        }
        return (SCNVector3(0, 0, -1))
    }

    //Apply force to ball method
    
    @objc func applyForceToBall(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let longPressLocation = recognizer.location(in: self.view)
        guard let ballNode = getBallNode(from: longPressLocation),
            let physicsBody = ballNode.physicsBody
            else { return }
        var direction = self.getUserVector()
        print(direction)
        direction.y = 0
        physicsBody.applyForce(direction, asImpulse: true)
    }
}

//****************************************************************************** Plane Detection ************************************

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        //MARK: - this is where the plane detection happens
        
        plane.materials.first?.diffuse.contents = UIColor.transparentWhite
        
        var planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // TODO: Update plane node
        update(&planeNode, withGeometry: plane, type: .static)
        
        node.addChildNode(planeNode)
        
        // TODO: Append plane node to plane nodes array if appropriate
        planeNodes.append(planeNode)
    }
    
    // TODO: Remove plane node from plane nodes array if appropriate
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor,
            let planeNode = node.childNodes.first
            else { return }
        planeNodes = planeNodes.filter { $0 != planeNode }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            var planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        planeNode.position = SCNVector3(x, y, z)

        update(&planeNode, withGeometry: plane, type: .static)
        
    }
    
    // TODO: Create update plane node method
    func update(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, type: SCNPhysicsBodyType) {
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: type, shape: shape)
        node.physicsBody = physicsBody
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentWhite: UIColor {
        return UIColor.white.withAlphaComponent(0.20)
    }
}
