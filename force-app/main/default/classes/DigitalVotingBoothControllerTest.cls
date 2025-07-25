@isTest
private class DigitalVotingBoothControllerTest {

    @testSetup
    static void setupData() {
        // Create a test party
        insert new Party__c(
            Name = 'Test Party',
            Description__c = 'A test party',
            PartyCode__c = 'TP',
            PartyLeader__c = 'Test Leader'
        );
    }

    @isTest
    static void testGetAllParties() {
        Test.startTest();
        List<Party__c> result = DigitalVotingBoothController.getAllParties();
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Expected at least one party');
        System.assertEquals('TP', result[0].PartyCode__c, 'Expected correct PartyCode');
    }

    @isTest
    static void testSubmitVote_NewVote_WithParty() {
        User testUser = createUser();
        Party__c party = [SELECT Id, PartyCode__c FROM Party__c LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            DigitalVotingBoothController.submitVote(party.Id, null);
            Test.stopTest();
        }

        List<Vote__c> votes = [SELECT Name, Party__c, BlankNote__c FROM Vote__c WHERE User__c = :testUser.Id];
        System.assertEquals(1, votes.size(), 'Vote should be created');
        System.assertEquals(party.Id, votes[0].Party__c, 'Party should be selected');
        System.assertEquals(null, votes[0].BlankNote__c, 'Blank note should be null');
        System.assertEquals('Vote - ' + party.PartyCode__c, votes[0].Name, 'Vote label should match party');
    }

    @isTest
    static void testSubmitVote_NoInput() {
        User testUser = createUser();
        System.runAs(testUser) {
            Test.startTest();
            DigitalVotingBoothController.submitVote(null, null);
            Test.stopTest();
        }
        List<Vote__c> votes = [SELECT Id FROM Vote__c WHERE User__c = :testUser.Id];
        System.assertEquals(0, votes.size(), 'No vote should be created');
    }

    @isTest
    static void testSubmitVote_NewVote_BlankNote() {
        User testUser = createUser();

        System.runAs(testUser) {
            Test.startTest();
            DigitalVotingBoothController.submitVote(null, 'Make pineapple national fruit');
            Test.stopTest();
        }

        List<Vote__c> votes = [SELECT Name, Party__c, BlankNote__c FROM Vote__c WHERE User__c = :testUser.Id];
        System.assertEquals(1, votes.size(), 'Vote should be created');
        System.assertEquals(null, votes[0].Party__c, 'Party should be blank');
        System.assertEquals('Make pineapple national fruit', votes[0].BlankNote__c, 'Expected blank note');
        System.assertEquals('Vote - Blank', votes[0].Name, 'Vote label should be "Vote - Blank"');
    }

    @isTest
    static void testSubmitVote_UpdateExisting() {
        User testUser = createUser();
        Party__c party = [SELECT Id, PartyCode__c FROM Party__c LIMIT 1];

        System.runAs(testUser) {
            DigitalVotingBoothController.submitVote(null, 'Initial note');
        }

        System.runAs(testUser) {
            Test.startTest();
            DigitalVotingBoothController.submitVote(party.Id, null);
            Test.stopTest();
        }

        List<Vote__c> votes = [SELECT Name, Party__c, BlankNote__c FROM Vote__c WHERE User__c = :testUser.Id];
        System.assertEquals(1, votes.size(), 'Vote should still be only one');
        System.assertEquals(party.Id, votes[0].Party__c, 'Party should now be set');
        System.assertEquals(null, votes[0].BlankNote__c, 'Blank note should now be null');
        System.assertEquals('Vote - ' + party.PartyCode__c, votes[0].Name, 'Vote label should match party code');
    }

    //FLS check for getAllParties()
    @isTest
    static void testGetAllParties_FLS() {
        DigitalVotingBoothController.bypassFLSInTest = false;

        Test.startTest();
        List<Party__c> result = DigitalVotingBoothController.getAllParties();
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'FLS test should still return parties');
    }

    @isTest
    static void testSubmitVote_FLS() {
        // Force FLS checks even during test
        DigitalVotingBoothController.bypassFLSInTest = false;
    
        User testUser = createUser();
        Party__c party = [SELECT Id FROM Party__c LIMIT 1];
    
        System.runAs(testUser) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                DigitalVotingBoothController.submitVote(party.Id, null);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
                System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown due to FLS check');
            }
            Test.stopTest();
            System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown due to FLS check');
        }
    
        // Reset for other tests
        DigitalVotingBoothController.bypassFLSInTest = true;
    }

    private static User createUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Unit',
            LastName = 'Test',
            Email = 'unit.test' + Math.random() + '@example.com',
            Username = 'unit.test' + Math.random() + '@example.com',
            Alias = 'utst',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        insert u;
        return u;
    }
}
