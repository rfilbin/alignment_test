public class ModelSolverPIRRResponse {
	public class Data {
		public Solve_for_portfolio_irr solve_for_portfolio_irr;
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

	public class Solve_for_portfolio_irr {
		public Boolean success;
		public Result result;
	}
	
	public static ModelSolverPIRRResponse parse(String json) {
		return (ModelSolverPIRRResponse) System.JSON.deserialize(json, ModelSolverPIRRResponse.class);
	}

	public enum SolverVariable {
		PPA_RATE,
		ACQUISITION_COST,
		LEASE_RATE,
		CLASS_A_ADVANCE,
		EPC_COST
	}
}