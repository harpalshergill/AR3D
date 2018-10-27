/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.
*/

import UIKit
import SceneKit

var firstTouchedObject1: VirtualObject?

extension ViewController: UIPopoverPresentationControllerDelegate {
    
    enum SegueIdentifier: String {
        case showSettings
        case showObjects
    }
    
    enum FilterMode:Float {
        case tiny = 0.0
        case medium = 5.0
        case real = 10.0
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        //print("slider scale function enter")
        let currentValue = Float(sender.value)
        //print(currentValue)
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                if node.name == "SketchUp"{
                    //print(currentValue)
                    if(currentValue < 0.006)
                    {
                        //let currentValue = Float(0.0001)
                        //node.scale = SCNVector3(x: currentValue, y: currentValue, z: currentValue)
                        node.position = SCNVector3(x: 0, y: 0, z: 0)
                    }
                    else if(currentValue >= 0.006 && currentValue < 0.015){
                        node.position = SCNVector3(x: 0, y: -0.5, z: -0.5)
                    }
                    else if(currentValue >= 0.015 && currentValue < 0.02){
                        node.position = SCNVector3(x: 0, y: -1, z: -1)
                    }

                    
                    node.scale = SCNVector3(x: currentValue, y: currentValue, z: currentValue)

                }
            }
        }
        //print("slider scale function exit")
    }
    
    
    @IBAction func scaleObject(_ button: UIButton) {
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                if node.name == "SketchUp"{
                    node.scale = SCNVector3(x: 0.0001, y: 0.0001, z: 0.0001)
                }
            }
        }
    }
    
    @IBAction func chooseObject(_ button: UIButton) {
        // Abort if we are about to load another object to avoid concurrent modifications of the scene.
        if isLoadingObject { return }
        textManager.cancelScheduledMessage(forType: .contentPlacement)
        performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: button)
    }
    
    /// - Tag: restartExperience
    @IBAction func restartExperience(_ sender: Any) {
        guard restartExperienceButtonIsEnabled, !isLoadingObject else { return }
        
        DispatchQueue.main.async {
            self.restartExperienceButtonIsEnabled = false
            
            self.scaleSlider.value = 0.03
            
            self.textManager.cancelAllScheduledMessages()
            self.textManager.dismissPresentedAlert()
            self.textManager.showMessage("STARTING A NEW SESSION")
            
            //self.sceneView.scene = nil
            self.virtualObjectManager.removeAllVirtualObjects()
            self.addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
            self.addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
            self.focusSquare?.isHidden = true
            
            self.resetTracking()
            
            self.restartExperienceButton.setImage(#imageLiteral(resourceName: "restart"), for: [])
            
            // Show the focus square after a short delay to ensure all plane anchors have been deleted.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.setupFocusSquare()
            })
            
            // Disable Restart button for a while in order to give the session enough time to restart.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                self.restartExperienceButtonIsEnabled = true
            })
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // All popover segues should be popovers even on iPhone.
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceRect = button.bounds
        }
        
        guard let identifier = segue.identifier, let segueIdentifer = SegueIdentifier(rawValue: identifier) else { return }
        if segueIdentifer == .showObjects, let objectsViewController = segue.destination as? VirtualObjectSelectionViewController {
            objectsViewController.delegate = self
        }
    }
    
}
