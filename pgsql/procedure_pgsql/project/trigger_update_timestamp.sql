-- =========================================================================
-- TRIGGER FUNCTION & BINDINGS: silver.trg_update_timestamp
-- DESCRIPTION: Sets the updated_at timestamp to the current timestamp
--              before a row update occurs on the dimension tables.
-- =========================================================================

CREATE OR REPLACE FUNCTION silver.trg_update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Bind triggers to tables
DROP TRIGGER IF EXISTS trg_customer_update_stamp ON silver.dim_customer;
CREATE TRIGGER trg_customer_update_stamp
BEFORE UPDATE ON silver.dim_customer
FOR EACH ROW
EXECUTE FUNCTION silver.trg_update_timestamp();

DROP TRIGGER IF EXISTS trg_product_update_stamp ON silver.dim_products;
CREATE TRIGGER trg_product_update_stamp
BEFORE UPDATE ON silver.dim_products
FOR EACH ROW
EXECUTE FUNCTION silver.trg_update_timestamp();
