//
//  ViewController.swift
//  Color Detector
//
//  Created by Matthew O'Meara on 1/13/21.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var segueTestField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func segueButtonPressed(_ sender: Any){
        performSegue(withIdentifier: "goToRealTimeVC", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToRealTimeVC" {
            guard let vc = segue.destination as? RealTimeViewController else {
                return
            }
            vc.modalPresentationStyle = .fullScreen
            
        }
    }
    



}


