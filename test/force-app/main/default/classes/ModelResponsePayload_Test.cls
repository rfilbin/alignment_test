@IsTest
public class ModelResponsePayload_Test {
	
	static testMethod void testParseWithErrors() {
		String json = '{'+
		'    \"errors\": [{'+
		'       \"message\": \"Failed to converge\" '+
		'    }],'+
		'    \"data\": {'+
		'        \"runAnalysis\": {'+
		'            \"success\": true,'+
		'            \"result\": {'+
		'                \"totalResults\": {'+
		'                    \"internalRateOfReturn\": 0.038578900141299055,'+
		'                    \"netPresentValue\": -1090908.658973364'+
		'                },'+
		'                \"projectResults\": ['+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 1\",'+
		'                            \"identifier\": \"1\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.033006813869057794,'+
		'                        \"netPresentValue\": -197739.8988847947'+
		'                    },'+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 2\",'+
		'                            \"identifier\": \"2\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.03680393637261137,'+
		'                        \"netPresentValue\": -490470.1606569829'+
		'                    },'+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 3\",'+
		'                            \"identifier\": \"3\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.044958431970276935,'+
		'                        \"netPresentValue\": -146874.93011530765'+
		'                    },'+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 4\",'+
		'                            \"identifier\": \"4\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.040540210577644675,'+
		'                        \"netPresentValue\": -255823.66931627924'+
		'                    }'+
		'                ]'+
		'            }'+
		'        }'+
		'    }'+
		'}';
		ModelResponsePayload obj = ModelResponsePayload.parse(json);
		System.assert(obj != null);		
	}

	static testMethod void testParseNoError() {
		String json = '{'+
		'    \"data\": {'+
		'        \"runAnalysis\": {'+
		'            \"success\": true,'+
		'            \"result\": {'+
		'                \"totalResults\": {'+
		'                    \"internalRateOfReturn\": 0.038578900141299055,'+
		'                    \"netPresentValue\": -1090908.658973364'+
		'                },'+
		'                \"projectResults\": ['+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 1\",'+
		'                            \"identifier\": \"1\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.033006813869057794,'+
		'                        \"netPresentValue\": -197739.8988847947'+
		'                    },'+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 2\",'+
		'                            \"identifier\": \"2\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.03680393637261137,'+
		'                        \"netPresentValue\": -490470.1606569829'+
		'                    },'+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 3\",'+
		'                            \"identifier\": \"3\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.044958431970276935,'+
		'                        \"netPresentValue\": -146874.93011530765'+
		'                    },'+
		'                    {'+
		'                        \"metadata\": {'+
		'                            \"name\": \"Site 4\",'+
		'                            \"identifier\": \"4\"'+
		'                        },'+
		'                        \"internalRateOfReturn\": 0.040540210577644675,'+
		'                        \"netPresentValue\": -255823.66931627924'+
		'                    }'+
		'                ]'+
		'            }'+
		'        }'+
		'    }'+
		'}';
		ModelResponsePayload obj = ModelResponsePayload.parse(json);
		System.assert(obj != null);		
	}


}