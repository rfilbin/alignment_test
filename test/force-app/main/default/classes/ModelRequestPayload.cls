public class ModelRequestPayload {

	public class EquityStructure {
		public StructuredEquityDetail cash_structure;
		public StructuredEquityDetail income_structure;
		public Double class_a_target_flip_atirr;
		public Double class_b_target_ptirr;
		public Boolean reduce_dro_postflip;
		public Double max_dro_fraction;
		public Double max_a_income_fraction;
		public Double max_b_income_fraction_preflip;
		public Double max_b_income_fraction_postflip;
	}

	public class ProjectDetails {
		public String com_operation_date;
		public String transaction_date;
		
		public Double discount_rate;
		public Double target_project_irr;
	}

	public class StructuredEquityDetail {
		public Double phase_I;
		public Double phase_II;
		public Double phase_III;
		public Double residual;
	}

	public class DepreciationPortion {
		public Double allocation;
		public Integer length;
		public DepreciationMethodEnum method;
	}

	public enum DepreciationMethodEnum  {MACRS, SL}

	public class Metadata {
		public String name;
		public String identifier;
	}

	public class DevAndConstruction {
		public Double epc;
		public Double epc_fee;
		public Double acquisition_cost;
		public Double legal_adv_trans_fee;
		public Double itc_eligible_costs_per_w;
		public Double itc_ineligible_costs_per_w;
		public Double development_fee;		
		public Double corporate_overhead;
		public Integer bess_capex;
		public Double total_build_cost;
	}

	public class ContractDetails {
		public Integer term_length;
		public Double ppa_escalator;
		public AnnualSchedule merc_schedule;
		public Double ppa_rate;
		public ContractTypeEnum type;
	}

	 public enum ContractTypeEnum { PPA }

	 public class AnnualSchedule {
		 public Integer starting_year;
		 public List<Double> values;
	 }

	 public class QuarterlySchedule {
		public Integer starting_year;
		public Integer starting_quarter;
		public List<Double> values;
	}


	public class OperationCosts {
		public Double planned_maintenance;
		public Double unplanned_maintenance;
		public Double o_and_m_escalator;
		public Double asset_management;
		public Double insurance_rate;
		public Double insurance_deflation;
		public Double inverter_replacement_cost;
		public Integer inverter_replacement_freq;
		public Double meter_replacement_cost;
		public Integer meter_replacement_freq;
		public Double site_lease;
		public Double site_lease_escalator;
		public Double property_tax;
		public Double property_tax_escalator;
		public Double other_expense;
		public Double other_expense_escalator;
		public AnnualSchedule other_opex_schedule;

	}

	public class ProductionAssumptions {
		public Double degradation;
		public Double year_one_specific_yield;
		public Double availability;
		public List<Double> quarter_seasonality_estimates;
	}

	public class InputSet {
		public Metadata metadata;
		public ProjectDetails projectDetails;
		public ContractDetails contractDetails;
		public SystemDetails systemDetails;
		public ProductionAssumptions productionAssumptions;
		public DevAndConstruction devAndConstruction;
		public Taxes taxes;
		public Depreciation depreciation;
		public OperationCosts operationCosts;
		public EquityStructure equityStructure;
		public TransactionDetails transactionDetails;
		public RevenueDetails revenueDetails;
	}

	public class RevenueDetails {
		public AnnualSchedule srec_rate;
		public QuarterlySchedule incentive_by_quarter;
		public AnnualSchedule incentive_by_year;
		public AnnualSchedule capacity_payments_by_year;
		public QuarterlySchedule other_rate_by_quarter;
		public AnnualSchedule other_rate_by_year;
	}

	public class Variables {
		public InputSet assumptionSet;
		public List<InputSet> inputSet;
		public InputSet overrides;
	}

	public String query;
	public Variables variables;

	public class Depreciation {
		public List<DepreciationPortion> table;
	}

	public class Taxes {
		public Double itc_eligibility;
		public Double income_tax_rate;
	}

	public class SystemDetails {
		public Double dc_size;
		public Double ac_size;
		public Integer number_of_meters;
		public Double bess_capacity;
	}

	public class TransactionDetails {
		public Double class_a_advance_rate;
	}

	public static ModelRequestPayload parse(String json) {
		return (ModelRequestPayload) System.JSON.deserialize(json, ModelRequestPayload.class);
	}

	public static String serialize(ModelRequestPayload instance) {
    return System.JSON.serialize(instance, true);
  }
}