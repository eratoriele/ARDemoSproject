//
//  ViewController.swift
//  ARDemoScode
//
//  Created by macos on 18.01.2020.
//  Copyright © 2020 macos. All rights reserved.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    static var i = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        arView.session.delegate = self
        
        setupARView()
        
        // Tap the location to add a model to there
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:
            #selector(handleTap(recognizer:))))
        // Long press to delete an added entity
        arView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action:
            #selector(handleLongPress(recognizer:))))
        
    }
    
    func setupARView() {
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        arView.session.run(configuration)
    }
    
    // Object Interaction
    // Add an object
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        let results = arView.raycast(from: location, allowing: .existingPlaneInfinite, alignment: .horizontal)
        
        if let firstResult = results.first {
            let anchor = ARAnchor(name: "toy_robot_vintage", transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
        } else {
            print("No Surface Found")
        }
    }
    
    // Delete an object
    @objc
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: arView)
            
        if let model = arView.entity(at: location) {
            model.isEnabled = false
        }
        else {
            print("No entity found")
        }
    }
    
    func placeObject(named entityName:String , for anchor:ARAnchor) {
        // TODO: change this load to be asynch to make the app smoother
        let entity = try! ModelEntity.loadModel(named: entityName)
        
        entity.generateCollisionShapes(recursive: true)
        //self.arView.installGestures([.rotation, .translation], for: entity)
        
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        
        // Add the model and the box to the arView
        arView.scene.addAnchor(anchorEntity)
        
    }
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorName = anchor.name, anchorName == "toy_robot_vintage" {
                placeObject(named: anchorName, for: anchor)
            }
            // If a new plane is added
            else {
                guard let planeAnchor = anchor as? ARPlaneAnchor else {
                    return
                }
                
                let anchorEntity = AnchorEntity(anchor: anchor)
                
                for verts in planeAnchor.geometry.boundaryVertices {
                    let ball = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [SimpleMaterial()])
                    ball.position.x = verts.x
                    ball.position.y = verts.y
                    ball.position.z = verts.z
                    ball.name = "Balls"
                    anchorEntity.addChild(ball)
                }
                
                let mesh = MeshResource.generatePlane(width: planeAnchor.extent.x, depth: planeAnchor.extent.z)
                let material = SimpleMaterial(color: SimpleMaterial.Color.green.withAlphaComponent(0.7), isMetallic: false)
                let plane = ModelEntity(mesh: mesh, materials: [material])
                plane.position = planeAnchor.center
                plane.name = "Plane"
                
                anchorEntity.name = "Anchor for planes \(ViewController.i)"
                ViewController.i += 1
                anchorEntity.addChild(plane)
                arView.scene.addAnchor(anchorEntity)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else {
                continue
            }
            
            for ent in arView.scene.anchors {
                if ent.anchorIdentifier == anchor.identifier {
                    let ancent = ent as! AnchorEntity
                    let plane = ancent.findEntity(named: "Plane") as! ModelEntity
                    plane.position = planeAnchor.center
                    plane.model = ModelComponent(
                        mesh: MeshResource.generatePlane(width: planeAnchor.extent.x, depth: planeAnchor.extent.z),
                        materials: [SimpleMaterial(color: SimpleMaterial.Color.green.withAlphaComponent(0.7), isMetallic: false)])
                    
                    for verts in planeAnchor.geometry.boundaryVertices {
                        let ball = ancent.findEntity(named: "Balls") as! ModelEntity
                        ball.position.x = verts.x
                        ball.position.y = verts.y
                        ball.position.z = verts.z
                    }
                    
                }
            }
            
        }
    }
    
}
