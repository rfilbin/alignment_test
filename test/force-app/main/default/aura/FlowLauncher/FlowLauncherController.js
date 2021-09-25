({
    launchFlow : function(component, event, helper) {
        helper.launchFlow(component);
    },

    statusChange : function(component, event, helper) {
        helper.statusChange(component, event);
    },

    handleCancel : function(component, event, helper) {
        helper.closeModal(component);
    }
})