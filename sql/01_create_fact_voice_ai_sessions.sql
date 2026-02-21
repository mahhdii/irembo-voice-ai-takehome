/*
===============================================================================
FILE: 01_create_fact_voice_ai_sessions.sql

PURPOSE:
Creates an analysis-ready fact table for Voice AI session analytics.

This table combines:

- voice_sessions (core session data)
- users (demographics & accessibility indicators)
- voice_ai_metrics (AI performance metrics)
- voice_turns (interaction-level aggregation)
- applications (service application outcomes)

This model supports KPI reporting for:
- Accessibility / Inclusivity
- Efficiency
- Adoption
- AI performance and friction monitoring

AUTHOR: Mahdi Mohammed
===============================================================================
*/

-- Drop existing table to allow clean recreation
DROP TABLE IF EXISTS public.fact_voice_ai_sessions;

-- Create analysis-ready fact table
CREATE TABLE public.fact_voice_ai_sessions AS

-- ============================================================================
-- Aggregate interaction-level voice turns
-- ============================================================================
WITH turns_agg AS (
    SELECT
        session_id,

        COUNT(*) AS total_turns,

        SUM(CASE WHEN speaker = 'user' THEN 1 ELSE 0 END) AS user_turns,

        SUM(CASE WHEN speaker = 'system' THEN 1 ELSE 0 END) AS system_turns,

        SUM(CASE WHEN error_type IS NOT NULL THEN 1 ELSE 0 END) AS error_turns,

        AVG(asr_confidence) AS avg_asr_conf_turns,

        AVG(intent_confidence) AS avg_intent_conf_turns

    FROM public."raw.voice_turns"
    GROUP BY session_id
),

-- ============================================================================
-- Prepare applications table with completion duration calculation
-- ============================================================================
app_join AS (
    SELECT
        session_id,

        application_id,

        channel AS application_channel,

        service_code,

        status AS application_status,

        submitted_at AS application_submitted_at,

        completed_at AS application_completed_at,

        CASE
            WHEN completed_at IS NOT NULL
                 AND submitted_at IS NOT NULL
            THEN EXTRACT(EPOCH FROM (completed_at - submitted_at)) / 60
            ELSE NULL
        END AS application_completion_minutes

    FROM public."raw.applications"
)

-- ============================================================================
-- Final fact table construction
-- ============================================================================
SELECT

    -- ========================
    -- Primary keys
    -- ========================
    s.session_id,
    s.user_id,
    a.application_id,

    -- ========================
    -- User attributes
    -- ========================
    u.region,
    u.disability_flag,
    u.first_time_digital_user,

    -- ========================
    -- Session attributes
    -- ========================
    s.channel AS session_channel,
    s.language,
    s.total_duration_sec,
    s.total_turns AS reported_turns,
    s.final_outcome,
    s.transfer_reason,
    s.created_at AS session_created_at,

    -- ========================
    -- Session outcome flags
    -- ========================
    CASE
        WHEN s.final_outcome = 'completed' THEN TRUE
        ELSE FALSE
    END AS is_completed,

    CASE
        WHEN s.final_outcome = 'transferred' THEN TRUE
        ELSE FALSE
    END AS is_transferred,

    CASE
        WHEN s.final_outcome = 'abandoned' THEN TRUE
        ELSE FALSE
    END AS is_abandoned,

    -- ========================
    -- Interaction aggregates
    -- ========================
    t.total_turns AS actual_turns,
    t.user_turns,
    t.system_turns,
    t.error_turns,
    t.avg_asr_conf_turns,
    t.avg_intent_conf_turns,

    -- ========================
    -- AI performance metrics
    -- ========================
    m.avg_asr_confidence,
    m.avg_intent_confidence,
    m.misunderstanding_rate,
    m.silence_rate,

    -- ========================
    -- Application attributes
    -- ========================
    a.application_channel,
    a.service_code,
    a.application_status,
    a.application_submitted_at,
    a.application_completed_at,
    a.application_completion_minutes,

    -- ========================
    -- KPI flags
    -- ========================
    CASE
        WHEN t.error_turns > 0 THEN TRUE
        ELSE FALSE
    END AS has_errors,

    CASE
        WHEN m.avg_asr_confidence < 0.7
          OR m.avg_intent_confidence < 0.7
          OR t.error_turns > 0
          OR m.misunderstanding_rate > 0.2
        THEN TRUE
        ELSE FALSE
    END AS has_ai_friction,

    CASE
        WHEN u.first_time_digital_user = 'yes'
        THEN TRUE
        ELSE FALSE
    END AS is_first_time_user

FROM public."raw.voice_sessions" s

LEFT JOIN public."raw.users" u
    ON s.user_id = u.user_id

LEFT JOIN public."raw.voice_ai_metrics" m
    ON s.session_id = m.session_id

LEFT JOIN turns_agg t
    ON s.session_id = t.session_id

LEFT JOIN app_join a
    ON s.session_id = a.session_id;
