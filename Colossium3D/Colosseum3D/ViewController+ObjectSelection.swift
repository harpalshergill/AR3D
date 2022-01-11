//
//  ViewController+ObjectSelection.swift
//  Colosseum3D
//
//  Created by Harpal Shergill on 10/28/18.
//  Copyright © 2018 harpalshergill. All rights reserved.
//
/*
Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import ARKit

extension ViewController: VirtualObjectSelectionViewControllerDelegate {
    /**
     Adds the specified virtual object to the scene, placed at the world-space position
     estimated by a hit test from the center of the screen.
     
     - Tag: PlaceVirtualObject
     */
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        //print(focusSquare.state)
        guard focusSquare.state != .initializing else {
            //print("1")
            statusViewController.showMessage("CANNOT PLACE OBJECT\nRefresh and try again.")
            if let controller = objectsViewController {
                //print("2")
                virtualObjectSelectionViewController(controller, didDeselectObject: virtualObject)
            }
            return
        }
        
        virtualObjectInteraction.translate(virtualObject, basedOn: screenCenter, infinitePlane: false, allowAnimation: false)
        virtualObjectInteraction.selectedObject = virtualObject
        
        updateQueue.async {
            //self.sceneView.scene.rootNode.cleanup()
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
        
        segmentControl.isHidden = false
    }
    
    func placeVirtualObjectAtLoad(_ virtualObject: VirtualObject) {
        
        virtualObjectInteraction.translate(virtualObject, basedOn: screenCenter, infinitePlane: false, allowAnimation: false)
        virtualObjectInteraction.selectedObject = virtualObject
        
        updateQueue.async {
            //self.sceneView.scene.rootNode.cleanup()
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
        
        segmentControl.isHidden = false
    }
    
    
    
    func RecoverplaceVirtualObjectForced(_ virtualObject: VirtualObject) {
        guard focusSquare.state != .initializing else {
            statusViewController.showMessage("CANNOT PLACE OBJECT\nRefresh and try again.")
            if let controller = objectsViewController {
                virtualObjectSelectionViewController(controller, didDeselectObject: virtualObject)
            }
            return
        }
        
        virtualObjectInteraction.translate(virtualObject, basedOn: screenCenter, infinitePlane: false, allowAnimation: false)
        virtualObjectInteraction.selectedObject = virtualObject
        print(virtualObject.modelName)
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObject object: VirtualObject) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            self.sceneView.prepare([object], completionHandler: { _ in
                DispatchQueue.main.async {
                    self.hideObjectLoadingUI()
                    self.segmentControl.selectedSegmentIndex = 0
                    self.placeVirtualObject(loadedObject)
                    loadedObject.isHidden = false
                }
            })
        })
        
        displayObjectLoadingUI()
    }
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObject object: VirtualObject) {
        guard let objectIndex = virtualObjectLoader.loadedObjects.firstIndex(of: object) else {
            fatalError("Programmer error: Failed to lookup virtual object in scene.")
        }
        virtualObjectLoader.removeVirtualObject(at: objectIndex)
        virtualObjectInteraction.selectedObject = nil
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
    }
    
    // MARK: Object Loading UI
    
    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        
        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }
    
    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        
        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}
