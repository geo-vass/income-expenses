--Corresponding triggers to trigger functions
CREATE TRIGGER phone_update_trigger
    AFTER INSERT OR UPDATE
    ON public.employers
    FOR EACH ROW
    EXECUTE PROCEDURE public.phone_update();

CREATE TRIGGER new_entry_date_exp_trig
    AFTER INSERT OR UPDATE
    ON public.expenses
    FOR EACH ROW
    EXECUTE PROCEDURE public.new_entry_date_exp();

CREATE TRIGGER new_entry_date_trigger
    AFTER INSERT OR UPDATE
    ON public.income
    FOR EACH ROW
    EXECUTE PROCEDURE public.new_entry_date();

CREATE TRIGGER expenses_update_vw_trigger
    INSTEAD OF INSERT OR DELETE OR UPDATE
    ON public.expenses_update_vw
    FOR EACH ROW
    EXECUTE PROCEDURE public.expenses_update_func();

CREATE TRIGGER income_update_vw_trigger
    INSTEAD OF INSERT OR DELETE OR UPDATE
    ON public.income_update_vw
    FOR EACH ROW
    EXECUTE PROCEDURE public.income_update_func();
