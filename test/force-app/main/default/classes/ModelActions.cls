global without sharing class ModelActions {
    
    @InvocableMethod(label='Solve for Variable' description='Solves for the given variable given the ID of the financial analysis.' category='Solver' callout=true)
    global static List<ModelActionResult> solve(List<ModelActionRequest> requests) {
      List<ModelActionResult> results = new List<ModelActionResult>();
      for (ModelActionRequest request : requests) {
        results.add(solveFinancialAnalysis(request));
      }
      return results;
    }
  
    public static ModelActionResult solveFinancialAnalysis(ModelActionRequest request) {
      ModelHelpers helper = new ModelHelpers(request.financialAnalsyisId);
      ModelActionResult result = new ModelActionResult();
      try {
        Double resultOfSolver = helper.solveForVariable(request.solverVariable);        
        result.solverResult = resultOfSolver;        
      }
      catch (ModelHelpers.ModelException modelException) {
        result.hasError = true;
        result.error = modelException.getMessage();
      }
      catch (CalloutException calloutException) {
        result.hasError = true;
        result.error = calloutException.getMessage();
      }
      
      return result;
    }
  
    global class ModelActionRequest {
      @InvocableVariable(required=true)
      global ID financialAnalsyisId;
  
      @InvocableVariable(required=true)
      global String solverVariable;
    }

    global class ModelActionResult {
      @InvocableVariable
      global Double solverResult;  

      @InvocableVariable
      global Boolean hasError;

      @InvocableVariable
      global String error;

    }

  
    class ModelActionException extends Exception {}
  }