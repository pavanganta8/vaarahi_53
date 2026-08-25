-- =========================================================================
-- FUNCTION: silver.clean_price
-- DESCRIPTION: Cleans currency formatted strings (e.g. $120.00) and converts to NUMERIC.
-- =========================================================================

CREATE OR REPLACE FUNCTION silver.clean_price(p_price_str TEXT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_numeric_str TEXT;
BEGIN
    IF p_price_str IS NULL OR TRIM(p_price_str) = '' OR LOWER(TRIM(p_price_str)) = 'free' THEN
        RETURN 0.00;
    END IF;
    
    v_numeric_str := REPLACE(TRIM(p_price_str), '$', '');
    
    BEGIN
        RETURN CAST(v_numeric_str AS NUMERIC(10, 2));
    EXCEPTION WHEN OTHERS THEN
        RETURN 0.00;
    END;
END;
$$;
