//
//  Question.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/28/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import Foundation
import Parse

class Question : PFObject {
    @NSManaged var oktaId : String!
    @NSManaged var text : String!
    @NSManaged var isOpen : NSNumber!
}

extension Question: PFSubclassing {
    static func parseClassName() -> String {
        return "Question"
    }
}
