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
    let defaultUserGroup: CognitoUserGroup = CognitoUserGroup(groupId: "app_default", isDebugEligibile: false)
    
    func userGroupForGroupId(groupId: String) -> CognitoUserGroup {
        let filteredGroup = userGroups.first { userGroup in userGroup.groupId == groupId }
        guard let knownUserGroup = filteredGroup else {
            return defaultUserGroup
        }
        return knownUserGroup
    }
    
}
