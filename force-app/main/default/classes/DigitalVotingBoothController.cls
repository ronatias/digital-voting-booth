public with sharing class DigitalVotingBoothController {

    @AuraEnabled(cacheable=true)
    public static List<Party__c> getAllParties() {
        // FLS checks
        if (!Schema.sObjectType.Party__c.fields.Name.isAccessible() ||
            !Schema.sObjectType.Party__c.fields.Description__c.isAccessible() ||
            !Schema.sObjectType.Party__c.fields.PartyCode__c.isAccessible() ||
            !Schema.sObjectType.Party__c.fields.PartyLeader__c.isAccessible()) {
            throw new AuraHandledException('Insufficient field access.');
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
        Id currentUserId = UserInfo.getUserId();

        // Field-Level Security Checks
        if (!Schema.sObjectType.Vote__c.fields.Party__c.isCreateable() ||
            !Schema.sObjectType.Vote__c.fields.LastVoteDate__c.isCreateable() ||
            !Schema.sObjectType.Vote__c.fields.User__c.isCreateable() ||
            !Schema.sObjectType.Vote__c.fields.BlankNote__c.isCreateable() ||
            !Schema.sObjectType.Vote__c.fields.Name.isCreateable()) {
            throw new AuraHandledException('Insufficient field permissions.');
        }

        // Fetch existing vote
        List<Vote__c> existingVotes = [
            SELECT Id, Party__c, BlankNote__c
            FROM Vote__c
            WHERE User__c = :currentUserId
            LIMIT 1
        ];

        // Set party only if partyId is not null and not a blank note
        Boolean isBlankVote = String.isNotBlank(blankNote) && partyId == null;

        if (!existingVotes.isEmpty()) {
            Vote__c vote = existingVotes[0];
            vote.LastVoteDate__c = System.now();
            vote.BlankNote__c = isBlankVote ? blankNote : null;
            vote.Party__c = isBlankVote ? null : partyId;
            vote.Name = 'Vote - ' + currentUserId + ' - ' + Datetime.now().format('yyyyMMddHHmmss');
            update vote;
        } else {
            Vote__c vote = new Vote__c();
            vote.User__c = currentUserId;
            vote.LastVoteDate__c = System.now();
            vote.BlankNote__c = isBlankVote ? blankNote : null;
            vote.Party__c = isBlankVote ? null : partyId;
            vote.Name = 'Vote - ' + currentUserId + ' - ' + Datetime.now().format('yyyyMMddHHmmss');
            insert vote;
        }
    }
}
