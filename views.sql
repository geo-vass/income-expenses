--Creating views combining employers-income, exp_type-expenses to
-- improve depiction of information and for the purpose of updating/
-- inserting new records

CREATE OR REPLACE VIEW expenses_update_vw AS
 SELECT e.id,
    e.amount,
    e.date_added,
    e.type_id,
    et.eksodo
 FROM expenses e
 FULL JOIN exp_type et ON e.type_id = et.type_id
 ORDER BY e.date_added DESC NULLS LAST;

CREATE OR REPLACE VIEW income_update_vw AS
  SELECT e.employer_name,
	 i.amount,
	 i.date_added,
	 i.emp_id,
	 i.inc_type,
	 i.id
  FROM income i
  FULL JOIN employers e ON i.emp_id = e.emp_id
  ORDER BY i.date_added DESC NULLS LAST;
