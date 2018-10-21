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
    let sphere = SCNSphere(radius: 0.3)
    let pyramid = SCNPyramid(width: 0.1, height: 0.1, length: 0.1)
    let plane = SCNPlane(width: 0.8, height: 0.8)
    var nodeA :SCNNode!
    var arrow :SCNNode!
    
    
    //デバック用　名古屋駅の位置情報
    var nagoya_station:CLLocation!
    var location:CLLocation!
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
        
        
        label.text = ""
        label.center = self.view.center
        label.numberOfLines = 0
        label.frame = CGRect(x:300, y:0, width:300, height:400)
        label.font = UIFont.boldSystemFont(ofSize: 90)
        self.view.addSubview(label)
        
        
        
        nodeA = SCNNode(geometry: sphere)
        nodeA.position = SCNVector3(0,0,0)
        
        //        sceneView.scene.rootNode.addChildNode(nodeA)
        
        
        
        //デバック用　名古屋駅の位置情報
        
        //        nagoya_station = CLLocation(latitude: 35.15633909391446, longitude: 136.92472466888248)
        //        V = Vincentry(destination:nagoya_station)
        
        //        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //        let lati = Double(appDelegate.latitude!)
        //        let long = Double(appDelegate.longitude!)
        //        label.text = String(lati)
        //        label.center = self.view.center
        //        label.numberOfLines = 0
        //        label.frame = CGRect(x:300, y:0, width:300, height:400)
        //        label.font = UIFont.boldSystemFont(ofSize: 90)
        self.view.addSubview(label)
        
        //        location = CLLocation(latitude: lati, longitude: long)
        //        V = Vincentry(destination:location)
        
        //サーバに接続
        SocketClient.connect()
        //map表示完了後
        SocketClient.setUpdateDestinationObserver({aLocation in
            self.nagoya_station = CLLocation(latitude: aLocation.latitude, longitude: aLocation.longitude)
            self.V = Vincentry(destination:self.nagoya_station)
        }, "updateDestination")
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
        if(nagoya_station==nil){return}
        //ここで目的地を指定
        var  Flag:Bool
        var Position:SCNVector3
        for location in locations {
            (Position ,Flag) = V.updatemyPosition(newposition: location)
            //目的地は変更不可
            if(Flag){
                nodeA.position = Position
            }
            let text = """
            \(floor(V.distance))m
            
            
            """
            // ラベルの設定
            let textAttributes: [NSAttributedString.Key : Any] = [
                .foregroundColor : UIColor(hue: 0.68, saturation: 0.49, brightness: 0.60, alpha: 1.0),
                .strokeColor : UIColor.white,
                .strokeWidth : -4.0
            ]
            label.attributedText = NSAttributedString(string: text, attributes: textAttributes)
            
            //           self.createPyramid(Position: nodeA.position)
            self.directionArrow(Position: Position)
            //           sceneView.scene.rootNode.addChildNode(nodeA)
            self.destinationSphere(Position: Position)
            
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
    //目的地まで矢印を飛ばす
    func directionArrow(Position:SCNVector3)
    {
        arrow = SCNNode(geometry: plane)
        arrow.eulerAngles = SCNVector3(-90 * (Float.pi / 180), -90 * (Float.pi / 180), 0)
        let position = SCNVector3(x: 0, y: -0.3, z: -1) // 偏差のベクトルを生成する
        if let camera = sceneView.pointOfView { // カメラを取得
            arrow.position = camera.convertPosition(position, to: nil) // カメラ位置からの偏差で求めた位置をノードの位置とする
        }
        
        //        arrow.eulerAngles = SCNVector3(x:atan((Position.x - arrow.position.x)/(Position.y - arrow.position.y )),y:Float(0),z:atan((Position.z - arrow.position.z)/(Position.y -  arrow.position.y)))
        
        if let material = arrow.geometry?.firstMaterial {
            material.diffuse.contents = UIImage(named: "direction")
            //            material.specular.contents = UIColor.red
        }
        let action2 = SCNAction.rotateBy(x:CGFloat(0),y:CGFloat(atan((Position.z - arrow.position.z)/(Position.x - arrow.position.x ))),
                                         z:CGFloat(0),
                                         duration: 0.1)
        let action = SCNAction.moveBy(x: CGFloat(Position.x), y:CGFloat(Position.y) , z:CGFloat(Position.z), duration:V.distance)
        arrow.runAction(
            SCNAction.sequence([
                action2,
                action,
                SCNAction.removeFromParentNode()
                ])
        )
        sceneView.scene.rootNode.addChildNode(arrow)
    }
    
    //目的地に球を表示する
    func destinationSphere(Position:SCNVector3)
    {
        nodeA.position = Position
        nodeA.position.y = 2.0
        if let material = nodeA.geometry?.firstMaterial {
            material.diffuse.contents = UIColor(hue: 0.11, saturation: 0.90, brightness: 1.00, alpha: 1.0)
        }
        sceneView.scene.rootNode.addChildNode(nodeA)
    }
    
}
