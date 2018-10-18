//
//  ViewController.swift
//  ARET
//
//  Created by 落合裕也 on 2018/10/16.
//  Copyright © 2018年 落合裕也. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var locationManager: CLLocationManager!
    let label:UILabel! = UILabel()
    let sphere = SCNSphere(radius: 0.03)
    let pyramid = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
    var nodeA :SCNNode!
    
   
    //デバック用　名古屋駅の位置情報
    var nagoya_station:CLLocation!
    var V:Vincentry!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        
        // Create a new scene
       
      
        
        // Set the scene to the view
        
        locationManager = CLLocationManager() // インスタンスの生成
        locationManager.delegate = self // CLLocationManagerDelegateプロトコルを実装するクラスを指定する
       
    
        label.text = "ラベルのテキスト"
        label.center = self.view.center
        label.numberOfLines = 0
        label.frame = CGRect(x:150, y:200, width:300, height:400)
        self.view.addSubview(label)
        
        
        
        nodeA = SCNNode(geometry: sphere)
        nodeA.position = SCNVector3(0,0,0)
        
        sceneView.scene.rootNode.addChildNode(nodeA)
        
        
        
        //デバック用　名古屋駅の位置情報
        
         nagoya_station = CLLocation(latitude: 35.15633909391446, longitude: 136.92472466888248)
         V = Vincentry(destination:nagoya_station)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        //configuration.worldAlignment = .gravityAndHeading
        
//        func session(_ session: ARSession, didFailWithError error: Error) {
//
//            switch error._code {
//            case 102:
//                configuration.worldAlignment = .gravity
//                labe2.text = "garavity"
//                restartSession()
//            default:
//                configuration.worldAlignment = .gravityAndHeading
//                labe2.text = "garavityAndHeading"
//                restartSession()
//            }
//        }
//
//        func restartSession() {
//
//            self.sceneView.session.pause()
//
//            self.sceneView.session.run(configuration, options: [
//                .resetTracking,
//                .removeExistingAnchors])
//        }
       
        // Run the view's session
        sceneView.session.run(configuration)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       
        switch status {
        case .notDetermined:
            print("ユーザーはこのアプリケーションに関してまだ選択を行っていません")
            // 許可を求めるコードを記述する（後述）
            locationManager.requestWhenInUseAuthorization() // 起動中のみの取得許可を求める
            break
        case .denied:
            print("ローケーションサービスの設定が「無効」になっています (ユーザーによって、明示的に拒否されています）")
            // 「設定 > プライバシー > 位置情報サービス で、位置情報サービスの利用を許可して下さい」を表示する
            break
        case .restricted:
            print("このアプリケーションは位置情報サービスを使用できません(ユーザによって拒否されたわけではありません)")
            // 「このアプリは、位置情報を取得できないために、正常に動作できません」を表示する
            break
        case .authorizedAlways:
            print("常時、位置情報の取得が許可されています。")
            // 位置情報取得の開始処理
            break
        case .authorizedWhenInUse:
            print("起動時のみ、位置情報の取得が許可されています。")
            //位置情報取得の開始処理
            locationManager.distanceFilter = 1.0
            locationManager.startUpdatingLocation()
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //ここで目的地を指定
        var  Flag:Bool
        var Position:SCNVector3
        for location in locations {
            (Position ,Flag) = V.updatemyPosition(newposition: location)
            //目的地は変更不可
            if(Flag){
                nodeA.position = Position
            }
            label.text = """
            距離:\(V.distance)
            

            """
           self.createPyramid(Position: nodeA.position)
           sceneView.scene.rootNode.addChildNode(nodeA)
           
        }
    }
    //目的地までものを飛ばす
    func createPyramid(Position:SCNVector3)
    {
        let nodeB = SCNNode(geometry:pyramid )
        
        nodeB.position = SCNVector3(0,0,-0.2)
        if let material = nodeB.geometry?.firstMaterial {
            material.diffuse.contents = UIColor.red
            material.specular.contents = UIColor.red
        }
        
        let action = SCNAction.moveBy(x: CGFloat(Position.x), y:CGFloat(Position.y) , z:CGFloat(Position.z), duration:V.distance)
        nodeB.runAction(
            SCNAction.sequence([
                action,
                SCNAction.removeFromParentNode()
                ])
        )
    sceneView.scene.rootNode.addChildNode(nodeB)
    }
    
    
}
