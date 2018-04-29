//
//  Vote.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/29/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import Foundation
import Parse

class Vote : PFObject {
    @NSManaged var user : String!
    @NSManaged var question : Question!
    @NSManaged var answer : Answer!
    @NSManaged var rank : NSNumber!
}

extension Vote: PFSubclassing {
    static func parseClassName() -> String {
        return "Vote"
    }
}
