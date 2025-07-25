trigger CollaborationGroupMemberTrigger on CollaborationGroupMember (after insert, after delete) {
    if (Trigger.isInsert) {
        ChatterGroupSyncHelper.handleInsertAsync(Trigger.new);
    }
    if (Trigger.isDelete) {
        ChatterGroupSyncHelper.handleDeleteAsync(Trigger.old);
    }
}
