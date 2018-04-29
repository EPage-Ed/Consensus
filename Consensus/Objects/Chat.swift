//
//  Chat.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/29/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import Foundation
import Parse

class Chat : PFObject {
    @NSManaged var question : Question!
    @NSManaged var user : String!
    @NSManaged var name : String!
    @NSManaged var message : String!
}

extension Chat: PFSubclassing {
    static func parseClassName() -> String {
        return "Chat"
    }
}
