//
//  ViewController.swift
//  Colosseum3D
//
//  Created by Harpal Shergill on 10/28/18.
//  Copyright © 2018 harpalshergill. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    @IBAction func indexChange(_ sender: UISegmentedControl) {
        var scale = 0.0
        var positiony = 0.0
        switch segmentControl.selectedSegmentIndex
        {
        case 0:
            scale = 0.03
            positiony = -1.5
        case 1:
            scale = 0.01
            positiony = 0
        case 2:
            scale = 0.001
            positiony = 0
        default:
            scale = 0.001
            positiony = -1.5
            break
        }
        
        //print(self.virtualObjectLoader.loadedObjects[0].modelName)
        updateQueue.async {
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                if node.name == "SketchUp"{
                    
                    let obj = self.virtualObjectLoader.loadedObjects
                    
                    switch(obj[0].modelName){
                    case "Colosseum":
                        if(scale == 0.01){
                            node.scale = SCNVector3(x: Float(0.001), y: Float(0.001), z: Float(0.001))
                            node.position = SCNVector3(0.0, positiony, 0.0)
                        }
                        else if (scale == 0.001){
                            node.scale = SCNVector3(x: Float(0.0002), y: Float(0.0002), z: Float(0.0002))
                            node.position = SCNVector3(0.0, positiony, 0.0)
                        } else{
                            node.scale = SCNVector3(x: Float(scale), y: Float(scale), z: Float(scale))
                            node.position = SCNVector3(0.0, -1.0, 0.0)
                        }
                    case "RomanForum":
                        if(scale == 0.01){
                            node.scale = SCNVector3(x: Float(scale), y: Float(scale), z: Float(scale))
                            node.position = SCNVector3(-50.0, -2.0, 50.0)
                        }
                        else if (scale == 0.001){
                            node.scale = SCNVector3(x: Float(scale), y: Float(scale), z: Float(scale))
                            node.position = SCNVector3(-10.0, -2.0, 10.0)
                        } else{
                            node.scale = SCNVector3(x: Float(scale), y: Float(scale), z: Float(scale))
                            node.position = SCNVector3(-250.0, -1.0, 210.0)
                        }
                    default:
                        node.scale = SCNVector3(x: Float(scale), y: Float(scale), z: Float(scale))
                        node.position = SCNVector3(0.0, -1.0, 0.0)
                        break;
                    }
                    
                    //print(obj[0].modelName)
                    
                }
            }
        }
        
    }
    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    
    var vObject = [VirtualObject]()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// The view controller that displays the virtual object selection menu.
    var objectsViewController: VirtualObjectSelectionViewController?
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "theshergill.com.Colosseum3D.v2.serialSceneKitQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        self.segmentControl.isHidden = true
        
        // Set up scene content.
        setupCamera()
        //sceneView.scene.rootNode.addChildNode(focusSquare)
        
        let obj = VirtualObject.findObject("colosseum")
        loadme(object: obj!)

        sceneView.setupDirectionalLighting(queue: updateQueue)
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)
    }
    
//    deinit {
//        print("deinit")
//    }
    
    func loadme(object: VirtualObject){
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            self.sceneView.prepare([object], completionHandler: { _ in
                DispatchQueue.main.async {
                    self.hideObjectLoadingUI()
                    self.segmentControl.selectedSegmentIndex = 0
                    self.placeVirtualObjectAtLoad(loadedObject)
                    loadedObject.isHidden = false
                }
            })
        })
        
        displayObjectLoadingUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the `ARSession`.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    // MARK: - Scene content setup
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
        virtualObjectInteraction.selectedObject = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal] //, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }
    
    // MARK: - Focus Square
    
    func updateFocusSquare(isObjectVisible: Bool) {
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // Perform hit testing only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let result = self.sceneView.smartHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
            }
            addObjectButton.isHidden = false
            statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
        }
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
