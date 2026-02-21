# Irembo Voice AI – Data Analyst Take-Home Assignment

This repository contains SQL logic and analysis queries for the Irembo Voice AI take-home assignment.

## Tools Used
- Postgres (Supabase)
- SQL (required)
- Dashboard mockup: PowerPoint (acceptable per instructions)

## Data Model
The main output is an analysis-ready table:
- `public.fact_voice_ai_sessions`

It combines:
- voice sessions + user attributes
- AI performance metrics
- session-level aggregates from voice turns
- linked applications and outcomes (where available)
- KPI flags: `is_completed`, `has_errors`, `has_ai_friction`, `is_first_time_user`

## How to Run
1. Load the provided CSVs into Supabase tables:
   - `public.raw.users`
   - `public.raw.voice_sessions`
   - `public.raw.voice_turns`
   - `public.raw.voice_ai_metrics`
   - `public.raw.applications`

2. Create the fact table:
   - Run `sql/01_create_fact_voice_ai_sessions.sql`

3. Run analysis queries:
   - Run `sql/02_analysis_queries.sql`

## Outputs
- Dashboard mockup: `docs/dashboard/Voice_AI_Impact_Dashboard_Irembo.pptx`

