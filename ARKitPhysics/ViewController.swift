//
//  ViewController.swift
//  ARKitPhysics
//
//  Created by Jayven Nhan on 12/24/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var planeNodes = [SCNNode]()
    var longPressGestureRecognizer = UILongPressGestureRecognizer()
    var tapGestureRecognizer = UITapGestureRecognizer()
    var ballNode : SCNNode!
    
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
    
    
    
    // TODO: Create add swipe gestures to scene view method
    func addLongPressGesturesToSceneView() {

        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.applyForceToBall(withGestureRecognizer:)))
        self.longPressGestureRecognizer.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(self.longPressGestureRecognizer)
    }
    
    //******************************************************************* Add scene **********************************

    @objc func addBallToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else { return }

        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y + 0.1
        let z = translation.z

         let golfScene = SCNScene(named: "ball.scn")
            ballNode  = golfScene!.rootNode.childNode(withName: "ball", recursively: false)
//            else { return }

        ballNode.position = SCNVector3(x,y,z)
        
        
//This will test the force on the ball
//        guard let physicsBody = ballNode.physicsBody
//        else { return }
//        // 4
//        let direction = SCNVector3(0, 0 , -1)
//        physicsBody.applyForce(direction, asImpulse: true)
//
        ballNode.name = ballNodeName
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    //*********************************************************************** create rocketship node ****************************
    
    // TODO: Get ball node from long press location method
    func getBallNode(from longPressLocation: CGPoint) -> SCNNode? {
        let hitTestResults = sceneView.hitTest(longPressLocation)
        print("Got location")
        guard let parentNode : SCNNode = hitTestResults.first?.node.parent,
            parentNode == ballNode
            else { return nil }
        
        dump(parentNode)
        print("Got parent node")
        return parentNode
    }
    
    //*******************************************************************************************************************************

    // TODO: Apply force to ball method
    @objc func applyForceToBall(withGestureRecognizer recognizer: UIGestureRecognizer) {
        // 1
        print("Got the long press")
        let longPressLocation = recognizer.location(in: sceneView)
        // 3
        guard let ballNode = getBallNode(from: longPressLocation),
            let physicsBody = ballNode.physicsBody
            else { return }
        // 4
        let direction = SCNVector3(0, 0, -1)
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
