-- ============================================================
-- IT Support Dashboard — PostgreSQL Schema
-- EdTech Company | Q3 2025 – Q1 2026
-- ============================================================

-- Drop existing table if rebuilding
DROP TABLE IF EXISTS public.support_tickets CASCADE;

-- Main tickets table
CREATE TABLE public.support_tickets (
    ticket_id                   VARCHAR(20)     PRIMARY KEY,
    created_at                  TIMESTAMP       NOT NULL,
    resolved_at                 TIMESTAMP,
    closed_at                   TIMESTAMP,
    hours                       NUMERIC(6,1),
    status                      VARCHAR(30)     NOT NULL,
    employee_name               VARCHAR(100)    NOT NULL,
    employee_department         VARCHAR(50)     NOT NULL,
    agent_name                  VARCHAR(100)    NOT NULL,
    category_name               VARCHAR(50)     NOT NULL,
    priority_id                 VARCHAR(20)     NOT NULL,
    sla_target_hours            NUMERIC(5,1)    NOT NULL,
    is_sla_breached             BOOLEAN,
    is_first_contact_resolution BOOLEAN         NOT NULL,
    original_ticket_id          VARCHAR(20),
    project_name                VARCHAR(100)    NOT NULL,

    -- Constraints
    CONSTRAINT chk_status CHECK (
        status IN ('Open', 'In Progress', 'Waiting for Approval', 'Resolved', 'Canceled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority_id IN ('Critical', 'High', 'Medium', 'Low')
    ),
    CONSTRAINT chk_resolved_after_created CHECK (
        resolved_at IS NULL OR resolved_at >= created_at
    ),
    CONSTRAINT chk_closed_after_created CHECK (
        closed_at IS NULL OR closed_at >= created_at
    )
);

-- Indexes for common filter/join patterns
CREATE INDEX idx_st_created_at          ON public.support_tickets (created_at);
CREATE INDEX idx_st_status              ON public.support_tickets (status);
CREATE INDEX idx_st_priority            ON public.support_tickets (priority_id);
CREATE INDEX idx_st_agent               ON public.support_tickets (agent_name);
CREATE INDEX idx_st_department          ON public.support_tickets (employee_department);
CREATE INDEX idx_st_category            ON public.support_tickets (category_name);
CREATE INDEX idx_st_project             ON public.support_tickets (project_name);

-- Computed helper column for Power BI (Status Group)
-- Active = not yet closed/canceled; Closed = done
ALTER TABLE public.support_tickets
    ADD COLUMN IF NOT EXISTS status_group VARCHAR(10)
    GENERATED ALWAYS AS (
        CASE
            WHEN status IN ('Resolved', 'Canceled') THEN 'Closed'
            ELSE 'Active'
        END
    ) STORED;

COMMENT ON TABLE public.support_tickets IS
    'IT support ticket data for EdTech company. Q3 2025–Q1 2026. 2,672 tickets.';
