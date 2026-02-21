/*
===============================================================================
FILE: 02_analysis_queries.sql

PURPOSE:
Analysis queries supporting KPI monitoring and Voice AI effectiveness insights.

Supports assignment Parts:
- Part 1: KPI Monitoring
- Part 3: Insight Generation
- Part 4: Error Rate Measurement

AUTHOR: Mahdi Mohammed
===============================================================================
*/

-- ============================================================================
-- KPI SUMMARY
-- ============================================================================

SELECT

    COUNT(*) AS total_sessions,

    ROUND(
        100.0 * SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS completion_rate_percent,

    ROUND(
        100.0 * SUM(CASE WHEN has_errors THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS error_rate_percent,

    ROUND(
        100.0 * SUM(CASE WHEN has_ai_friction THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS ai_friction_rate_percent,

    ROUND(AVG(total_duration_sec), 2) AS avg_session_duration_seconds,

    ROUND(AVG(application_completion_minutes), 2) AS avg_application_completion_minutes

FROM public.fact_voice_ai_sessions;



-- ============================================================================
-- COMPLETION RATE BY CHANNEL (Voice vs Web vs USSD)
-- ============================================================================

SELECT

    application_channel,

    COUNT(*) AS total_applications,

    SUM(CASE WHEN application_status = 'completed' THEN 1 ELSE 0 END)
        AS completed_applications,

    ROUND(
        100.0 * SUM(CASE WHEN application_status = 'completed' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS completion_rate_percent

FROM public.fact_voice_ai_sessions

WHERE application_id IS NOT NULL

GROUP BY application_channel

ORDER BY completion_rate_percent DESC;



-- ============================================================================
-- COMPLETION RATE BY REGION (Rural vs Urban)
-- ============================================================================

SELECT

    region,

    COUNT(*) AS total_sessions,

    SUM(CASE WHEN is_completed THEN 1 ELSE 0 END)
        AS completed_sessions,

    ROUND(
        100.0 * SUM(CASE WHEN is_completed THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS completion_rate_percent

FROM public.fact_voice_ai_sessions

GROUP BY region

ORDER BY completion_rate_percent DESC;



-- ============================================================================
-- COMPLETION RATE BY FIRST-TIME DIGITAL USER STATUS
-- ============================================================================

SELECT

    is_first_time_user,

    COUNT(*) AS total_sessions,

    SUM(CASE WHEN is_completed THEN 1 ELSE 0 END)
        AS completed_sessions,

    ROUND(
        100.0 * SUM(CASE WHEN is_completed THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS completion_rate_percent

FROM public.fact_voice_ai_sessions

GROUP BY is_first_time_user

ORDER BY completion_rate_percent DESC;



-- ============================================================================
-- AI FRICTION RATE ANALYSIS
-- ============================================================================

SELECT

    COUNT(*) AS total_sessions,

    SUM(CASE WHEN has_ai_friction THEN 1 ELSE 0 END)
        AS friction_sessions,

    ROUND(
        100.0 * SUM(CASE WHEN has_ai_friction THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS friction_rate_percent

FROM public.fact_voice_ai_sessions;



-- ============================================================================
-- TOP TRANSFER REASONS (FRICTION POINT ANALYSIS)
-- ============================================================================

SELECT

    transfer_reason,

    COUNT(*) AS transfer_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percent_of_transfers

FROM public.fact_voice_ai_sessions

WHERE is_transferred = TRUE

GROUP BY transfer_reason

ORDER BY transfer_count DESC;



-- ============================================================================
-- SESSION OUTCOME DISTRIBUTION
-- ============================================================================

SELECT

    final_outcome,

    COUNT(*) AS session_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percent_of_sessions

FROM public.fact_voice_ai_sessions

GROUP BY final_outcome

ORDER BY session_count DESC;



-- ============================================================================
-- ERROR TYPE DISTRIBUTION (INTERACTION LEVEL)
-- ============================================================================

SELECT

    error_type,

    COUNT(*) AS error_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percent_of_errors

FROM public."raw.voice_turns"

WHERE error_type IS NOT NULL

GROUP BY error_type

ORDER BY error_count DESC;



-- ============================================================================
-- AI PERFORMANCE ANALYSIS
-- ============================================================================

SELECT

    ROUND(AVG(avg_asr_confidence), 3) AS avg_asr_confidence,

    ROUND(AVG(avg_intent_confidence), 3) AS avg_intent_confidence,

    ROUND(AVG(misunderstanding_rate), 3) AS avg_misunderstanding_rate,

    ROUND(AVG(silence_rate), 3) AS avg_silence_rate

FROM public.fact_voice_ai_sessions;



-- ============================================================================
-- ACCESSIBILITY ANALYSIS (FIRST-TIME USERS BY REGION)
-- ============================================================================

SELECT

    region,

    is_first_time_user,

    COUNT(*) AS session_count,

    ROUND(
        100.0 * SUM(CASE WHEN is_completed THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS completion_rate_percent

FROM public.fact_voice_ai_sessions

GROUP BY region, is_first_time_user

ORDER BY region, completion_rate_percent DESC;
