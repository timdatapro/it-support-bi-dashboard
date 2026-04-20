-- =============================================================
-- IT Support Dashboard -- Validation & Analytics Queries
-- Database: PostgreSQL (edtech_support)
-- Table: public.support_tickets
-- =============================================================


-- =============================================================
-- SECTION 1: SCHEMA VALIDATION
-- =============================================================

-- Q-001: Column structure with nullability summary
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'support_tickets'
ORDER BY ordinal_position;


-- Q-002: Constraints with type labels
SELECT
    conname AS constraint_name,
    CASE contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'c' THEN 'CHECK'
        WHEN 'u' THEN 'UNIQUE'
    END AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.support_tickets'::regclass
ORDER BY contype;


-- Q-003: Index usage stats (requires pg_stat_user_indexes)
SELECT
    i.indexname,
    i.indexdef,
    s.idx_scan   AS times_used,
    s.idx_tup_read,
    s.idx_tup_fetch
FROM pg_indexes i
LEFT JOIN pg_stat_user_indexes s
       ON s.indexrelname = i.indexname
      AND s.schemaname   = i.schemaname
WHERE i.schemaname = 'public'
  AND i.tablename  = 'support_tickets'
ORDER BY s.idx_scan DESC NULLS LAST;


-- =============================================================
-- SECTION 2: COMPLETENESS AND NULL AUDIT
-- =============================================================

-- Q-004: NULL audit across all columns with percentage
WITH total AS (
    SELECT COUNT(*) AS n FROM public.support_tickets
)
SELECT
    col,
    null_cnt,
    ROUND(null_cnt * 100.0 / t.n, 2) AS null_pct,
    t.n - null_cnt                   AS filled_cnt
FROM total t
CROSS JOIN LATERAL (
    VALUES
        ('ticket_id',                   COUNT(*) FILTER (WHERE ticket_id IS NULL)),
        ('created_at',                  COUNT(*) FILTER (WHERE created_at IS NULL)),
        ('resolved_at',                 COUNT(*) FILTER (WHERE resolved_at IS NULL)),
        ('closed_at',                   COUNT(*) FILTER (WHERE closed_at IS NULL)),
        ('hours',                       COUNT(*) FILTER (WHERE hours IS NULL)),
        ('status',                      COUNT(*) FILTER (WHERE status IS NULL)),
        ('employee_name',               COUNT(*) FILTER (WHERE employee_name IS NULL)),
        ('employee_department',         COUNT(*) FILTER (WHERE employee_department IS NULL)),
        ('agent_name',                  COUNT(*) FILTER (WHERE agent_name IS NULL)),
        ('category_name',               COUNT(*) FILTER (WHERE category_name IS NULL)),
        ('priority_id',                 COUNT(*) FILTER (WHERE priority_id IS NULL)),
        ('sla_target_hours',            COUNT(*) FILTER (WHERE sla_target_hours IS NULL)),
        ('is_sla_breached',             COUNT(*) FILTER (WHERE is_sla_breached IS NULL)),
        ('is_first_contact_resolution', COUNT(*) FILTER (WHERE is_first_contact_resolution IS NULL)),
        ('original_ticket_id',          COUNT(*) FILTER (WHERE original_ticket_id IS NULL)),
        ('project_name',                COUNT(*) FILTER (WHERE project_name IS NULL))
) AS nulls(col, null_cnt)
ORDER BY null_pct DESC;


-- =============================================================
-- SECTION 3: DISTRIBUTION AND VOLUME
-- =============================================================

-- Q-005: Status distribution with running total
WITH counts AS (
    SELECT
        status,
        COUNT(*) AS cnt
    FROM public.support_tickets
    GROUP BY status
)
SELECT
    status,
    cnt,
    ROUND(cnt * 100.0 / SUM(cnt) OVER (), 1)              AS pct,
    SUM(cnt) OVER (ORDER BY cnt DESC ROWS UNBOUNDED PRECEDING) AS running_total
FROM counts
ORDER BY cnt DESC;


-- Q-006: Priority distribution with cumulative share
WITH counts AS (
    SELECT
        priority_id,
        COUNT(*) AS cnt
    FROM public.support_tickets
    GROUP BY priority_id
)
SELECT
    priority_id,
    cnt,
    ROUND(cnt * 100.0 / SUM(cnt) OVER (), 1)                          AS pct,
    ROUND(SUM(cnt) OVER (ORDER BY cnt DESC) * 100.0 / SUM(cnt) OVER (), 1) AS cumulative_pct
FROM counts
ORDER BY cnt DESC;


-- Q-007: Agent workload with rank and deviation from mean
WITH agent_stats AS (
    SELECT
        agent_name,
        COUNT(*)                                                        AS total_tickets,
        COUNT(*) FILTER (WHERE status IN ('Open','In Progress','Waiting for Approval')) AS active_tickets,
        COUNT(*) FILTER (WHERE status = 'Resolved')                    AS resolved_tickets
    FROM public.support_tickets
    GROUP BY agent_name
)
SELECT
    agent_name,
    total_tickets,
    active_tickets,
    resolved_tickets,
    RANK() OVER (ORDER BY total_tickets DESC)                          AS volume_rank,
    ROUND(AVG(total_tickets) OVER (), 1)                               AS team_avg,
    total_tickets - ROUND(AVG(total_tickets) OVER (), 0)               AS deviation_from_avg,
    ROUND(total_tickets * 100.0 / SUM(total_tickets) OVER (), 1)      AS share_pct
FROM agent_stats
ORDER BY total_tickets DESC;


-- =============================================================
-- SECTION 4: SLA DEEP ANALYSIS
-- =============================================================

-- Q-008: SLA compliance rate mirroring DAX logic exactly
-- is_sla_breached is NULL for active tickets, excluded from both numerator and denominator
WITH sla_base AS (
    SELECT
        COUNT(*) FILTER (WHERE is_sla_breached IS NOT NULL)  AS sla_total,
        COUNT(*) FILTER (WHERE is_sla_breached = FALSE)      AS sla_met,
        COUNT(*) FILTER (WHERE is_sla_breached = TRUE)       AS sla_breached
    FROM public.support_tickets
)
SELECT
    sla_total,
    sla_met,
    sla_breached,
    ROUND(sla_met    * 100.0 / NULLIF(sla_total, 0), 1) AS compliance_pct,
    ROUND(sla_breached * 100.0 / NULLIF(sla_total, 0), 1) AS breach_pct,
    0.70 AS target_pct,
    ROUND((sla_met * 1.0 / NULLIF(sla_total, 0)) - 0.70, 3) AS gap_to_target
FROM sla_base;


-- Q-009: SLA compliance by priority with gap to target
WITH sla_by_priority AS (
    SELECT
        priority_id,
        sla_target_hours,
        COUNT(*) FILTER (WHERE is_sla_breached IS NOT NULL) AS total,
        COUNT(*) FILTER (WHERE is_sla_breached = FALSE)     AS met
    FROM public.support_tickets
    GROUP BY priority_id, sla_target_hours
)
SELECT
    priority_id,
    sla_target_hours,
    met,
    total,
    ROUND(met * 100.0 / NULLIF(total, 0), 1)               AS compliance_pct,
    ROUND((met * 1.0 / NULLIF(total, 0) - 0.70) * 100, 1) AS gap_pp,
    RANK() OVER (ORDER BY met * 1.0 / NULLIF(total, 0) DESC) AS sla_rank
FROM sla_by_priority
ORDER BY sla_target_hours;


-- Q-010: SLA compliance by agent with percentile rank
WITH agent_sla AS (
    SELECT
        agent_name,
        COUNT(*) FILTER (WHERE is_sla_breached IS NOT NULL) AS total,
        COUNT(*) FILTER (WHERE is_sla_breached = FALSE)     AS met
    FROM public.support_tickets
    GROUP BY agent_name
),
agent_rates AS (
    SELECT
        agent_name,
        total,
        met,
        ROUND(met * 100.0 / NULLIF(total, 0), 1) AS sla_pct
    FROM agent_sla
)
SELECT
    agent_name,
    sla_pct,
    met,
    total,
    RANK() OVER (ORDER BY sla_pct DESC)                       AS sla_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY sla_pct) * 100, 0)   AS percentile,
    ROUND(sla_pct - AVG(sla_pct) OVER (), 1)                 AS vs_team_avg
FROM agent_rates
ORDER BY sla_pct DESC;


-- Q-011: Monthly SLA trend with month-over-month delta
WITH monthly_sla AS (
    SELECT
        DATE_TRUNC('month', created_at)                         AS month,
        COUNT(*) FILTER (WHERE is_sla_breached IS NOT NULL)     AS total,
        COUNT(*) FILTER (WHERE is_sla_breached = FALSE)         AS met
    FROM public.support_tickets
    GROUP BY 1
),
with_rate AS (
    SELECT
        month,
        total,
        met,
        ROUND(met * 100.0 / NULLIF(total, 0), 1) AS sla_pct
    FROM monthly_sla
)
SELECT
    TO_CHAR(month, 'Mon YYYY')  AS period,
    sla_pct,
    total,
    LAG(sla_pct) OVER (ORDER BY month)              AS prev_month_pct,
    ROUND(sla_pct - LAG(sla_pct) OVER (ORDER BY month), 1) AS mom_delta,
    CASE
        WHEN sla_pct >= 70 THEN 'On Target'
        WHEN sla_pct >= 65 THEN 'At Risk'
        ELSE 'Below Target'
    END AS status_flag
FROM with_rate
ORDER BY month;


-- =============================================================
-- SECTION 5: FCR DEEP ANALYSIS
-- =============================================================

-- Q-012: FCR rate mirroring DAX logic
SELECT
    COUNT(*) FILTER (WHERE is_first_contact_resolution = TRUE)  AS fcr_met,
    COUNT(*)                                                     AS total,
    ROUND(
        COUNT(*) FILTER (WHERE is_first_contact_resolution = TRUE) * 100.0 / COUNT(*),
        1
    )                                                            AS fcr_pct,
    ROUND(
        (COUNT(*) FILTER (WHERE is_first_contact_resolution = TRUE) * 1.0 / COUNT(*) - 0.60) * 100,
        1
    )                                                            AS gap_to_target_pp
FROM public.support_tickets;


-- Q-013: FCR by agent with rolling 3-month average
WITH monthly_fcr AS (
    SELECT
        agent_name,
        DATE_TRUNC('month', created_at)                                      AS month,
        COUNT(*) FILTER (WHERE is_first_contact_resolution = TRUE)           AS fcr_met,
        COUNT(*)                                                             AS total
    FROM public.support_tickets
    GROUP BY agent_name, DATE_TRUNC('month', created_at)
),
with_rate AS (
    SELECT
        agent_name,
        month,
        ROUND(fcr_met * 100.0 / NULLIF(total, 0), 1) AS fcr_pct,
        total
    FROM monthly_fcr
)
SELECT
    agent_name,
    TO_CHAR(month, 'Mon YYYY')                                            AS period,
    fcr_pct,
    ROUND(
        AVG(fcr_pct) OVER (
            PARTITION BY agent_name
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        1
    )                                                                     AS rolling_3m_avg,
    total
FROM with_rate
ORDER BY agent_name, month;


-- =============================================================
-- SECTION 6: RESOLUTION TIME ANALYTICS
-- =============================================================

-- Q-014: Resolution time distribution with percentiles
SELECT
    ROUND(AVG(hours)::NUMERIC, 1)                                               AS avg_hours,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY hours)::NUMERIC, 1)     AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY hours)::NUMERIC, 1)     AS median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY hours)::NUMERIC, 1)     AS p75,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY hours)::NUMERIC, 1)     AS p90,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY hours)::NUMERIC, 1)     AS p95,
    ROUND(MIN(hours)::NUMERIC, 1)                                               AS min_hours,
    ROUND(MAX(hours)::NUMERIC, 1)                                               AS max_hours,
    ROUND(STDDEV(hours)::NUMERIC, 1)                                            AS stddev_hours
FROM public.support_tickets
WHERE status = 'Resolved'
  AND hours IS NOT NULL
  AND hours > 0;


-- Q-015: Resolution time by priority vs SLA target with breach analysis
WITH resolved AS (
    SELECT
        priority_id,
        sla_target_hours,
        hours,
        CASE WHEN hours > sla_target_hours THEN 1 ELSE 0 END AS is_over_sla
    FROM public.support_tickets
    WHERE status = 'Resolved'
      AND hours IS NOT NULL
      AND hours > 0
)
SELECT
    priority_id,
    sla_target_hours,
    COUNT(*)                                                                    AS resolved_cnt,
    ROUND(AVG(hours)::NUMERIC, 1)                                              AS avg_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY hours)::NUMERIC, 1)     AS median_hours,
    ROUND(AVG(hours - sla_target_hours)::NUMERIC, 1)                          AS avg_overage_hours,
    SUM(is_over_sla)                                                           AS over_sla_cnt,
    ROUND(SUM(is_over_sla) * 100.0 / COUNT(*), 1)                             AS over_sla_pct
FROM resolved
GROUP BY priority_id, sla_target_hours
ORDER BY sla_target_hours;


-- Q-016: Agent resolution time with z-score to flag outliers
WITH agent_hours AS (
    SELECT
        agent_name,
        AVG(hours)    AS avg_hours,
        STDDEV(hours) AS stddev_hours,
        COUNT(*)      AS cnt
    FROM public.support_tickets
    WHERE status = 'Resolved'
      AND hours IS NOT NULL
      AND hours > 0
    GROUP BY agent_name
),
team_stats AS (
    SELECT
        AVG(avg_hours)    AS team_avg,
        STDDEV(avg_hours) AS team_stddev
    FROM agent_hours
)
SELECT
    a.agent_name,
    ROUND(a.avg_hours::NUMERIC, 1)                                         AS avg_hours,
    ROUND(a.stddev_hours::NUMERIC, 1)                                      AS stddev_hours,
    a.cnt,
    ROUND(t.team_avg::NUMERIC, 1)                                          AS team_avg,
    ROUND((a.avg_hours - t.team_avg) / NULLIF(t.team_stddev, 0), 2)       AS z_score,
    CASE
        WHEN (a.avg_hours - t.team_avg) / NULLIF(t.team_stddev, 0) > 1.5  THEN 'Slow outlier'
        WHEN (a.avg_hours - t.team_avg) / NULLIF(t.team_stddev, 0) < -1.5 THEN 'Fast outlier'
        ELSE 'Normal'
    END AS performance_flag
FROM agent_hours a
CROSS JOIN team_stats t
ORDER BY a.avg_hours DESC;


-- =============================================================
-- SECTION 7: TIME PATTERN ANALYSIS (HEATMAP SOURCE)
-- =============================================================

-- Q-017: Ticket volume by day of week and hour bin (heatmap)
WITH hour_bins AS (
    SELECT
        ticket_id,
        CASE EXTRACT(DOW FROM created_at)
            WHEN 1 THEN 'Mon'
            WHEN 2 THEN 'Tue'
            WHEN 3 THEN 'Wed'
            WHEN 4 THEN 'Thu'
            WHEN 5 THEN 'Fri'
        END AS weekday,
        EXTRACT(DOW FROM created_at) AS day_num,
        CASE
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 9  AND 11 THEN '9-11 AM'
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 14 THEN '12-2 PM'
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 15 AND 17 THEN '3-5 PM'
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 20 THEN '6-8 PM'
            WHEN EXTRACT(HOUR FROM created_at) >= 21              THEN '9-11 PM'
        END AS hour_bin,
        CASE
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 9  AND 11 THEN 1
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 14 THEN 2
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 15 AND 17 THEN 3
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 20 THEN 4
            WHEN EXTRACT(HOUR FROM created_at) >= 21              THEN 5
        END AS hour_sort
    FROM public.support_tickets
    WHERE EXTRACT(DOW FROM created_at) BETWEEN 1 AND 5
)
SELECT
    hour_bin,
    hour_sort,
    weekday,
    day_num,
    COUNT(*)                                                   AS ticket_cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)        AS share_pct,
    MAX(COUNT(*)) OVER ()                                      AS global_max,
    ROUND(COUNT(*) * 100.0 / MAX(COUNT(*)) OVER (), 0)        AS pct_of_peak
FROM hour_bins
GROUP BY hour_bin, hour_sort, weekday, day_num
ORDER BY hour_sort, day_num;


-- Q-018: Peak detection with day-over-day comparison within each time slot
WITH daily_counts AS (
    SELECT
        DATE(created_at)                   AS day,
        TO_CHAR(created_at, 'Dy')          AS weekday,
        EXTRACT(DOW FROM created_at)       AS day_num,
        COUNT(*)                           AS cnt
    FROM public.support_tickets
    WHERE EXTRACT(DOW FROM created_at) BETWEEN 1 AND 5
    GROUP BY DATE(created_at), TO_CHAR(created_at, 'Dy'), EXTRACT(DOW FROM created_at)
)
SELECT
    day,
    weekday,
    cnt,
    LAG(cnt)  OVER (ORDER BY day)                                         AS prev_day_cnt,
    cnt - LAG(cnt) OVER (ORDER BY day)                                    AS day_delta,
    ROUND(AVG(cnt) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 1) AS rolling_7d_avg,
    RANK() OVER (ORDER BY cnt DESC)                                       AS busiest_day_rank
FROM daily_counts
ORDER BY day;


-- =============================================================
-- SECTION 8: AGENT PERFORMANCE SCORECARD
-- =============================================================

-- Q-019: Full agent scorecard with composite score
WITH agent_base AS (
    SELECT
        agent_name,
        COUNT(*)                                                                       AS total_tickets,
        COUNT(*) FILTER (WHERE status IN ('Open','In Progress','Waiting for Approval')) AS active_tickets,
        COUNT(*) FILTER (WHERE status = 'Resolved')                                   AS resolved_tickets,
        ROUND(
            COUNT(*) FILTER (WHERE is_sla_breached = FALSE) * 100.0
            / NULLIF(COUNT(*) FILTER (WHERE is_sla_breached IS NOT NULL), 0),
            1
        )                                                                             AS sla_pct,
        ROUND(
            COUNT(*) FILTER (WHERE is_first_contact_resolution = TRUE) * 100.0
            / COUNT(*),
            1
        )                                                                             AS fcr_pct,
        ROUND(
            AVG(hours) FILTER (WHERE status = 'Resolved' AND hours IS NOT NULL AND hours > 0)::NUMERIC,
            1
        )                                                                             AS avg_hours
    FROM public.support_tickets
    GROUP BY agent_name
)
SELECT
    agent_name,
    total_tickets,
    active_tickets,
    resolved_tickets,
    sla_pct,
    fcr_pct,
    avg_hours,
    RANK() OVER (ORDER BY sla_pct DESC)   AS sla_rank,
    RANK() OVER (ORDER BY fcr_pct DESC)   AS fcr_rank,
    RANK() OVER (ORDER BY avg_hours ASC)  AS speed_rank,
    RANK() OVER (ORDER BY total_tickets DESC) AS volume_rank,
    ROUND(
        (PERCENT_RANK() OVER (ORDER BY sla_pct)
        + PERCENT_RANK() OVER (ORDER BY fcr_pct)
        + PERCENT_RANK() OVER (ORDER BY avg_hours DESC)) / 3 * 100,
        0
    )                                     AS composite_score
FROM agent_base
ORDER BY composite_score DESC;


-- =============================================================
-- SECTION 9: DATA INTEGRITY CHECKS
-- =============================================================

-- Q-020: All integrity checks in one query
WITH checks AS (
    SELECT
        'Duplicate ticket_id'                                              AS check_name,
        COUNT(*) - COUNT(DISTINCT ticket_id)                               AS violations
    FROM public.support_tickets

    UNION ALL

    SELECT 'resolved_at before created_at',
        COUNT(*) FILTER (WHERE resolved_at IS NOT NULL AND resolved_at < created_at)
    FROM public.support_tickets

    UNION ALL

    SELECT 'closed_at before created_at',
        COUNT(*) FILTER (WHERE closed_at IS NOT NULL AND closed_at < created_at)
    FROM public.support_tickets

    UNION ALL

    SELECT 'Active ticket with non-NULL hours',
        COUNT(*) FILTER (WHERE status IN ('Open','In Progress','Waiting for Approval') AND hours IS NOT NULL)
    FROM public.support_tickets

    UNION ALL

    SELECT 'Resolved ticket with NULL hours',
        COUNT(*) FILTER (WHERE status = 'Resolved' AND hours IS NULL)
    FROM public.support_tickets

    UNION ALL

    SELECT 'Invalid status value',
        COUNT(*) FILTER (WHERE status NOT IN ('Open','In Progress','Waiting for Approval','Resolved','Canceled'))
    FROM public.support_tickets

    UNION ALL

    SELECT 'Invalid priority value',
        COUNT(*) FILTER (WHERE priority_id NOT IN ('Critical','High','Medium','Low'))
    FROM public.support_tickets

    UNION ALL

    SELECT 'SLA breached flag on active ticket',
        COUNT(*) FILTER (WHERE status IN ('Open','In Progress','Waiting for Approval') AND is_sla_breached IS NOT NULL)
    FROM public.support_tickets

    UNION ALL

    SELECT 'Resolved ticket missing SLA flag',
        COUNT(*) FILTER (WHERE status = 'Resolved' AND is_sla_breached IS NULL)
    FROM public.support_tickets
)
SELECT
    check_name,
    violations,
    CASE WHEN violations = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM checks
ORDER BY result DESC, violations DESC;


-- =============================================================
-- SECTION 10: FULL KPI SUMMARY -- mirrors all Power BI KPI cards
-- =============================================================

-- Q-021: KPI dashboard summary in one query
WITH base AS (
    SELECT
        COUNT(*)                                                                      AS total_tickets,
        COUNT(*) FILTER (WHERE status IN ('Open','In Progress','Waiting for Approval')) AS active_tickets,
        COUNT(*) FILTER (WHERE is_sla_breached IS NOT NULL)                          AS sla_eligible,
        COUNT(*) FILTER (WHERE is_sla_breached = FALSE)                              AS sla_met,
        COUNT(*) FILTER (WHERE is_first_contact_resolution = TRUE)                   AS fcr_met,
        AVG(hours)    FILTER (WHERE status = 'Resolved' AND hours > 0)               AS avg_hours_raw,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY hours
        ) FILTER (WHERE status = 'Resolved' AND hours > 0)                           AS median_hours_raw
    FROM public.support_tickets
)
SELECT
    total_tickets,
    active_tickets,
    ROUND(avg_hours_raw::NUMERIC, 1)                                AS avg_resolution_hours,
    ROUND(median_hours_raw::NUMERIC, 1)                             AS median_resolution_hours,
    ROUND(sla_met * 100.0 / NULLIF(sla_eligible, 0), 1)            AS sla_compliance_pct,
    70.0                                                            AS sla_target_pct,
    ROUND(sla_met * 100.0 / NULLIF(sla_eligible, 0) - 70, 1)       AS sla_gap_pp,
    ROUND(fcr_met * 100.0 / NULLIF(total_tickets, 0), 1)           AS fcr_pct,
    60.0                                                            AS fcr_target_pct,
    ROUND(fcr_met * 100.0 / NULLIF(total_tickets, 0) - 60, 1)      AS fcr_gap_pp
FROM base;
