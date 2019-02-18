-- Using regular expressions to correct the employer's phone number
-- when inserted by the user for the purposes of conformity
CREATE OR REPLACE FUNCTION proper_phone(val character varying)
      RETURNS character varying
      LANGUAGE 'plpgsql'
    AS $BODY$
	  DECLARE res varchar(30);
  	BEGIN
		  SELECT array_to_string(regexp_matches($1,'^(?:\+30)?\s?(\d{3,5})[-\.\s]*(\d{5,7})$'),'') INTO res;
	     RETURN res;
	  END; $BODY$;

--Just a helper function returning an integer array for the set year
--calculating income,expenses,difference between them
CREATE OR REPLACE FUNCTION period_calc(year integer)
      RETURNS integer[]
      LANGUAGE 'plpgsql'
    AS $BODY$
    DECLARE
      res integer ARRAY[3];
    BEGIN
      SELECT sum(amount)
      FROM expenses
      WHERE date_part('year', date_added) = $1 INTO res[1]::integer;
      SELECT sum(amount)
      FROM income
      WHERE date_part('year', date_added) = $1 INTO res[2]::integer;
      res[3] = res[2]-res[1];
      RETURN res;
    END
    $BODY$;

-- Overloading period_calc in case the user needs info for a specific month/year
CREATE OR REPLACE FUNCTION period_calc(month integer,year integer)
      RETURNS integer[]
      LANGUAGE 'plpgsql'
    AS $BODY$
    DECLARE
    	res integer ARRAY[3];
    BEGIN
    	SELECT sum(amount)
    	FROM expenses
    	WHERE date_part('month', date_added) = $1 AND date_part('year', date_added) = $2 INTO res[1]::integer;
    	SELECT sum(amount)
    	FROM income
    	WHERE date_part('month', date_added) = $1 AND date_part('year', date_added) = $2 INTO res[2]::integer;
    	res[3] = res[2] - res[1];
    	RETURN res;
    END
    $BODY$;

-- Declaring a new type of data
CREATE TYPE mytype AS
(
  list character varying,
  amount numeric(10,2)
);
-- Using period_calc we put "tags" on our results returning mytype set of rows
CREATE OR REPLACE FUNCTION balance_calc(year integer)
    RETURNS SETOF mytype
    LANGUAGE 'plpgsql'
AS $BODY$
		DECLARE
		res1  varchar ARRAY  DEFAULT  ARRAY['income', 'expenses', 'balance'];
		res2 integer ARRAY[3];
		r mytype%rowtype;
		i int; expenses int; income int;
		BEGIN
		SELECT period_calc($1) INTO res2;
		for i IN 1 .. 3 loop
			r.list = res1[i];
			r.amount = res2[i];
			return next r;
		end loop;
		return;
END
$BODY$;

--Overloading balance_calc if we want a specific month
CREATE OR REPLACE FUNCTION balance_calc(month integer,year integer)
    RETURNS SETOF mytype
    LANGUAGE 'plpgsql'
AS $BODY$
		DECLARE
		res1  varchar ARRAY  DEFAULT  ARRAY['income', 'expenses', 'balance'];
		res2 integer ARRAY[3];
		r mytype%rowtype;
		i int; expenses int; income int;
		BEGIN
		SELECT period_calc($1,$2) INTO res2;
		for i IN 1 .. 3 loop
			r.list = res1[i];
			r.amount = res2[i];
			return next r;
		end loop;
		return;
END
$BODY$;
--When the user inserts,updates or deletes expenses_update_vw, this trigger
--function ensures the proper update of the tables
CREATE FUNCTION expenses_update_func()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$DECLARE tp int;
	BEGIN
	  IF NEW.amount < 0 THEN
			NEW.amount = 0;
		END IF;

		IF TG_OP = 'INSERT' THEN
			SELECT type_id FROM exp_type WHERE eksodo = NEW.eksodo INTO tp;
			INSERT INTO expenses(amount,date_added,type_id) VALUES (NEW.amount,NEW.date_added,tp);
			RETURN NEW;

		ELSIF TG_OP = 'UPDATE' THEN
			IF NEW.eksodo <> OLD.eksodo THEN
				SELECT type_id FROM exp_type WHERE eksodo = NEW.eksodo INTO tp;
			ELSE
				SELECT type_id FROM exp_type WHERE eksodo = OLD.eksodo INTO tp;
			END IF;
			UPDATE expenses SET amount=NEW.amount,date_added=NEW.date_added,type_id=tp
			WHERE id=NEW.id;
			RETURN NEW;

		ELSIF TG_OP = 'DELETE' THEN
			DELETE FROM expenses WHERE id=OLD.id;
			RETURN NEW;
		END IF;

	END;
	$BODY$;

  --When the user inserts,updates or deletes income_update_vw, this trigger
  --function ensures the proper update of the tables
CREATE FUNCTION income_update_func()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    AS $BODY$DECLARE emp int;
	  BEGIN
		  IF NEW.amount < 0 THEN
			   NEW.amount = 0;
		  END IF;
		  IF TG_OP = 'INSERT' THEN
			   SELECT emp_id FROM employers WHERE employer_name = NEW.employer_name INTO emp;
			   INSERT INTO income(amount,date_added,emp_id,inc_type) VALUES (NEW.amount,NEW.date_added,emp,NEW.inc_type);
			   RETURN NEW;

		  ELSIF TG_OP = 'UPDATE' THEN
			   IF NEW.employer_name <> OLD.employer_name THEN
				     SELECT emp_id FROM employers WHERE employer_name = NEW.employer_name INTO emp;
			   ELSE
				     SELECT emp_id FROM employers WHERE employer_name = OLD.employer_name INTO emp;
			   END IF;
			   UPDATE income SET amount=NEW.amount,date_added=NEW.date_added,emp_id=emp,inc_type=NEW.inc_type
			   WHERE id=NEW.id;
			   RETURN NEW;

		  ELSIF TG_OP = 'DELETE' THEN
			   DELETE FROM income WHERE id=OLD.id;
			   RETURN NEW;
		  END IF;
	  END;
	  $BODY$;

-- This is a helper trigger function when updating income.
-- If the user doesnt specify the date ormistakingly types a future date,
--date for the entry is set to current
CREATE FUNCTION new_entry_date()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    AS $BODY$
    BEGIN
      IF NEW.date_added IS NULL OR NEW.date_added > now()::date   THEN
 	      UPDATE income
  	    SET date_added=now()::date
  	    WHERE id=NEW.id;
      END IF;
      RETURN NEW;
    END;
    $BODY$;

--Same as previous for expenses
CREATE FUNCTION new_entry_date_exp()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    AS $BODY$
    BEGIN
      IF NEW.date_added IS NULL OR NEW.date_added > now()::date   THEN
 	      UPDATE expenses
  	    SET date_added=now()::date
  	    WHERE id=NEW.id;
      END IF;
      RETURN NEW;
    END;
    $BODY$;

-- Using proper_phone function to update phone number
CREATE FUNCTION phone_update()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    AS $BODY$
  	BEGIN
  		IF NEW.phone <> OLD.phone OR OLD.phone IS NULL THEN
  			UPDATE employers
  			SET phone = proper_phone(NEW.phone)
  			WHERE emp_id=NEW.emp_id;
  		END IF;
  		RETURN NEW;
  	END;
  	$BODY$;
