--Employer table. Making sure every employer name is unique
CREATE TABLE employers
(
    emp_id bigint NOT NULL DEFAULT nextval('employers_seq'::regclass),
    employer_name character varying(30),
    address character varying(30),
    phone character varying(20) ,
    info text ,
    contact_person character varying(30),
    CONSTRAINT employers_pkey PRIMARY KEY (emp_id),
    CONSTRAINT employer_name_dist UNIQUE (employer_name)

)

--Income table. Records reference the employers table. Restricting the deletion
--of employers so that records here are not orphaned
CREATE TABLE income
(
    id bigint NOT NULL DEFAULT nextval('incomes_seq'::regclass),
    amount numeric(10,2) NOT NULL,
    date_added date,
    emp_id integer NOT NULL,
    inc_type character varying(30) ,
    CONSTRAINT income_pkey PRIMARY KEY (id),
    CONSTRAINT income_emp_id_fkey FOREIGN KEY (emp_id)
        REFERENCES employers (emp_id)
        ON DELETE RESTRICT
)
--Expense type table. Making sure we have unique expense names
CREATE TABLE exp_type
(
    type_id bigint NOT NULL DEFAULT nextval('exp_type_type_id_seq'::regclass),
    eksodo character varying(30),
    info text ,
    CONSTRAINT exp_type_pkey PRIMARY KEY (type_id),
    CONSTRAINT exp_type_eksodo_key UNIQUE (eksodo)

)
--Expenses table. Just like the income table making sure records are not
--orphaned
CREATE TABLE expenses
(
    id bigint NOT NULL DEFAULT nextval('expenses_id_seq'::regclass),
    amount numeric(10,2) NOT NULL,
    date_added date,
    type_id integer NOT NULL,
    CONSTRAINT expenses_pkey PRIMARY KEY (id),
    CONSTRAINT expenses_type_id_fkey FOREIGN KEY (type_id)
        REFERENCES exp_type (type_id)
        ON DELETE RESTRICT
)
