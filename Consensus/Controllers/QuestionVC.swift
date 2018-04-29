//
//  QuestionVC.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/28/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import UIKit
import Parse

extension QuestionVC : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        saveRightButton = navigationItem.rightBarButtonItem
        let b = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneHit(_:)))
        navigationItem.rightBarButtonItem = b
        
        if textView.text == "Your Question" {
            textView.text = ""
            textView.textColor = .black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Your Question"
            textView.textColor = .lightGray
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
    }
    
    @objc func doneHit(_ item:UIBarButtonItem) {
        navigationItem.rightBarButtonItem = saveRightButton
        questionTV.resignFirstResponder()
        if showInvite {
            showInvite = false
        }
    }
}


class AnswerCell : UITableViewCell {
    
}

extension QuestionVC : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return answers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnswerCell", for: indexPath) as! AnswerCell
        
        let a = answers[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = a.text
        
        return cell
    }
}

extension QuestionVC : UITableViewDelegate {
    
}

protocol QuestionVCDelegate : class {
    func createdQuestion(question:Question)
    func questionDone()
}

enum Method : String {
    case Majority, Plurality, Half, TwoThirds, ThreeQuarters, Unanimous, Preferrential
    static var allValues : [Method] = [.Majority, .Plurality, .Half, .TwoThirds, .ThreeQuarters, .Unanimous, .Preferrential]
}

class QuestionVC: UIViewController {

    weak var delegate : QuestionVCDelegate?
    var isNew = false
    var question : Question?
    private var answers = [Answer]()
    private var method : Method = .Majority
    private var invites = [CUser]()
    
    private var saveRightButton : UIBarButtonItem?
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBAction func saveHit(_ sender: UIBarButtonItem) {
        if isNew {
            let ac = UIAlertController(title: "Consensus Method", message: nil, preferredStyle: .actionSheet)
            for v in Method.allValues {
                ac.addAction(UIAlertAction(title: v.rawValue, style: .default, handler: { action in
                    self.method = v
                    let q = Question()
                    q.text = self.questionTV.text
                    q.user = CUser.current()
                    q.saveInBackground { success,error in
                        if success {
                            for a in self.answers {
                                a.question = q
                                a.saveInBackground()
                            }
                        }
                    }
                    self.delegate?.createdQuestion(question: q)
                }))
            }
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(ac, animated: true, completion: nil)
        } else {
            
        }
    }
    
    var showInvite = false {
        didSet {
            if showInvite {
                inviteViewHeightConstraint.constant = view.bounds.size.height * 0.75
                saveRightButton = navigationItem.rightBarButtonItem
                let b = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneHit(_:)))
                navigationItem.rightBarButtonItem = b
            } else {
                inviteViewHeightConstraint.constant = 0
            }
            UIView.animate(withDuration: 0.4, animations: { self.view.layoutIfNeeded() })
        }
    }
    @IBOutlet weak var inviteView: UIView!
    @IBOutlet weak var inviteViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inviteSV: UIScrollView!
    @IBOutlet weak var inviteButton: UIBarButtonItem!
    var didPopulateInvite = false
    @IBAction func inviteHit(_ sender: UIBarButtonItem) {
        if inviteSV == nil || invites.count == 0 { return }

        if !didPopulateInvite {
            for (i,p) in invites.enumerated() {
                let y : CGFloat = CGFloat(i * 50 + 10)
                let b = CheckButton(frame: CGRect(x: 10, y: y, width: 40, height: 40))
                b.tag = 10+i
                b.addTarget(self, action: #selector(checkButtonHit(_:)), for: .touchUpInside)
                b.isChecked = p.invited
                inviteSV.addSubview(b)
                let l = UILabel(frame: CGRect(x: 60, y: y, width: inviteSV.bounds.size.width - 50, height: 40))
                l.font = UIFont.systemFont(ofSize: 24)
                l.textColor = .white
                l.text = p.username
                inviteSV.addSubview(l)
            }
            inviteSV.contentSize = CGSize(width: inviteSV.bounds.size.width, height: CGFloat(invites.count * 50 + 20))
        }
        didPopulateInvite = true

        showInvite = true
        
        /*
        let ac = UIAlertController(title: nil, message: "Invite Contacts", preferredStyle: .actionSheet)
        for v in invites {
            ac.addAction(UIAlertAction(title: v.username, style: .default, handler: { action in
                
            }))
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
         */
    }
    @objc func checkButtonHit(_ b:CheckButton) {
        b.isChecked = !b.isChecked
        invites[b.tag - 10].invited = b.isChecked
    }

    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.layer.cornerRadius = 8
            tableView.layer.masksToBounds = true
            tableView.layer.borderColor = UIColor.lightGray.cgColor
            tableView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var questionTV: UITextView! {
        didSet {
            questionTV.layer.cornerRadius = 8
            questionTV.layer.masksToBounds = true
            questionTV.layer.borderColor = UIColor.lightGray.cgColor
            questionTV.layer.borderWidth = 1
        }
    }
    
    @IBAction func addHit(_ sender: UIBarButtonItem) {
        let ac = UIAlertController(title: "Answer", message: nil, preferredStyle: .alert)
        ac.addTextField(configurationHandler: { tf in
            tf.placeholder = "Answer Text"
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            guard let text = ac.textFields?[0].text else { return }
            let ans = Answer()
            ans.text = text
            self.answers.append(ans)
            self.tableView.reloadData()
        }))
        present(ac, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        inviteButton.isEnabled = isNew
        invites = [
            makeUser(name: "Payal", index: 0),
            makeUser(name: "Andrew", index: 1),
            makeUser(name: "Shawn", index: 2),
            makeUser(name: "Randall", index: 3),
            makeUser(name: "David", index: 4),
            makeUser(name: "Justin", index: 5)
        ]
        
        if let qu = question {
            questionTV.text = qu.text
            questionTV.textColor = .black
            let q = Answer.query()!
            q.whereKey("question", equalTo: qu)
            q.findObjectsInBackground { objects, error in
                guard let ans = objects as? [Answer] else { return }
                self.answers = ans
                self.tableView.reloadData()
            }
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func makeUser(name:String,index:Int) -> CUser {
        let u = CUser(withoutDataWithObjectId: "\(index)")
        u.username = name
        return u
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
