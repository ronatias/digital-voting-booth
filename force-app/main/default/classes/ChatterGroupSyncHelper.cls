public class ChatterGroupSyncHelper {

    public static void handleInsertAsync(List<CollaborationGroupMember> members) {
        List<ChatterGroupSyncJob.SyncItem> items = new List<ChatterGroupSyncJob.SyncItem>();
        // For each member added to a Chatter group, create a SyncItem with isInsert = true
        for (CollaborationGroupMember m : members) {
            items.add(new ChatterGroupSyncJob.SyncItem(m.CollaborationGroupId, m.MemberId, true));
        }
        // Enqueue the job to perform public group synchronization
        System.enqueueJob(new ChatterGroupSyncJob(items));
    }

    public static void handleDeleteAsync(List<CollaborationGroupMember> members) {
        List<ChatterGroupSyncJob.SyncItem> items = new List<ChatterGroupSyncJob.SyncItem>();
        // For each member removed from a Chatter group, create a SyncItem with isInsert = false
        for (CollaborationGroupMember m : members) {
            items.add(new ChatterGroupSyncJob.SyncItem(m.CollaborationGroupId, m.MemberId, false));
        }
        // Enqueue the job to perform public group synchronization
        System.enqueueJob(new ChatterGroupSyncJob(items));
    }
}
