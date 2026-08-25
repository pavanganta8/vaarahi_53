-- =========================================================================
-- TUTORIAL: WHILE Loops in PL/pgSQL
-- DESCRIPTION: This file demonstrates how to use WHILE loops in PL/pgSQL
--              to execute code repeatedly as long as a condition remains true.
-- USAGE: Execute the anonymous block in your PostgreSQL query tool.
-- =========================================================================

DO $$
DECLARE
    v_counter INTEGER := 1;
    v_sum     INTEGER := 0;
    v_limit   INTEGER := 5;
BEGIN
    RAISE NOTICE '--- 1. Simple WHILE Loop ---';
    -- The loop runs as long as v_counter is less than or equal to v_limit.
    -- Inside a WHILE loop, we must manually update the loop condition variable (v_counter),
    -- otherwise it will become an infinite loop.
    WHILE v_counter <= v_limit LOOP
        v_sum := v_sum + v_counter;
        RAISE NOTICE 'Counter: %, Current Cumulative Sum: %', v_counter, v_sum;
        
        -- Increment the counter (crucial step!)
        v_counter := v_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Final Sum of numbers from 1 to 5 is: %', v_sum;

    RAISE NOTICE '--- 2. WHILE Loop with EXIT WHEN clause ---';
    -- Resetting values
    v_counter := 1;
    
    -- An alternative way to control/exit the loop
    WHILE TRUE LOOP -- Infinite loop declaration
        RAISE NOTICE 'Loop iteration: %', v_counter;
        
        -- Exit condition
        EXIT WHEN v_counter >= 3;
        
        v_counter := v_counter + 1;
    END LOOP;
    RAISE NOTICE 'Exited infinite loop safely. Final counter value: %', v_counter;

END $$;
