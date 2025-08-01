// Queueable Apex job that synchronizes Chatter group membership with matching Public Groups
public class ChatterGroupSyncJob implements Queueable {

    //Wrapper class representing a membership sync action (insert or delete)
    public class SyncItem {
        public Id chatterGroupId;
        public Id userId;
        public Boolean isInsert;

        public SyncItem(Id cgid, Id uid, Boolean ins) {
            this.chatterGroupId = cgid;
            this.userId = uid;
            this.isInsert = ins;
        }
    }

    // List of sync actions to be processed
    private List<SyncItem> syncItems;

    // Constructor to initialize sync items
    public ChatterGroupSyncJob(List<SyncItem> items) {
        this.syncItems = items;
    }

    // Main method executed asynchronously by the queue
    public void execute(QueueableContext context) {
        //Collect unique Chatter group Ids from sync items
        Set<Id> chatterGroupIds = new Set<Id>();
        for (SyncItem item : syncItems) {
            chatterGroupIds.add(item.chatterGroupId);
        }

        // Query Chatter groups involved in the sync
        Map<Id, CollaborationGroup> chatterGroups = new Map<Id, CollaborationGroup>(
            [SELECT Id, Name FROM CollaborationGroup WHERE Id IN :chatterGroupIds]
        );

        // Load all public groups (group type = 'Regular') for mapping by name
        Map<String, Group> publicGroupsByName = new Map<String, Group>();
        for (Group g : [
            SELECT Id, Name FROM Group WHERE Type = 'Regular'
        ]) {
            publicGroupsByName.put(g.Name, g);
        }

        // Identify public groups that do not exist yet and prepare to create them
        List<Group> toInsertGroups = new List<Group>();
        for (CollaborationGroup cg : chatterGroups.values()) {
            if (!publicGroupsByName.containsKey(cg.Name)) {
                toInsertGroups.add(new Group(Name = cg.Name, Type = 'Regular'));
            }
        }

        // Insert new public groups if needed and permitted by FLS
        if (!toInsertGroups.isEmpty() && Schema.sObjectType.Group.isCreateable()) {
            insert toInsertGroups;
            for (Group g : toInsertGroups) {
                publicGroupsByName.put(g.Name, g);
            }
        }

        // Prepare members to insert, delete, and events to publish
        List<GroupMember> membersToInsert = new List<GroupMember>();
        List<GroupMember> membersToDelete = new List<GroupMember>();
        List<ChatterGroupMemberSync__e> eventsToPublish = new List<ChatterGroupMemberSync__e>();

        for (SyncItem item : syncItems) {
            CollaborationGroup cg = chatterGroups.get(item.chatterGroupId);
            if (cg == null) continue; // skip not found
            Group pg = publicGroupsByName.get(cg.Name);
            if (pg == null) continue; // skip not found

            if (item.isInsert) {
                // Prepare user to be inserted into Public group if permitted
                if (Schema.sObjectType.GroupMember.isCreateable()) {
                    membersToInsert.add(new GroupMember(GroupId = pg.Id, UserOrGroupId = item.userId));
                }
            } else {
                // Prepare user to be removed from Public group if permitted
                if (Schema.sObjectType.GroupMember.isDeletable()) {
                    membersToDelete.addAll([
                        SELECT Id FROM GroupMember 
                        WHERE GroupId = :pg.Id AND UserOrGroupId = :item.userId
                    ]);
                }
            }
            // Prepare platform event log for each sync action
            eventsToPublish.add(new ChatterGroupMemberSync__e(
                UserId__c     = item.userId,
                GroupName__c  = cg.Name,
                Action__c     = item.isInsert ? 'Add' : 'Remove'
            ));
        }

        // Run final DML's
        if (!membersToInsert.isEmpty()) insert membersToInsert;
        if (!membersToDelete.isEmpty()) delete membersToDelete;
        if (!eventsToPublish.isEmpty()) EventBus.publish(eventsToPublish);
    }
}
