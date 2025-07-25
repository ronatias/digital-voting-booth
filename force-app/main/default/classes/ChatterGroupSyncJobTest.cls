@isTest
private class ChatterGroupSyncJobTest {

    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testusr',
            Email = 'testuser_' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser_' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        return u;
    }

    private static CollaborationGroup createChatterGroup(String name) {
        CollaborationGroup cg = new CollaborationGroup(
            Name = name,
            CollaborationType = 'Public'
        );
        insert cg;
        return cg;
    }

    @isTest
    static void testInsertSyncCreatesPublicGroupAndAddsMember() {
        User u = createTestUser();
        CollaborationGroup cg = createChatterGroup('Chatter Group Insert Test');

        // Prepare the sync item
        List<ChatterGroupSyncJob.SyncItem> items = new List<ChatterGroupSyncJob.SyncItem>{
            new ChatterGroupSyncJob.SyncItem(cg.Id, u.Id, true)
        };

        Test.startTest();
        System.enqueueJob(new ChatterGroupSyncJob(items));
        Test.stopTest();

        // Assert: Public group was created
        Group g = [SELECT Id, Name FROM Group WHERE Name = :cg.Name AND Type = 'Regular' LIMIT 1];
        System.assertNotEquals(null, g, 'Public group should be created');

        // Assert: User is a member of the public group
        List<GroupMember> gms = [SELECT Id FROM GroupMember WHERE GroupId = :g.Id AND UserOrGroupId = :u.Id];
        System.assertEquals(1, gms.size(), 'User should be added to public group');
    }
}
