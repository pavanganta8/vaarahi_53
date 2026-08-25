-- =========================================================================
-- FUNCTION: silver.parse_date_safe
-- DESCRIPTION: Safely parses dates formatted in YYYY-MM-DD, DD-MM-YYYY, or YYYY/MM/DD.
-- =========================================================================

CREATE OR REPLACE FUNCTION silver.parse_date_safe(p_date_str TEXT)
RETURNS DATE
LANGUAGE plpgsql
AS $$
DECLARE
    v_parsed_date DATE;
BEGIN
    IF p_date_str IS NULL OR TRIM(p_date_str) = '' THEN
        RETURN NULL;
    END IF;
    
    BEGIN
        v_parsed_date := TO_DATE(TRIM(p_date_str), 'YYYY-MM-DD');
        RETURN v_parsed_date;
    EXCEPTION WHEN OTHERS THEN
        BEGIN
            v_parsed_date := TO_DATE(TRIM(p_date_str), 'DD-MM-YYYY');
            RETURN v_parsed_date;
        EXCEPTION WHEN OTHERS THEN
            BEGIN
                v_parsed_date := TO_DATE(TRIM(p_date_str), 'YYYY/MM/DD');
                RETURN v_parsed_date;
            EXCEPTION WHEN OTHERS THEN
                RETURN NULL;
            END;
        END;
    END;
END;
$$;
