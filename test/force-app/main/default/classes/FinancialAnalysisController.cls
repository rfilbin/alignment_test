public class FinancialAnalysisController {

    ApexPages.StandardController sc;    
    public final PortfolioFinancialAnalysis__c financialAnalysis;    
    public final Assumption_Set__c assumptionSet;    
    public final List<Sites__c> sites;
    public final List<Merchant_Schedule__c> merc_schedule;
    public final List<Depreciation_Breakdown__c> deprec_breakdown;

    // Continuation data
    public string requestAnalysisLabel;
    public string requestPIRRLabel;
    public string requestClassALabel;
    private static final String LONG_RUNNING_SERVICE_URL = 'https://dsd-model-api.azurewebsites.net/api/graphqlapi';
    
    public FinancialAnalysisController(ApexPages.StandardController sc) {
        this.sc = sc;        
        
        Id id = ApexPages.currentPage().getParameters().get('id');
        this.financialAnalysis =  [SELECT Id, Name, Assumption_set__c, Estimated_COD__c, PPA_Term__c, PPA_Escalator__c, ITC_Assumption__c, PPA_Rate__c, Model_Type_Solve_For__c, Project_eligible_for_incentives__c FROM PortfolioFinancialAnalysis__c WHERE Id IN (:id) ];
        System.debug('Running analysis for: ' + this.financialAnalysis.id + ', with a name of: ' + this.financialAnalysis.Name);
        
        
        // Get the assumption Set        
        this.assumptionSet = [SELECT Id, Name, Project_level_Discount_Rate__c, Seasonality_Q1__c, Seasonality_Q2__c,Seasonality_Q3__c,Seasonality_Q4__c, Degradation__c, Class_A_Advance_Rate__c, Income_Tax_Rate__c, PreFlip_Phase_I_Cash__c, PreFlip_Phase_II_Cash__c, PreFlip_Phase_III_Cash__c,Residual_Phase_Cash__c, PreFlip_Phase_I_Income__c, PreFlip_Phase_II_Income__c,PreFlip_Phase_III_Income__c,Residual_Phase_Income__c, Class_B_Target_PTIRR__c , Max_DRO__c, Class_A_Target_Flip__c, Development_Fee__c, Legal_Advisory_Transaction_Fees__c, Availability__c, EPC_Fee__c, Corporate_Overhead_W__c, Annual_Insurance__c, Insurance_Deflation__c, Inverter_Replacement_Cost__c, Inverter_Replacement_Freq__c, Meter_Replacement_Cost__c, Meter_Replacement_Freq__c, O_M_Escalator__c, Income_Available_Cash_Equity_pre_flip__c, Income_Available_Cash_Equity_post_flip__c ,Income_Available_Structured_Equity__c, Reduce_DRO_Postflip__c, Target_Project_Rate_IRR__c FROM Assumption_Set__c WHERE Id IN (:this.financialAnalysis.Assumption_Set__c)  ];
        System.debug('Assumption set: ' + this.assumptionSet.Name);
        
        // Get the sites
        this.sites = [SELECT Id, Name, Total_AC_Size__c, Total_DC_Size__c,Year_One_Specific_Yield__c,Number_of_Meters__c, Transaction_Close__c, PPA_Price__c, Interconnection_Costs__c, Availability__c, EPC_Cost__c, EPC_Fee__c, PPA_Term__c, Project_Type__c, Re_roofing_Fee__c, Property_Tax__c, Other_Recurring_Expenses__c, Property_Tax_Escalator__c, Recurring_Expense_Escalator__c,  Annual_Lease_Escalator__c,  Annual_Lease_Payment__c    FROM Sites__c WHERE Project__c = :this.financialAnalysis.Id];
        System.debug('Sites size: ' + this.sites.size());

        // Get the merchanct schedule
        this.merc_schedule = [SELECT Fiscal_Year__c, Rate__c FROM Merchant_Schedule__c WHERE Financial_Analysis__c = :this.financialAnalysis.Id ORDER BY Fiscal_Year__c ASC];                                 
    }
    
    public String getName() {
        return financialAnalysis.Name;
    }
    

    public Object runAnalysis() {             
        Continuation con = new Continuation(40);
        con.continuationMethod = 'processResponse';

        // Analysis request  
        ModelRequestPayload payload = ModelHelpers.createPayload(this.financialAnalysis, this.assumptionSet, this.sites, this.merc_schedule);
        payload.query = 'mutation RunAnalysis($assumptionSet: InputSet, $inputSet: [InputSet], $overrides:InputSet) {' +
  							'runAnalysis(assumption_set: $assumptionSet, input_set: $inputSet, overrides:$overrides) {' +
    							'success ' +
                                'result { '+
                                  'totalResults { '+
                                    'internalRateOfReturn '+
                                    'netPresentValue '+
                                    'class_a_preflip_atirr '+
                                    'class_a_npv '+
                                    'class_b_ptirr '+
                                    'class_b_npv '+
                                  '}'+
                                  'projectResults { '+
                                    'metadata { '+
                                      'name '+
                                      'identifier '+
                                    '} '+
                                    'internalRateOfReturn '+
                                    'netPresentValue '+
                                  '}'+
                                '}'+
                              '}'+
                            '}';

       
        HttpRequest request1 = new HttpRequest();   
        request1.setEndpoint('callout:azure_api_url');
        request1.setMethod('POST');
        request1.setHeader('Content-Type','application/json;charset=UTF-8');        
        request1.setBody(ModelRequestPayload.serialize(payload));        
        this.requestAnalysisLabel = con.addHttpRequest(request1);

        System.debug('Picklist value is: ' + this.financialAnalysis.Model_Type_Solve_For__c);
        String solveVariable = 'PPA_RATE';
        switch on this.financialAnalysis.Model_Type_Solve_For__c {
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


        // PIRR solver request    
        payload.query = 'mutation SolveForPPARate($assumptionSet: InputSet, $inputSet: [InputSet], $overrides:InputSet) {'+
                            'solve_for_portfolio_irr(assumption_set: $assumptionSet, input_set: $inputSet, overrides:$overrides, variable: '+ solveVariable +') {'+
                                'success '+
                                'result { '+
                                'value '+
                                    'variable '+
                                    '}'+
                                '}'+
                                '}';       

        
        HttpRequest request2 = new HttpRequest();   
        request2.setEndpoint('callout:azure_api_url');
        request2.setMethod('POST');
        request2.setHeader('Content-Type','application/json;charset=UTF-8');
        request2.setBody(ModelRequestPayload.serialize(payload));        
        this.requestPIRRLabel = con.addHttpRequest(request2);

        // Class A solver request
        payload.query = 'mutation SolveForClassARate($assumptionSet: InputSet, $inputSet: [InputSet], $overrides:InputSet) {' +
                                'solve_for_class_a_advance(assumption_set: $assumptionSet, input_set: $inputSet, overrides:$overrides) {'+
                                    'success '+
                                    'result { '+
                                        'value '+
                                        'variable '+
                                    '}'+
                                    '}'+
                                '}';

        
        HttpRequest request3 = new HttpRequest();   
        request3.setEndpoint('callout:azure_api_url');
        request3.setMethod('POST');
        request3.setHeader('Content-Type','application/json;charset=UTF-8');
        request3.setBody(ModelRequestPayload.serialize(payload));        
        this.requestClassALabel = con.addHttpRequest(request3);

        return con;
    }

    public Pagereference processResponse() {
         HttpResponse response = Continuation.getResponse(this.requestAnalysisLabel);
         HttpResponse solverPIRRResponse = Continuation.getResponse(this.requestPIRRLabel);
         HttpResponse solverClassAResponse = Continuation.getResponse(this.requestClassALabel);

         if(response.getStatusCode() != 200) {
            System.debug('The status code was not expected" ' +
                         response.getStatusCode() + ' ' + response.getStatus());
        }
        else if (solverClassAResponse.getStatusCode() != 200 ) {
            System.debug('The status code for solver class A was not expected" ' +
            solverClassAResponse.getStatusCode() + ' ' + solverClassAResponse.getStatus() + ' ' + solverClassAResponse.getBody() );
        }
        else if (solverPIRRResponse.getStatusCode() != 200 ) {
            System.debug('The status code for solver pirr was not expected" ' +
            solverPIRRResponse.getStatusCode() + ' ' + solverPIRRResponse.getStatus() + ' ' + solverPIRRResponse.getBody());
        }
        else {
            
            System.debug(response.getBody());
            ModelResponsePayload resPayload = ModelResponsePayload.parse(response.getBody());  
            
            PortfolioFinancialAnalysis__c analysisSnapshot = getAnalysisCloneAsSnapshotById();
            analysisSnapshot.Portfolio_ATIRR__c = resPayload.data.runAnalysis.result.totalResults.internalRateOfReturn * 100;
            analysisSnapshot.Pro_Forma_NPV__c = resPayload.data.runAnalysis.result.totalResults.netPresentValue;
            analysisSnapshot.Class_A_ATIRR__c = resPayload.data.runAnalysis.result.totalResults.class_a_preflip_atirr * 100;
            analysisSnapshot.Class_A_NPV__c = resPayload.data.runAnalysis.result.totalResults.class_a_npv;
            analysisSnapshot.Class_B_PTIRR__c = resPayload.data.runAnalysis.result.totalResults.class_b_ptirr * 100;
            analysisSnapshot.Class_B_NPV__c = resPayload.data.runAnalysis.result.totalResults.class_b_npv;
            analysisSnapshot.Active_Financial_Analysis__c = this.financialAnalysis.Id;

            ModelSolverPIRRResponse solverPIRRResponsePayload = ModelSolverPIRRResponse.parse(solverPIRRResponse.getBody());
            analysisSnapshot.Solver_Result__c = solverPIRRResponsePayload.data.solve_for_portfolio_irr.result.value;


            ModelSolverClassAResponse solverClassAPayload = ModelSolverClassAResponse.parse(solverClassAResponse.getBody());
            analysisSnapshot.Solver_class_A_advance_rate__c = solverClassAPayload.data.solve_for_class_a_advance.result.value * 100;
            
            insert analysisSnapshot;
            
            for ( ModelResponsePayload.ProjectResults siteResults : resPayload.data.runAnalysis.result.projectResults ) {
                Sites__c snapshot = getSiteCloneAsSnapshotById(Id.valueOf(siteResults.metadata.identifier));
                snapshot.ATIRR__c = siteResults.internalRateOfReturn * 100;
                snapshot.After_Tax_NPV__c = siteResults.netPresentValue;
                snapshot.Project__c = analysisSnapshot.Id;
                insert snapshot;
            }
            
            PageReference newAnalysisPage = new ApexPages.StandardController(analysisSnapshot).view();
            newAnalysisPage.setRedirect(true);
            return newAnalysisPage;
           
        }
         return sc.view();
    }

    
    private Sites__c getSiteCloneAsSnapshotById(Id id) {
        Id recordTypeId = [select Id from RecordType where DeveloperName = 'Snapshot' AND sObjectType = 'Sites__c' limit 1].Id;
        for (Sites__c siteDetails : this.sites) {
            if ( siteDetails.Id == id) {
                Sites__c clone = siteDetails.clone(false, true, false, false);
                clone.RecordTypeId = recordTypeId;
                clone.Project__c = this.financialAnalysis.Id;
                clone.Analysis_Last_Run__c = datetime.now();
                clone.Active_Site__c = id;
                return clone;
            }
        }
        
        return null;
    }
    
    private PortfolioFinancialAnalysis__c getAnalysisCloneAsSnapshotById() {
        Id recordTypeId = [select Id from RecordType where DeveloperName = 'Snapshot' AND sObjectType = 'PortfolioFinancialAnalysis__c' limit 1].Id;
        
        PortfolioFinancialAnalysis__c clone = this.financialAnalysis.clone(false, true, false, false);
        clone.RecordTypeId = recordTypeId;                
        clone.Analysis_Last_Run__c = datetime.now();
        return clone;
        
    }
}