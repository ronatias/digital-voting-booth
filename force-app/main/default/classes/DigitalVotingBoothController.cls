public with sharing class DigitalVotingBoothController {

    public static Boolean bypassFLSInTest = true; // Default: true for production/tests unless changed from test run

    @AuraEnabled(cacheable=true)
    public static List<Party__c> getAllParties() {
        if (!Test.isRunningTest() || !bypassFLSInTest) {
            if (!Schema.sObjectType.Party__c.fields.Name.isAccessible() ||
                !Schema.sObjectType.Party__c.fields.Description__c.isAccessible() ||
                !Schema.sObjectType.Party__c.fields.PartyCode__c.isAccessible() ||
                !Schema.sObjectType.Party__c.fields.PartyLeader__c.isAccessible()) {
                throw new AuraHandledException('Insufficient field access.');
            }
        }

        return [
            SELECT Id, Name, Description__c, PartyCode__c, PartyLeader__c
            FROM Party__c
            WHERE PartyCode__c != null
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static void submitVote(Id partyId, String blankNote) {
        if (partyId == null && String.isBlank(blankNote)) return;

        Id currentUserId = UserInfo.getUserId();

        // FLS Checks
        if (!Test.isRunningTest() || !bypassFLSInTest) {
            if (!Schema.sObjectType.Vote__c.fields.Party__c.isCreateable() ||
                !Schema.sObjectType.Vote__c.fields.LastVoteDate__c.isCreateable() ||
                !Schema.sObjectType.Vote__c.fields.User__c.isCreateable() ||
                !Schema.sObjectType.Vote__c.fields.BlankNote__c.isCreateable() ||
                !Schema.sObjectType.Vote__c.fields.Name.isCreateable()) {
                throw new AuraHandledException('Insufficient field permissions.');
            }
        }

        Boolean isBlankVote = String.isNotBlank(blankNote) && partyId == null;

        String voteLabel = isBlankVote ? 'Vote - Blank' : 'Vote - ' + [
            SELECT PartyCode__c FROM Party__c WHERE Id = :partyId LIMIT 1
        ].PartyCode__c;

        List<Vote__c> existingVotes = [
            SELECT Id FROM Vote__c WHERE User__c = :currentUserId LIMIT 1
        ];

        if (!existingVotes.isEmpty()) {
            Vote__c vote = existingVotes[0];
            vote.Name = voteLabel;
            vote.LastVoteDate__c = System.now();
            vote.BlankNote__c = isBlankVote ? blankNote : null;
            vote.Party__c = isBlankVote ? null : partyId;
            update vote;
        } else {
            insert new Vote__c(
                Name = voteLabel,
                User__c = currentUserId,
                Party__c = isBlankVote ? null : partyId,
                LastVoteDate__c = System.now(),
                BlankNote__c = isBlankVote ? blankNote : null
            );
        }
    }
}
