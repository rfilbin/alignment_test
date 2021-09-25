public class ModelResponsePayload {
  public Data data;
	public List<Error> errors;

	public class Error {
		public String message;
	}

	public class Data {
		public RunAnalysis runAnalysis;
	}

	public class RunAnalysis {
		public Boolean success;
		public Result result;
	}
	
	public class Result {
		public TotalResults totalResults;
		public List<ProjectResults> projectResults;
	}

	public class Metadata {
		public String name;
		public String identifier;
	}

	public class TotalResults {
		public Double internalRateOfReturn;
		public Double netPresentValue;
    public Double class_a_preflip_atirr;
    public Double class_a_npv;
    public Double class_b_ptirr;
    public Double class_b_npv;
	}

	public class ProjectResults {
		public Metadata metadata;
		public Double internalRateOfReturn;
		public Double netPresentValue;
	}
	
	public static ModelResponsePayload parse(String json) {
		return (ModelResponsePayload) System.JSON.deserialize(json, ModelResponsePayload.class);
	}
}