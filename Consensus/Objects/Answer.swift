//
//  Answer.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/28/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import Foundation
import Parse

class Answer : PFObject {
    @NSManaged var question : Question!
    @NSManaged var text : String!
}

extension Answer: PFSubclassing {
    static func parseClassName() -> String {
        return "Answer"
    }
}
