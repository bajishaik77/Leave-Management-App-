@isTest
public class LeaveRequestControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test user (using current user)
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create test leave requests
        List<LeaveRequest__c> testLeaves = new List<LeaveRequest__c>();
        
        testLeaves.add(new LeaveRequest__c(
            From_Date__c = Date.today().addDays(1),
            To_Date__c = Date.today().addDays(5),
            Reason__c = 'Test Vacation',
            Status__c = 'Pending',
            User__c = testUser.Id
        ));
        
        testLeaves.add(new LeaveRequest__c(
            From_Date__c = Date.today().addDays(10),
            To_Date__c = Date.today().addDays(15),
            Reason__c = 'Test Sick Leave',
            Status__c = 'Approved',
            User__c = testUser.Id,
            Manager_Comment__c = 'Approved for testing'
        ));
        
        insert testLeaves;
    }
    
    @isTest
    static void testGetMyLeaves() {
        Test.startTest();
        List<LeaveRequest__c> results = LeaveRequestController.getMyLeaves();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(2, results.size(), 'Should return 2 leave requests');
    }
    
    @isTest
    static void testSaveLeaveRequest() {
        LeaveRequest__c newLeave = new LeaveRequest__c(
            From_Date__c = Date.today().addDays(20),
            To_Date__c = Date.today().addDays(25),
            Reason__c = 'Test New Leave'
        );
        
        Test.startTest();
        String resultId = LeaveRequestController.saveLeaveRequest(newLeave);
        Test.stopTest();
        
        System.assertNotEquals(null, resultId, 'Should return an Id');
        
        LeaveRequest__c savedLeave = [SELECT Status__c, User__c FROM LeaveRequest__c WHERE Id = :resultId];
        System.assertEquals('Pending', savedLeave.Status__c, 'Status should be Pending');
        System.assertEquals(UserInfo.getUserId(), savedLeave.User__c, 'User should be current user');
    }
    
    @isTest
    static void testSaveLeaveRequestValidation() {
        LeaveRequest__c invalidLeave = new LeaveRequest__c(
            From_Date__c = Date.today().addDays(5),
            To_Date__c = Date.today().addDays(1), // Invalid: To date before From date
            Reason__c = 'Invalid Test Leave'
        );
        
        Test.startTest();
        try {
            LeaveRequestController.saveLeaveRequest(invalidLeave);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Date'), 'Should contain validation message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateLeaveStatus() {
        LeaveRequest__c testLeave = [SELECT Id FROM LeaveRequest__c LIMIT 1];
        
        Test.startTest();
        LeaveRequestController.updateLeaveStatus(testLeave.Id, 'Approved', 'Test approval');
        Test.stopTest();
        
        LeaveRequest__c updatedLeave = [
            SELECT Status__c, Manager_Comment__c 
            FROM LeaveRequest__c 
            WHERE Id = :testLeave.Id
        ];
        
        System.assertEquals('Approved', updatedLeave.Status__c, 'Status should be updated');
        System.assertEquals('Test approval', updatedLeave.Manager_Comment__c, 'Comment should be updated');
    }
    
    @isTest
    static void testGetLeaveRequestsForApproval() {
        Test.startTest();
        List<LeaveRequest__c> results = LeaveRequestController.getLeaveRequestsForApproval();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        // Should have at least 1 pending request from test data
        System.assert(results.size() >= 1, 'Should have pending requests');
    }
}
