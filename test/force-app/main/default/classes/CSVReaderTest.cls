@isTest
private class CSVReaderTest {

    @IsTest public static void  testParse(){
		String csvString = 'h1, h2, h3, h4\nv1, 5, with space,\n"with\nnewline", "with quotes", 3, 4';
		List<List<string>> result = CSVReader.Parse(csvString);
		System.assert(result.size() == 3);
		System.assert(result[0].size()==4);
		System.assert(result[1].size()==4);
		System.assert(result[2].size()==4);
		
		String csv = 'Serial #,Make/Model,Accessory Description,Lease#,Asset#,Ref C,Ref P ,Ref H,Ref T,Line Item';
 		csv += '\n';
 		csv += 'Serial #,Make/Model,Accessory Description,Lease#,Asset#,5,5 ,5,6,Conversion Failure';
		result = CSVReader.Parse(csv);
		System.assert(result.size() == 2);
		System.assert(result[0].size() == 10);
		System.assert(result[1].size() == 10);
	}
}