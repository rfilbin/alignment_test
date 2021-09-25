@isTest
global class MockModelResponseErrorGenerator implements HttpCalloutMock {
   global HTTPResponse respond(HttpRequest req) {


    String jsonPIRR = '{'+
        ' \"errors\": [{'+
        '       \"message\": \"Failed to converge\" '+
        '    }],'+
		'  \"data\": {'+
		'    \"solve_for_portfolio_irr\": {'+
		'      \"success\": true,'+
		'      \"result\": {'+
		'        \"value\": 0.10259391326419223,'+
		'        \"variable\": \"PPA_RATE\"'+
		'      }'+
		'    }'+
		'  }'+
		'}';
    HttpResponse res = new HttpResponse();
    res.setStatusCode(200);
    res.setHeader('Content-Type', 'application/json');
    res.setBody(jsonPIRR);
    return res;
   }
   
}