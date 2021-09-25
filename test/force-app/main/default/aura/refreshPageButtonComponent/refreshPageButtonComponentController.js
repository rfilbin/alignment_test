({
    refreshPage : function(component, event, helper) {
        // $A.get('e.force:refreshView').fire();
        location.reload();
    },
    invoke : function(component, event, helper) { 
        location.reload();
      }
})