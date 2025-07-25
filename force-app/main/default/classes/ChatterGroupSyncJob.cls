public class ChatterGroupSyncJob implements Queueable {

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

    private List<SyncItem> syncItems;

    public ChatterGroupSyncJob(List<SyncItem> items) {
        this.syncItems = items;
    }

    public void execute(QueueableContext context) {
        Set<Id> chatterGroupIds = new Set<Id>();
        for (SyncItem item : syncItems) {
            chatterGroupIds.add(item.chatterGroupId);
        }

        Map<Id, CollaborationGroup> chatterGroups = new Map<Id, CollaborationGroup>(
            [SELECT Id, Name FROM CollaborationGroup WHERE Id IN :chatterGroupIds]
        );

        Map<String, Group> publicGroupsByName = new Map<String, Group>();
        for (Group g : [
            SELECT Id, Name FROM Group WHERE Type = 'Regular'
        ]) {
            publicGroupsByName.put(g.Name, g);
        }

        List<Group> toInsertGroups = new List<Group>();
        for (CollaborationGroup cg : chatterGroups.values()) {
            if (!publicGroupsByName.containsKey(cg.Name)) {
                toInsertGroups.add(new Group(Name = cg.Name, Type = 'Regular'));
            }
        }

        if (!toInsertGroups.isEmpty() && Schema.sObjectType.Group.isCreateable()) {
            insert toInsertGroups;
            for (Group g : toInsertGroups) {
                publicGroupsByName.put(g.Name, g);
            }
        }

        List<GroupMember> membersToInsert = new List<GroupMember>();
        List<GroupMember> membersToDelete = new List<GroupMember>();
        List<ChatterGroupMemberSync__e> eventsToPublish = new List<ChatterGroupMemberSync__e>();

        for (SyncItem item : syncItems) {
            CollaborationGroup cg = chatterGroups.get(item.chatterGroupId);
            if (cg == null) continue;
            Group pg = publicGroupsByName.get(cg.Name);
            if (pg == null) continue;

            if (item.isInsert) {
                if (Schema.sObjectType.GroupMember.isCreateable()) {
                    membersToInsert.add(new GroupMember(GroupId = pg.Id, UserOrGroupId = item.userId));
                }
            } else {
                if (Schema.sObjectType.GroupMember.isDeletable()) {
                    membersToDelete.addAll([
                        SELECT Id FROM GroupMember 
                        WHERE GroupId = :pg.Id AND UserOrGroupId = :item.userId
                    ]);
                }
            }
            eventsToPublish.add(new ChatterGroupMemberSync__e(
                UserId__c     = item.userId,
                GroupName__c  = cg.Name,
                Action__c     = item.isInsert ? 'Add' : 'Remove'
            ));
        }

        if (!membersToInsert.isEmpty()) insert membersToInsert;
        if (!membersToDelete.isEmpty()) delete membersToDelete;
        if (!eventsToPublish.isEmpty()) EventBus.publish(eventsToPublish);
    }
}
