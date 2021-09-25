(
	{
    //Confirm 
    handleConfirm : function(component, event, helper) {
        //Find lightning flow from component
        var flow = component.find("deleteContactFlow");
        //Put input variable values
        var inputVariables = [
            {
                name : "FinancialAnalysisId_Input",
                type : "String",
                value : component.get("v.recordId")
            }
        ];
        //Reference flow's Unique Name
        flow.startFlow("Project_Wireframe", inputVariables);
    },
     
    //Close the quick action
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
     
    //Flow Status Change
    statusChange : function (component, event, helper) {
        //Check Flow Status
        if (event.getParam('status') === "FINISHED_SCREEN" || event.getParam('status') === "FINISHED") {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Success!",
                message: "Your edits to this project opportunity have been saved.",
                type: "success"
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        } else if (event.getParam('status') === "ERROR") {
            component.set("v.hasError", true);
        }
    }
}
)