public with sharing class LeaveRequestController {
    
    @AuraEnabled(cacheable=true)
    public static List<LeaveRequest__c> getMyLeaves() {
        try {
            // Check if user has access to LeaveRequest object
            if (!Schema.sObjectType.LeaveRequest__c.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access Leave Requests');
            }
            
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1];
            
            // Fetch all leaves if user is manager or admin
            if (currentUser.Profile.Name.contains('Manager') || currentUser.Profile.Name == 'System Administrator') {
                return [
                    SELECT Id, Name, From_Date__c, To_Date__c, Reason__c, 
                           Status__c, User__c, Manager_Comment__c, CreatedDate
                    FROM LeaveRequest__c 
                    ORDER BY CreatedDate DESC
                ];
            } else {
                // Return only leaves owned by current user otherwise
                return [
                    SELECT Id, Name, From_Date__c, To_Date__c, Reason__c, 
                           Status__c, User__c, Manager_Comment__c, CreatedDate
                    FROM LeaveRequest__c 
                    WHERE User__c = :currentUserId
                    ORDER BY CreatedDate DESC
                ];
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching leave requests: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String saveLeaveRequest(LeaveRequest__c leaveRequest) {
        try {
            // Check permissions
            if (!Schema.sObjectType.LeaveRequest__c.isCreateable()) {
                throw new AuraHandledException('Insufficient permissions to create Leave Requests');
            }
            
            if (leaveRequest.User__c == null) {
                leaveRequest.User__c = UserInfo.getUserId();
            }
            
            if (String.isBlank(leaveRequest.Id)) {
                leaveRequest.Status__c = 'Pending';
            }
            
            if (leaveRequest.From_Date__c == null || leaveRequest.To_Date__c == null) {
                throw new AuraHandledException('From Date and To Date are required.');
            }
            
            if (leaveRequest.From_Date__c > leaveRequest.To_Date__c) {
                throw new AuraHandledException('From Date cannot be after To Date.');
            }
            
            if (leaveRequest.From_Date__c < Date.today()) {
                throw new AuraHandledException('From Date cannot be in the past.');
            }
            
            upsert leaveRequest;
            return leaveRequest.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving leave request: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateLeaveStatus(String recordId, String status, String comment) {
        try {
            // Check permissions
            if (!Schema.sObjectType.LeaveRequest__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient permissions to update Leave Requests');
            }
            
            LeaveRequest__c leaveRequest = [
                SELECT Id, Status__c, Manager_Comment__c 
                FROM LeaveRequest__c 
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            leaveRequest.Status__c = status;
            leaveRequest.Manager_Comment__c = comment;
            
            update leaveRequest;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating leave status: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LeaveRequest__c> getLeaveRequestsForApproval() {
        try {
            if (!Schema.sObjectType.LeaveRequest__c.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access Leave Requests');
            }
            
            return [
                SELECT Id, Name, From_Date__c, To_Date__c, Reason__c, 
                       Status__c, User__c, User__r.Name, Manager_Comment__c, CreatedDate
                FROM LeaveRequest__c 
                WHERE Status__c = 'Pending'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching leave requests for approval: ' + e.getMessage());
        }
    }
}
