@isTest
private class ChatterGroupSyncHelperTest {

    @isTest
    static void testHandleInsertAsyncAndDeleteAsync() {
        // Create test user
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert testUser;

        // Create Chatter group
        CollaborationGroup chatterGroup = new CollaborationGroup(
            Name = 'Test Group for Helper',
            CollaborationType = 'Public'
        );
        insert chatterGroup;

        // Create ChatterGroupMember
        CollaborationGroupMember groupMember = new CollaborationGroupMember(
            CollaborationGroupId = chatterGroup.Id,
            MemberId = testUser.Id
        );
        insert groupMember;
        delete  groupMember;
        
        Test.startTest();
        // Call helper methods to enqueue jobs
        ChatterGroupSyncHelper.handleInsertAsync(new List<CollaborationGroupMember>{ groupMember });
        ChatterGroupSyncHelper.handleDeleteAsync(new List<CollaborationGroupMember>{ groupMember });
        Test.stopTest();
    }
}
