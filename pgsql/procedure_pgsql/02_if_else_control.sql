-- =========================================================================
-- TUTORIAL: IF-ELSE Control Structures in PL/pgSQL
-- DESCRIPTION: This file demonstrates conditional logic in PL/pgSQL using
--              IF-THEN, IF-THEN-ELSE, IF-THEN-ELSIF, and CASE statements.
-- USAGE: Execute the anonymous block in your PostgreSQL query tool.
-- =========================================================================

DO $$
DECLARE
    v_score       INTEGER := 85;
    v_grade       CHAR(1);
    v_attendance  INTEGER := 92; -- Percentage of attendance
    v_is_eligible BOOLEAN;
BEGIN
    RAISE NOTICE '--- 1. Simple IF-THEN-ELSE ---';
    -- Check if student has passing marks (>= 50)
    IF v_score >= 50 THEN
        RAISE NOTICE 'Score: %. Status: PASSED', v_score;
    ELSE
        RAISE NOTICE 'Score: %. Status: FAILED', v_score;
    END IF;

    RAISE NOTICE '--- 2. IF-THEN-ELSIF-ELSE Chain (Grade Calculation) ---';
    -- Calculate grade based on score
    IF v_score >= 90 THEN
        v_grade := 'A';
    ELSIF v_score >= 80 THEN
        v_grade := 'B';
    ELSIF v_score >= 70 THEN
        v_grade := 'C';
    ELSIF v_score >= 60 THEN
        v_grade := 'D';
    ELSE
        v_grade := 'F';
    END IF;
    
    RAISE NOTICE 'Score: %, Grade: %', v_score, v_grade;

    RAISE NOTICE '--- 3. Nested IF Condition ---';
    -- Check eligibility for exam: Score >= 50 AND attendance >= 75
    IF v_score >= 50 THEN
        IF v_attendance >= 75 THEN
            v_is_eligible := TRUE;
            RAISE NOTICE 'Eligible for graduation. Attendance: %%, Score: %', v_attendance, v_score;
        ELSE
            v_is_eligible := FALSE;
            RAISE NOTICE 'Not eligible due to low attendance. Attendance: %%', v_attendance;
        END IF;
    ELSE
        v_is_eligible := FALSE;
        RAISE NOTICE 'Not eligible due to low score. Score: %', v_score;
    END IF;

    RAISE NOTICE '--- 4. CASE Statements ---';
    -- Similar to switch-case in other programming languages
    CASE v_grade
        WHEN 'A' THEN
            RAISE NOTICE 'Excellent Performance!';
        WHEN 'B', 'C' THEN
            RAISE NOTICE 'Good Performance.';
        WHEN 'D' THEN
            RAISE NOTICE 'Needs Improvement.';
        ELSE
            RAISE NOTICE 'Fail. Please retake the course.';
    END CASE;

END $$;
