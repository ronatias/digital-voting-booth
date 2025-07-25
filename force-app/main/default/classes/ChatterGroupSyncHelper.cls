public class ChatterGroupSyncHelper {

    public static void handleInsertAsync(List<CollaborationGroupMember> members) {
        List<ChatterGroupSyncJob.SyncItem> items = new List<ChatterGroupSyncJob.SyncItem>();
        for (CollaborationGroupMember m : members) {
            items.add(new ChatterGroupSyncJob.SyncItem(m.CollaborationGroupId, m.MemberId, true));
        }
        System.enqueueJob(new ChatterGroupSyncJob(items));
    }

    public static void handleDeleteAsync(List<CollaborationGroupMember> members) {
        List<ChatterGroupSyncJob.SyncItem> items = new List<ChatterGroupSyncJob.SyncItem>();
        for (CollaborationGroupMember m : members) {
            items.add(new ChatterGroupSyncJob.SyncItem(m.CollaborationGroupId, m.MemberId, false));
        }
        System.enqueueJob(new ChatterGroupSyncJob(items));
    }
}
