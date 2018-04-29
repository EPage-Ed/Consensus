//
//  ViewController.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/28/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import UIKit
import OktaAuth
import OktaJWT

class QuestionCell : UITableViewCell {
    
}

extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuestionCell", for: indexPath) as! QuestionCell
        
        let q = questions[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = q.text
        
        return cell
    }
}

extension ViewController : UITableViewDelegate {
    
}

class ViewController: UIViewController {
    
    var questions = [Question]()
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func doneHit(_ sender: UIBarButtonItem) {
        AppDelegate.logout { success in
            if success {
                DispatchQueue.main.async {
                    if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SplashVC") {
                        self.view.window?.rootViewController = vc
                    }
                }
            }
        }
        
        //        OktaAuth.clear()
    }
    
    @IBAction func addHit(_ sender: UIBarButtonItem) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let q = Question.query()!
        q.whereKey("user", equalTo: CUser.current()!)
        q.findObjectsInBackground { objects, error in
            guard let objs = objects as? [Question] else { return }
            self.questions = objs
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? QuestionVC else { return }
        vc.delegate = self
        if segue.identifier == "Tapped" {
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                vc.question = questions[indexPath.row]
            }

        } else if segue.identifier == "New" {
            vc.isNew = true
        }
    }
}

extension ViewController : QuestionVCDelegate {
    func createdQuestion(question: Question) {
        navigationController?.popViewController(animated: true)
        questions.insert(question, at: 0)
        tableView.reloadData()
    }
    func questionDone() {
        navigationController?.popViewController(animated: true)
    }
}

