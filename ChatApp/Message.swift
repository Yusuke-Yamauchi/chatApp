//
//  Message.swift
//  ChatApp
//
//  Created by user on 2019/06/09.
//  Copyright © 2019 Yusuke Yamauchi. All rights reserved.
//

import Foundation
import MessageKit

struct Message : MessageType {
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
    
}
