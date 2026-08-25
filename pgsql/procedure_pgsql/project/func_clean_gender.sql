-- =========================================================================
-- FUNCTION: silver.clean_gender
-- DESCRIPTION: Standardizes dirty raw gender values into 'Male', 'Female', or 'n/a'.
-- =========================================================================

CREATE OR REPLACE FUNCTION silver.clean_gender(p_gender_str TEXT)
RETURNS VARCHAR 
LANGUAGE plpgsql
AS $$
DECLARE
    v_gender_clean TEXT;
BEGIN
    IF p_gender_str IS NULL THEN
        RETURN 'n/a';
    END IF;
    
    v_gender_clean := LOWER(TRIM(p_gender_str));
    
    IF v_gender_clean IN ('m', 'male') THEN
        RETURN 'Male';
    ELSIF v_gender_clean IN ('f', 'female') THEN
        RETURN 'Female';
    ELSE
        RETURN 'n/a';
    END IF;
END;
$$;
