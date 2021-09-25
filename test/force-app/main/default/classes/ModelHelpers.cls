public without sharing class ModelHelpers {
    public class ModelException extends Exception {}


    private final Id financialAnalysisID;
    
    public ModelHelpers(Id financialAnalysisId) {
        this.financialAnalysisId = financialAnalysisId;
    }

    public Double solveForVariable(String variable) {

        
        // Get all the objects we need
        PortfolioFinancialAnalysis__c financialAnalysis =  [SELECT Id, Name, Assumption_set__c, Estimated_COD__c, PPA_Term__c, PPA_Escalator__c, ITC_Assumption__c, PPA_Rate__c, Model_Type_Solve_For__c, Project_eligible_for_incentives__c FROM PortfolioFinancialAnalysis__c WHERE Id IN (:this.financialAnalysisId) ];
        //System.debug('Running analysis for: ' + financialAnalysis.id + ', with a name of: ' + financialAnalysis.Name);
        
        
        // Get the assumption Set        
        Assumption_Set__c assumptionSet = [SELECT Id, Name, Project_level_Discount_Rate__c, Seasonality_Q1__c, Seasonality_Q2__c,Seasonality_Q3__c,Seasonality_Q4__c, Degradation__c, Class_A_Advance_Rate__c, Income_Tax_Rate__c, PreFlip_Phase_I_Cash__c, PreFlip_Phase_II_Cash__c, PreFlip_Phase_III_Cash__c,Residual_Phase_Cash__c, PreFlip_Phase_I_Income__c, PreFlip_Phase_II_Income__c,PreFlip_Phase_III_Income__c,Residual_Phase_Income__c, Class_B_Target_PTIRR__c , Max_DRO__c, Class_A_Target_Flip__c, Development_Fee__c, Legal_Advisory_Transaction_Fees__c, Availability__c, EPC_Fee__c, Corporate_Overhead_W__c, Annual_Insurance__c, Insurance_Deflation__c, Inverter_Replacement_Cost__c, Inverter_Replacement_Freq__c, Meter_Replacement_Cost__c, Meter_Replacement_Freq__c, O_M_Escalator__c, Income_Available_Cash_Equity_pre_flip__c, Income_Available_Cash_Equity_post_flip__c ,Income_Available_Structured_Equity__c, Reduce_DRO_Postflip__c,Target_Project_Rate_IRR__c FROM Assumption_Set__c WHERE Id IN (:financialAnalysis.Assumption_Set__c)  ];
        //System.debug('Assumption set: ' + assumptionSet.Name);
        
        // Get the sites
        List<Sites__c> sites = [SELECT Id, Name, Total_AC_Size__c, Total_DC_Size__c,Year_One_Specific_Yield__c,Number_of_Meters__c, Transaction_Close__c, PPA_Price__c, Interconnection_Costs__c, Availability__c, EPC_Cost__c, EPC_Fee__c, PPA_Term__c, Project_Type__c, Re_roofing_Fee__c, Property_Tax__c, Other_Recurring_Expenses__c, Property_Tax_Escalator__c, Recurring_Expense_Escalator__c,  Annual_Lease_Escalator__c,  Annual_Lease_Payment__c FROM Sites__c WHERE Project__c = :this.financialAnalysisId];
        //System.debug('Sites size: ' + sites.size());

        // Get the merchanct schedule
        List<Merchant_Schedule__c> merc_schedule = [SELECT Fiscal_Year__c, Rate__c FROM Merchant_Schedule__c WHERE Financial_Analysis__c = :this.financialAnalysisId ORDER BY Fiscal_Year__c ASC];


        System.debug('Solving for variable: ' + variable);
        String solveVariable = 'PPA_RATE';
        switch on variable {
            when 'PPA Price' {		
                solveVariable = 'PPA_RATE';
            }	
            when 'Lease Payment' {		
                solveVariable = 'LEASE_RATE';
            }
            when 'EPC Cost' {		
                solveVariable = 'EPC_COST';
            }
            when 'Acquisition Cost' {		
                solveVariable = 'ACQUISITION_COST';
            }
        }

        
        ModelRequestPayload payloadPIRR = createPayload(financialAnalysis, assumptionSet, sites, merc_schedule);    
        payloadPIRR.query = 'mutation SolveForPPARate($assumptionSet: InputSet, $inputSet: [InputSet], $overrides:InputSet) {'+
                            'solve_for_portfolio_irr(assumption_set: $assumptionSet, input_set: $inputSet, overrides:$overrides, variable: '+ solveVariable +') {'+
                                'success '+
                                'result { '+
                                'value '+
                                    'variable '+
                                    '}'+
                                '}'+
                                '}';       

        String serializedPayload = ModelRequestPayload.serialize(payloadPIRR);
        System.debug(System.LoggingLevel.DEBUG, 'Sending the following payload to API: ' + serializedPayload);

        Http h = new Http();
        HttpRequest request1 = new HttpRequest();   
        request1.setEndpoint('callout:azure_api_url');
        request1.setMethod('POST');
        request1.setTimeout(120000);
        request1.setHeader('Content-Type','application/json;charset=UTF-8');        
        request1.setBody(serializedPayload);    
        HttpResponse response = h.send(request1);

        if(response.getStatusCode() != 200) {
            System.debug('The status code was not expected" ' +
                         response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody());
        }
        else {
            System.debug(response.getBody());
            ModelSolverPIRRResponse solverPIRRResponsePayload = ModelSolverPIRRResponse.parse(response.getBody());
            if ( solverPIRRResponsePayload?.errors?.size() > 0 ) {
                System.debug(System.LoggingLevel.ERROR, 'Error from API:' + solverPIRRResponsePayload.errors[0].message );
                throw new ModelException(solverPIRRResponsePayload.errors[0].message);
            }
            else {
                return solverPIRRResponsePayload.data.solve_for_portfolio_irr.result.value;

                
            }
        }

        return null;
    }


    public static ModelRequestPayload createPayload(PortfolioFinancialAnalysis__c financialAnalysis, Assumption_Set__c assumptionSet, List<Sites__c> sites, List<Merchant_Schedule__c>  merc_schedule_source ) {
        ModelRequestPayload payload = new ModelRequestPayload();




        
        
        // Assumption Set
        // Metadata
        payload.variables = new ModelRequestPayload.Variables();
        payload.variables.assumptionSet = new ModelRequestPayload.InputSet();
        payload.variables.assumptionSet.metadata = new ModelRequestPayload.Metadata();
        payload.variables.assumptionSet.metadata.name = assumptionSet.Name;
        payload.variables.assumptionSet.metadata.identifier = assumptionSet.Id;
        
        // Project Details
        payload.variables.assumptionSet.projectDetails = new ModelRequestPayload.ProjectDetails();
        payload.variables.assumptionSet.projectDetails.com_operation_date = financialAnalysis.Estimated_COD__c?.format();       
        payload.variables.assumptionSet.projectDetails.discount_rate = assumptionSet.Project_level_Discount_Rate__c/100;
        payload.variables.assumptionSet.projectDetails.target_project_irr = assumptionSet.Target_Project_Rate_IRR__c/100;
        
        // Contract Details
        payload.variables.assumptionSet.contractDetails = new ModelRequestPayload.ContractDetails();
        payload.variables.assumptionSet.contractDetails.term_length = financialAnalysis?.PPA_Term__c?.intValue();
		payload.variables.assumptionSet.contractDetails.ppa_escalator  = financialAnalysis?.PPA_Escalator__c;
        payload.variables.assumptionSet.contractDetails.ppa_rate=financialAnalysis?.PPA_Rate__c;  

        // Revenue Details
        payload.variables.assumptionSet.revenueDetails = new ModelRequestPayload.RevenueDetails();        
     
        // Merchant Schedule
        payload.variables.assumptionSet.contractDetails.merc_schedule = new ModelRequestPayload.AnnualSchedule();
        if (merc_schedule_source != null && merc_schedule_source.size() > 0 ) {
            payload.variables.assumptionSet.contractDetails.merc_schedule.starting_year = merc_schedule_source[0].Fiscal_Year__c.year();
            List<Double> merc_schedule = new List<Double>();
            for ( Merchant_Schedule__c schedule_entry : merc_schedule_source ) {
                merc_schedule.add(schedule_entry.Rate__c);
            }
            payload.variables.assumptionSet.contractDetails.merc_schedule.values = merc_schedule;
            System.debug(merc_schedule);
        }
        
        // Production Assumptions
        payload.variables.assumptionSet.productionAssumptions = new ModelRequestPayload.ProductionAssumptions();
        payload.variables.assumptionSet.productionAssumptions.degradation = assumptionSet.Degradation__c;
        List<Double> quarter_seasonality_estimates = new List<Double>();
        quarter_seasonality_estimates.add(assumptionSet.Seasonality_Q1__c/100);
        quarter_seasonality_estimates.add(assumptionSet.Seasonality_Q2__c/100);
        quarter_seasonality_estimates.add(assumptionSet.Seasonality_Q3__c/100);
        quarter_seasonality_estimates.add(assumptionSet.Seasonality_Q4__c/100);            
        payload.variables.assumptionSet.productionAssumptions.quarter_seasonality_estimates = quarter_seasonality_estimates;
        payload.variables.assumptionSet.productionAssumptions.availability = assumptionSet.Availability__c;
        
        // Operation Costs
        payload.variables.assumptionSet.operationCosts = new ModelRequestPayload.OperationCosts();
        payload.variables.assumptionSet.operationCosts.o_and_m_escalator = assumptionSet.O_M_Escalator__c;        
        payload.variables.assumptionSet.operationCosts.insurance_rate = assumptionSet.Annual_Insurance__c;
        payload.variables.assumptionSet.operationCosts.insurance_deflation = assumptionSet.Insurance_Deflation__c;
        payload.variables.assumptionSet.operationCosts.inverter_replacement_cost = assumptionSet.Inverter_Replacement_Cost__c;
        payload.variables.assumptionSet.operationCosts.inverter_replacement_freq = assumptionSet?.Inverter_Replacement_Freq__c?.intValue();
        payload.variables.assumptionSet.operationCosts.meter_replacement_cost = assumptionSet?.Meter_Replacement_Cost__c;
        payload.variables.assumptionSet.operationCosts.meter_replacement_freq = assumptionSet?.Meter_Replacement_Freq__c?.intValue();
        
        // Transaction Details
        payload.variables.assumptionSet.transactionDetails = new ModelRequestPayload.TransactionDetails();
        payload.variables.assumptionSet.transactionDetails.class_a_advance_rate= assumptionSet.Class_A_Advance_Rate__c / 100; 
        
        // Taxes
        payload.variables.assumptionSet.taxes = new ModelRequestPayload.Taxes();
        payload.variables.assumptionSet.taxes.itc_eligibility = financialAnalysis.ITC_Assumption__c;
        payload.variables.assumptionSet.taxes.income_tax_rate = assumptionSet.Income_Tax_Rate__c;
        
        // Equity Structure
        payload.variables.assumptionSet.equityStructure = new ModelRequestPayload.EquityStructure();
        payload.variables.assumptionSet.equityStructure.cash_structure = new ModelRequestPayload.StructuredEquityDetail();
        payload.variables.assumptionSet.equityStructure.cash_structure.phase_I = assumptionSet.PreFlip_Phase_I_Cash__c /100;    
        payload.variables.assumptionSet.equityStructure.cash_structure.phase_II= assumptionSet.PreFlip_Phase_II_Cash__c /100;
        payload.variables.assumptionSet.equityStructure.cash_structure.phase_III= assumptionSet.PreFlip_Phase_III_Cash__c /100;
        payload.variables.assumptionSet.equityStructure.cash_structure.residual= assumptionSet.Residual_Phase_Cash__c /100;        
        payload.variables.assumptionSet.equityStructure.income_structure   = new ModelRequestPayload.StructuredEquityDetail();
        payload.variables.assumptionSet.equityStructure.income_structure.phase_I = assumptionSet.PreFlip_Phase_I_Income__c /100;
        payload.variables.assumptionSet.equityStructure.income_structure.phase_II = assumptionSet.PreFlip_Phase_II_Income__c /100;
        payload.variables.assumptionSet.equityStructure.income_structure.phase_III = assumptionSet.PreFlip_Phase_III_Income__c /100;
        payload.variables.assumptionSet.equityStructure.income_structure.residual = assumptionSet.Residual_Phase_Income__c /100;        
        payload.variables.assumptionSet.equityStructure.class_a_target_flip_atirr= assumptionSet.Class_A_Target_Flip__c  /100;
        payload.variables.assumptionSet.equityStructure.class_b_target_ptirr=assumptionSet.Class_B_Target_PTIRR__c /100;
        payload.variables.assumptionSet.equityStructure.reduce_dro_postflip= assumptionSet.Reduce_DRO_Postflip__c;
        payload.variables.assumptionSet.equityStructure.max_dro_fraction= assumptionSet.Max_DRO__c / 100;
        payload.variables.assumptionSet.equityStructure.max_a_income_fraction= assumptionSet.Income_Available_Structured_Equity__c/100; 
        payload.variables.assumptionSet.equityStructure.max_b_income_fraction_preflip= assumptionSet.Income_Available_Cash_Equity_pre_flip__c/100; 
        payload.variables.assumptionSet.equityStructure.max_b_income_fraction_postflip=  assumptionSet.Income_Available_Cash_Equity_post_flip__c/100; 

        // Dev and Construction 
        payload.variables.assumptionSet.devAndConstruction = new ModelRequestPayload.DevAndConstruction();
        payload.variables.assumptionSet.devAndConstruction.epc_fee = assumptionSet.EPC_Fee__c;
        payload.variables.assumptionSet.devAndConstruction.corporate_overhead= assumptionSet.Corporate_Overhead_W__c;
        payload.variables.assumptionSet.devAndConstruction.development_fee = assumptionSet.Development_Fee__c;
        payload.variables.assumptionSet.devAndConstruction.legal_adv_trans_fee = assumptionSet.Legal_Advisory_Transaction_Fees__c;


        if ( financialAnalysis.Project_eligible_for_incentives__c  == 'Yes') {
            // Incentives
            List<Incentive_Payments__c> incentive_payments = [SELECT Capacity_Wdc__c, Dollar__c, Energy_KWh__c, Rec_MWh__c, YearNumber__c, YearAsNumber__c FROM Incentive_Payments__c WHERE Financial_Analysis__c = :financialAnalysis.id ORDER BY YearAsNumber__c ASC];
            if ( incentive_payments.size() > 0 ) {
                Integer startingYear = incentive_payments[0].YearAsNumber__c.intValue();
                ModelRequestPayload.AnnualSchedule srec_sched = new ModelRequestPayload.AnnualSchedule();
                srec_sched.starting_year = startingYear;
                srec_sched.values = new List<Double>();

                ModelRequestPayload.AnnualSchedule incentives_sched = new ModelRequestPayload.AnnualSchedule();
                incentives_sched.starting_year = startingYear;
                incentives_sched.values = new List<Double>();

                ModelRequestPayload.AnnualSchedule capacity_sched = new ModelRequestPayload.AnnualSchedule();
                capacity_sched.starting_year = startingYear;
                capacity_sched.values = new List<Double>();

                ModelRequestPayload.AnnualSchedule dollar_sched = new ModelRequestPayload.AnnualSchedule();
                dollar_sched.starting_year = startingYear;
                dollar_sched.values = new List<Double>();

                for (Incentive_Payments__c incentive_payment : incentive_payments) {
                    srec_sched.values.add(incentive_payment.Rec_MWh__c);
                    incentives_sched.values.add(incentive_payment.Dollar__c);
                    capacity_sched.values.add(incentive_payment.Capacity_Wdc__c);
                    dollar_sched.values.add(incentive_payment.Energy_KWh__c);
                }

                payload.variables.assumptionSet.revenueDetails.capacity_payments_by_year = capacity_sched;
                payload.variables.assumptionSet.revenueDetails.incentive_by_year = incentives_sched;
                payload.variables.assumptionSet.revenueDetails.srec_rate = srec_sched;
                payload.variables.assumptionSet.revenueDetails.other_rate_by_year = dollar_sched;
                
            }

        }
 
        List<ModelRequestPayload.InputSet> sitesLocal = new List<ModelRequestPayload.InputSet>();      
        for ( Sites__c siteDetails : sites ) {

            ModelRequestPayload.InputSet site = new ModelRequestPayload.InputSet();
            site.metadata = new ModelRequestPayload.Metadata();
            site.metadata.name = siteDetails.Name;
            site.metadata.identifier = siteDetails.Id;

            site.projectDetails = new ModelRequestPayload.ProjectDetails();
            site.projectDetails.transaction_date = siteDetails.Transaction_Close__c?.format();   

            site.contractDetails = new ModelRequestPayload.ContractDetails();        
            site.contractDetails.term_length = siteDetails.PPA_Term__c?.intValue();       

            site.systemDetails = new ModelRequestPayload.SystemDetails();
            site.systemDetails.dc_size = siteDetails.Total_DC_Size__c;
            site.systemDetails.ac_size= siteDetails.Total_AC_Size__c;
            site.systemDetails.number_of_meters= siteDetails.Number_of_Meters__c?.intValue();
            site.systemDetails.bess_capacity= 0;       

            site.productionAssumptions = new ModelRequestPayload.ProductionAssumptions();
            site.productionAssumptions.year_one_specific_yield = siteDetails.Year_One_Specific_Yield__c;
            site.productionAssumptions.availability= siteDetails?.Availability__c;        

            site.devAndConstruction = new ModelRequestPayload.DevAndConstruction();            

            site.devAndConstruction.epc= siteDetails?.EPC_Cost__c; 
            site.devAndConstruction.itc_eligible_costs_per_w = 0;      
            site.devAndConstruction.itc_ineligible_costs_per_w = 0;
            if (siteDetails.Interconnection_Costs__c != null) {
                site.devAndConstruction.itc_ineligible_costs_per_w += siteDetails.Interconnection_Costs__c;
            }
            if (siteDetails.Re_roofing_Fee__c != null) {
                site.devAndConstruction.itc_ineligible_costs_per_w += siteDetails.Re_roofing_Fee__c;
            }    
            

          

            // Depreciation Breakdown
            List<Depreciation_Breakdown__c> deprec_breakdown = [SELECT Id, Project_Type__c FROM Depreciation_Breakdown__c WHERE Assumption_Set__c = :assumptionSet.id AND Project_Type__c = :siteDetails.Project_Type__c ];
            if ( deprec_breakdown != null && deprec_breakdown.size() == 1) {
                List<Depreciation_Allocation__c> allocations = [SELECT Method__c, Lifetime__c, allocation_Percentage__c FROM Depreciation_Allocation__c WHERE Depreciation_Breakdown__c = :deprec_breakdown[0].Id];
                System.debug('Allocations: ' + allocations.size());

                List<ModelRequestPayload.DepreciationPortion> table = new List<ModelRequestPayload.DepreciationPortion>();
                for ( Depreciation_Allocation__c allocation : allocations ) {
                    ModelRequestPayload.DepreciationPortion portion = new ModelRequestPayload.DepreciationPortion();
                    portion.allocation = allocation.Allocation_Percentage__c;
                    portion.length = Integer.valueOf(allocation.Lifetime__c);

                    if (allocation.Method__c == 'Straight Line' ) {
                        portion.method = ModelRequestPayload.DepreciationMethodEnum.SL;
                    }
                    else if ( allocation.Method__c == 'MACRS') {
                        portion.method = ModelRequestPayload.DepreciationMethodEnum.MACRS;
                    }                    
                    table.add(portion);
                }        
       
                site.depreciation = new ModelRequestPayload.Depreciation();
                site.depreciation.table = table;
            }
            else 
            {
                System.debug('Could not find any depreciation breakdown for Assumption set: ' + assumptionSet.id + ', with project type: ' + siteDetails.Project_Type__c);
            }

            // Operations and Management
            site.operationCosts = new ModelRequestPayload.OperationCosts();
            List<Operations_and_Maintenance__c> op_maints = [SELECT Asset_Management__c, Planned_Maintenance__c, Unplanned_Maintenance__c FROM Operations_and_Maintenance__c WHERE Assumption_Set__c = :assumptionSet.id AND Project_Type__c = :siteDetails.Project_Type__c ];
            if ( op_maints != null && op_maints.size() == 1) {
                site.operationCosts.planned_maintenance = op_maints[0].Planned_Maintenance__c;
                site.operationCosts.unplanned_maintenance = op_maints[0].Unplanned_Maintenance__c;
                site.operationCosts.asset_management = op_maints[0].Asset_Management__c;
            }            
            else 
            {
                System.debug('Could not find any operations amd maintenance breakdown for Assumption set: ' + assumptionSet.id + ', with project type: ' + siteDetails.Project_Type__c);
            }

            site.operationCosts.property_tax = siteDetails?.Property_Tax__c;
            site.operationCosts.property_tax_escalator = siteDetails?.Property_Tax_Escalator__c;
            site.operationCosts.other_expense = siteDetails?.Other_Recurring_Expenses__c;
            site.operationCosts.other_expense_escalator = siteDetails?.Recurring_Expense_Escalator__c;
            site.operationCosts.site_lease = siteDetails?.Annual_Lease_Payment__c;
            site.operationCosts.site_lease_escalator = siteDetails?.Annual_Lease_Escalator__c;

            //site.devAndConstruction.corporate_overhead=0.12;
            // TODO: Needs to come from SF Object
            site.devAndConstruction.bess_capex=0;
            //site.devAndConstruction.epc_fee= 5;   
            site.devAndConstruction.epc_fee= siteDetails?.EPC_Fee__c; 
            sitesLocal.add(site);        
        }     
        
        payload.variables.inputSet = sitesLocal;
        
        payload.variables.overrides = new ModelRequestPayload.InputSet();
        return payload;
    }
}