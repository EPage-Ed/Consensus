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
        if tableView == chatTV { return chats.count }
        return answers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == chatTV {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
            let chat = chats[indexPath.row]
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = chat.message
            let bot = "\(chat.name!) @ \(df.string(from: chat.createdAt!))"
            cell.detailTextLabel?.text = bot
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "AnswerCell", for: indexPath) as! AnswerCell
        
        let a = answers[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = a.text
        cell.textLabel?.backgroundColor = .clear
        cell.detailTextLabel?.text = "\(a.voteCount.intValue)"
        cell.detailTextLabel?.backgroundColor = .clear
        cell.accessoryType = myAnswer != nil && myAnswer?.objectId == a.objectId ? .checkmark : .none
        
        if winners.contains(a) {
            cell.backgroundColor = greenColor.withAlphaComponent(0.5)
        } else {
            cell.backgroundColor = .clear
        }
        
        return cell
    }
}

extension QuestionVC : UITableViewDelegate {
    func doVote(ans:Answer,indexPaths:[IndexPath]) {
        ans.incrementKey("voteCount")
        myAnswer = ans
        let v = Vote()
        v.answer = ans
        v.question = question
        v.rank = 0
        v.user = AppDelegate.authUserIdent
        v.saveInBackground()
        myVote = v
        tableView.reloadRows(at: indexPaths, with: .fade)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == chatTV { return }
        
        tableView.deselectRow(at: indexPath, animated: false)
        if !isNew {
            let ans = answers[indexPath.row]
            if myAnswer != nil {
                if myAnswer?.objectId != ans.objectId {
                    let ac = UIAlertController(title: "Change Vote?", message: nil, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                    ac.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                        let oldRow = self.answers.index(where: {$0.objectId == self.myAnswer?.objectId})
//                        self.myAnswer?.incrementKey("voteCount", byAmount: -1)
                        self.myAnswer?.voteCount = NSNumber(value: (self.myAnswer?.voteCount?.intValue ?? 1) - 1)
                        self.myAnswer?.saveInBackground()
                        self.myAnswer = nil
                        self.myVote?.deleteInBackground()
                        self.myVote = nil
                        if let old = oldRow {
                            let ip = IndexPath(row: old, section: 0)
                            self.doVote(ans: ans, indexPaths: [ip,indexPath])
                        } else {
                            self.doVote(ans: ans, indexPaths: [indexPath])
                        }
                    }))
                    present(ac, animated: true, completion: nil)
                } else {
                    
                }
            } else {
                doVote(ans: ans, indexPaths: [indexPath])
            }
        } else {
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == chatTV { return nil }
        let l = UILabel()
        l.backgroundColor = .black
        l.text = "RESOLVED"
        l.textAlignment = .center
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 24)
        return l
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == chatTV { return 0 }
        return isOpen ? 0 : 40
    }
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
    private var myAnswer : Answer?
    private var myVote : Vote?
    private var answers = [Answer]()
    private var method : Method = .Majority
    private var invites = [CUser]()
    private var chats = [Chat]()
    private var df = DateFormatter()
    
    private let greenColor = UIColor(red: 0, green: 143.0/255, blue: 0, alpha: 1)
    
    private var saveRightButton : UIBarButtonItem?
    
    @IBOutlet weak var openButton: UIBarButtonItem!
    @IBAction func openHit(_ sender: UIBarButtonItem) {
        if sender.title == "Open" {
            sender.title = "Closed"
            sender.tintColor = .red
            question?.isOpen = false
        } else {
            sender.title = "Open"
            sender.tintColor = greenColor
            question?.isOpen = true
        }
        question?.saveInBackground()
        resolveQuestion()
    }
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBAction func saveHit(_ sender: UIBarButtonItem) {
        if isNew {
            let ac = UIAlertController(title: "Consensus Method", message: nil, preferredStyle: .actionSheet)
            for v in Method.allValues {
                ac.addAction(UIAlertAction(title: v.rawValue, style: .default, handler: { action in
                    self.method = v
                    let q = Question()
                    q.text = self.questionTV.text
                    q.oktaId = AppDelegate.authUserIdent
                    q.isOpen = true
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
    private var didPopulateInvite = false
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
            ans.voteCount = 0
            self.answers.append(ans)
            self.tableView.reloadData()
        }))
        present(ac, animated: true, completion: nil)
    }
    

    private var isOpen = true
    private var winners : [Answer] = []
    func resolveQuestion() {
        defer { tableView.allowsSelection = isOpen; tableView.reloadData() }
        guard let open = question?.isOpen, !open.boolValue else { isOpen = true; winners = []; return }
        isOpen = false
        
        let max = answers.max(by: { $0.voteCount.intValue < $1.voteCount.intValue })?.voteCount.intValue
        winners = answers.filter { $0.voteCount.intValue == max }
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
            makeUser(name: "Brent", index: 5),
            makeUser(name: "Justin", index: 6),
            makeUser(name: "Ed", index: 7)
        ]
        
        df.dateStyle = .short
        df.timeStyle = .medium
        
        openButton.isEnabled = !isNew
        resolveQuestion()
        
        if let qu = question {
            openButton.isEnabled = openButton.isEnabled && qu.oktaId == AppDelegate.authUserIdent
            
            if !qu.isOpen.boolValue {
                openButton.title = "Closed"
                openButton.tintColor = .red
            }
            
            let dg = DispatchGroup()

            questionTV.text = qu.text
            questionTV.textColor = .black
            let q = Answer.query()!
            q.whereKey("question", equalTo: qu)
            dg.enter()
            q.findObjectsInBackground { objects, error in
                guard let ans = objects as? [Answer] else { return }
                self.answers = ans
                dg.leave()
            }
            
            let vq = Vote.query()!
            vq.whereKey("question", equalTo: qu)
            vq.whereKey("user", equalTo: AppDelegate.authUserIdent!)
//            vq.includeKey("answer")
            dg.enter()
            vq.getFirstObjectInBackground { obj, error in
                defer { dg.leave() }
                guard let vote = obj as? Vote else { return }
                guard let ans = vote.answer else { return }
                self.myAnswer = self.answers.first(where: {$0.objectId == ans.objectId})
                self.myVote = vote
            }
            
            let cq = Chat.query()!
            cq.whereKey("question", equalTo: qu)
            cq.order(byDescending: "createdAt")
            dg.enter()
            cq.findObjectsInBackground { objects, error in
                guard let cs = objects as? [Chat] else { return }
                self.chats = cs
                dg.leave()
            }
            
            dg.notify(queue: .main) {
                self.resolveQuestion()
                self.chatTV.reloadData()
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
    
    
    // MARK: - Chat
    
    @IBOutlet weak var chatTV: UITableView!
    
    @IBAction func addChatHit(_ sender: UIBarButtonItem) {
        let ac = UIAlertController(title: nil, message: "", preferredStyle: .alert)
        ac.addTextField(configurationHandler: { tf in
            tf.placeholder = "Your Message"
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Post", style: .default, handler: {action in
            guard let text = ac.textFields?[0].text, !text.isEmpty else { return }
            let chat = Chat()
            chat.message = text
            if let comps = AppDelegate.authUserName?.components(separatedBy: .whitespaces) {
                let fname = comps.first ?? "?"
                if comps.count > 1 {
                    let lname = String(comps[1].first ?? "?")
                    chat.name = "\(fname) \(lname)"
                } else {
                    chat.name = fname
                }
            } else {
                chat.name = AppDelegate.authUserName ?? "??"
            }
            chat.question = self.question
            chat.user = AppDelegate.authUserIdent
            chat.saveInBackground { success, error in
                self.chats.insert(chat, at: 0)
                self.chatTV.reloadData()
            }
        }))
        present(ac, animated: true, completion: nil)
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
