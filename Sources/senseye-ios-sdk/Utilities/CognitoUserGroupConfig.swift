//
//  File.swift
//  
//
//  Created by Deepak Kumar on 10/31/22.
//

import Foundation

struct CognitoUserGroup {
    let groupId: String
    let isDebugEligibile: Bool
}

class CognitoUserGroupConfig {

    let userGroups: [CognitoUserGroup] = [CognitoUserGroup(groupId: "senseye_user_group", isDebugEligibile: true)]
    
    func userGroupForGroupId(groupId: String) -> CognitoUserGroup? {
        return userGroups.first { userGroup in
            userGroup.groupId == groupId
        }
    }
    
}
