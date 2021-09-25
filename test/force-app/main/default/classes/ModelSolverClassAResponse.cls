public class ModelSolverClassAResponse {
	public class Data {
		public Solve_for_class_a_advance solve_for_class_a_advance;
	}

	public Data data;
	public List<Error> errors;

	public class Error {
		public String message;
	}

	public class Result {
		public Double value;
		public SolverVariable variable;
	}

	public class Solve_for_class_a_advance {
		public Boolean success;
		public Result result;
	}
	
	public static ModelSolverClassAResponse parse(String json) {
		return (ModelSolverClassAResponse) System.JSON.deserialize(json, ModelSolverClassAResponse.class);
	}

	public enum SolverVariable {
		PPA_RATE,
		ACQUISITION_COST,
		LEASE_RATE,
		CLASS_A_ADVANCE,
		EPC_COST
	}
}