//
//  ViewController.swift
//  AR Interaction
//
//  Created by Timur Saidov on 19.09.2018.
//  Copyright © 2018 Timur Saidov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var hoopAdded = false
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if !hoopAdded {
            let touchLocation = sender.location(in: sceneView) // Где пользователь нажал. Возвращается точка нажатия.
            
            let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent]) // Попытка пересечения луча, начинающегося оттуда, где пользователь нажал на экран (точка на экране с 2 координатами), с существующей плоскостью (учитывая ее размеры), соответствующей этому месту нажатия. Для этого нужна визуализированная плоскость. То место, где они пересекутся и будет результатом.
            print(hitTestResult)
            print("\nhitTestResult.first: \(hitTestResult.first!)")
            
            if let result = hitTestResult.first { // В массиве hitTestResult один элемент (координаты одной точки пересечения), так как каждый новый tap идет присваивание новых координат пересечения в массив. То есть не .appdend, а присваивание =
                addHoop(result: result)
                
                hoopAdded = true
                
                print("Пересеклись с поверхностью\n")
            }
        } else {
            createBall()
        }
    }
    
    func addHoop(result: ARHitTestResult) {
        let hoopScene = SCNScene(named: "art.scnassets/Hoop.scn")
        
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else { return }
        
        let position = result.worldTransform.columns.3 // Матрица, однозначно определяющая координаты объекта. В 3 колонке находятся те координаты, которые можно присвоить hoopNode, для того чтобы кольцо расположилось в том месте, где произошло пересечие луча от нажатия пользователем на экран с визуальзированной плоскостью.
        hoopNode.position = SCNVector3(position.x, position.y, position.z)
        
        sceneView.scene.rootNode.addChildNode(hoopNode)
    }
    
    func createPlane(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let width = CGFloat(planeAnchor.extent.x)
        let heigth = CGFloat(planeAnchor.extent.z)
        
        let geometry = SCNPlane(width: width, height: heigth)
        
        let planeNode = SCNNode()
        planeNode.geometry = geometry
        planeNode.opacity = 0.25
        planeNode.eulerAngles.x = -Float.pi / 2
        
        return planeNode
    }
    
    func createBall() {
        guard let currentFrame = sceneView.session.currentFrame else { return } // currentFrame необходим для того, чтобы получить текущую позицию камеры (текущую позицию, куда смотрит камера). Меняется 60 раз в секунду.
        
//        let ballNode = SCNNode()
//        let ball = SCNSphere(radius: 0.25)
//        ball.firstMaterial?.diffuse.contents = UIColor.orange
//        ballNode.geometry = ball
        
        let ballNode = SCNNode(geometry: SCNSphere(radius: 0.25))
        ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
        
        ballNode.transform = SCNMatrix4(currentFrame.camera.transform) // Матрица 4х4, однозначно определяющая положение объекта в пространстве.
        
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return } // Если произошло распознование, определяем, что за сущность распознана. Кастим ее до поверхности. Если кастится, то распознана плоскость. А помимо этого есть еще распознование объекта и картинки.
        
        print(#function, planeAnchor)
        
        let plane = createPlane(planeAnchor: planeAnchor) // Визуализация распознанной поверхности.
        
        node.addChildNode(plane) // node, переданная функции, закреплена так, где распознана поверхность, в ее центре. И в ней визуализируется поверхность. То есть planeNode совпадает с node.
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Вызывается в тот момент, когда 2 плоскости - это одна и та же плоскость, и, следовательно, они объединяются.
        guard let planeAnchor = anchor as? ARPlaneAnchor, let plane = node.childNodes.first, let geometry = plane.geometry as? SCNPlane else { return } // Берется node первой поверхности и ее геометрия, чтобы затем увеличить ее размеры до размеров объединенной плоскости anchor и позиции ее node.
        
        geometry.width = CGFloat(planeAnchor.extent.x)
        geometry.height = CGFloat(planeAnchor.extent.z)
        
        plane.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
