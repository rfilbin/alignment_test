@isTest
public  class ModelActions_test {

    @TestSetup
    static void makeData(){
        
        Assumption_Set__c assumptionSet = new Assumption_Set__c(Name= 'AssumptionSet');          
        assumptionSet.Seasonality_Q1__c = 0.25;
        assumptionSet.Seasonality_Q2__c = 0.25;
        assumptionSet.Seasonality_Q3__c = 0.25;
        assumptionSet.Seasonality_Q4__c = 0.25;
        assumptionSet.Degradation__c = 0.5;
        assumptionSet.Class_A_Advance_Rate__c = 0.31942;
        assumptionSet.Income_Tax_Rate__c = 21;
        assumptionSet.PreFlip_Phase_I_Cash__c = 0.15;
        assumptionSet.PreFlip_Phase_II_Cash__c = 0.15;
        assumptionSet.PreFlip_Phase_III_Cash__c = 0.15;
        assumptionSet.Residual_Phase_Cash__c = 0.15;
        assumptionSet.PreFlip_Phase_I_Income__c = 0.15;
        assumptionSet.PreFlip_Phase_II_Income__c = 0.15;
        assumptionSet.PreFlip_Phase_III_Income__c = 0.15;
        assumptionSet.Residual_Phase_Income__c = 0.15;
        assumptionSet.Class_B_Target_PTIRR__c  = 0.15;
        assumptionSet.Max_DRO__c = 0.15;
        assumptionSet.Class_A_Target_Flip__c = 0.15;
        assumptionSet.Development_Fee__c = 15.0;
        assumptionSet.Legal_Advisory_Transaction_Fees__c = 0.15;
        assumptionSet.Availability__c = 0.15;
        assumptionSet.EPC_Fee__c = 0.15;
        assumptionSet.Corporate_Overhead_W__c = 0.15;
        assumptionSet.Annual_Insurance__c = 0.15;
        assumptionSet.Insurance_Deflation__c = 0.15;
        assumptionSet.Inverter_Replacement_Cost__c = 1000.0;
        assumptionSet.Inverter_Replacement_Freq__c = 11;
        assumptionSet.Meter_Replacement_Cost__c = 1000.0;
        assumptionSet.Meter_Replacement_Freq__c = 11;
        assumptionSet.O_M_Escalator__c = 0.15;
        assumptionSet.Income_Available_Cash_Equity_pre_flip__c = 0.15;
        assumptionSet.Income_Available_Cash_Equity_post_flip__c  = 0.15;
        assumptionSet.Income_Available_Structured_Equity__c = 0.15;
        assumptionSet.Reduce_DRO_Postflip__c = false;
        assumptionSet.Project_level_Discount_Rate__c = 6.75; 
        assumptionSet.Target_Project_Rate_IRR__c = 7.00;
        insert assumptionSet;

        PortfolioFinancialAnalysis__c analysis = new PortfolioFinancialAnalysis__c(Name= 'Analysis 1');
        analysis.Assumption_Set__c = assumptionSet.Id;
        
        analysis.Estimated_COD__c  = Date.today();
        analysis.PPA_Term__c = 20;
        analysis.PPA_Escalator__c = 2.0;
        analysis.ITC_Assumption__c = 2.0;
        analysis.PPA_Rate__c = 2.0;
        analysis.Model_Type_Solve_For__c = 'EPC Cost';
        insert analysis;     
        
        List<Sites__c> sites = new List<Sites__c>();
        for(Integer i=0;i<4;i++) {
            Sites__c site = new Sites__c(Name = 'Site'+i);
            site.Project__c = analysis.Id;
            site.Total_AC_Size__c = 575.0;
            site.Total_DC_Size__c = 766.2;
            site.Year_One_Specific_Yield__c = 1224.2;
            site.Number_of_Meters__c = 1;
            site.Transaction_Close__c = Date.today();
            site.PPA_Price__c = 0.043;
            site.Interconnection_Costs__c = 0.07; 
            site.Availability__c = 99.2;
            site.EPC_Cost__c = 2.0;
            site.EPC_Fee__c = 2.0;
            site.PPA_Term__c = 20;
            site.Project_Type__c =  'Canopy';
            site.Re_roofing_Fee__c=0.0;
            site.Property_Tax__c = 0.0;
            site.Other_Recurring_Expenses__c= 0.0;
            site.Property_Tax_Escalator__c= 0.0;
            site.Recurring_Expense_Escalator__c= 0.0;
            site.Annual_Lease_Escalator__c= 0.0;
            site.Annual_Lease_Payment__c= 0.0;
            sites.add(site);
        }
        insert sites;  

        Merchant_Schedule__c sched = new Merchant_Schedule__c();
        sched.Financial_Analysis__c = analysis.Id;
        sched.Fiscal_Year__c = Date.today();
        sched.Rate__c = 5.0;
        insert sched;
    }

    public static testMethod void testAction() {

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockModelResponseGenerator()); 

        PortfolioFinancialAnalysis__c financialAnalysis = [SELECT Id FROM PortfolioFinancialAnalysis__c WHERE Name = 'Analysis 1' LIMIT 1 ];

        ModelActions.ModelActionRequest request = new ModelActions.ModelActionRequest();
        request.financialAnalsyisId = financialAnalysis.Id;
        request.solverVariable = 'EPC Cost';

        List<ModelActions.ModelActionRequest> requests = new List<ModelActions.ModelActionRequest>();
        requests.add(request);

        List<ModelActions.ModelActionResult> response = ModelActions.solve(requests);

        Test.stopTest();
        System.assertNotEquals(null, response);

    }

    public static testMethod void testActionException() {



        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockModelResponseErrorGenerator()); 

        PortfolioFinancialAnalysis__c financialAnalysis = [SELECT Id FROM PortfolioFinancialAnalysis__c WHERE Name = 'Analysis 1' LIMIT 1 ];

        ModelActions.ModelActionRequest request = new ModelActions.ModelActionRequest();
        request.financialAnalsyisId = financialAnalysis.Id;
        request.solverVariable = 'EPC Cost';

        List<ModelActions.ModelActionRequest> requests = new List<ModelActions.ModelActionRequest>();
        requests.add(request);

        List<ModelActions.ModelActionResult> response = ModelActions.solve(requests);

        Test.stopTest();
        System.assertNotEquals(null, response);

    }
}