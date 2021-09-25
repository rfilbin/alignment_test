({
    launchFlow : function(component) {
        this.openModal(component);

        var flow = component.find("lightningFlow");

        var inputVariables = [
            {
                name : "recordId",
                type : "String",
                value : component.get("v.recordId")
            }
        ];

        flow.startFlow(component.get("v.FlowName"), inputVariables);
    },

    statusChange : function (component, event) {
        if(event.getParam('status') === "FINISHED") {
            this.closeModal(component);
        }
    },

    openModal : function(component) {
        component.set("v.OpenModal", true);
    },

    closeModal : function(component) {
        component.set("v.OpenModal", false);
    }
})