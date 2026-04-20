# IT Support Analytics Dashboard: EdTech Company

📊 **Power BI Project** | Business Intelligence | IT Operations | EdTech Industry

---

## Business Context

> *"Our IT support team is struggling to keep up with growing ticket volume across projects and departments. Manual reports are outdated by the time they reach us. We need a single dashboard to prioritize tickets correctly, monitor team performance, and identify recurring bottlenecks before they delay course launches."*
>
> -- Head of IT Support, EdTech Company

The company faces a critical challenge: technical issues block employees from doing their jobs, causing delays in launching new courses and platform updates. Reports are built manually, take too long, and are stale by the time decisions need to be made.

**The dashboard answers three core questions:**
1. Where are the bottlenecks : which categories and departments generate the most unresolved tickets?
2. Are we meeting our SLA and FCR targets : who is falling behind?
3. How is workload distributed across agents : where do we need to rebalance?

> **KPI Targets:** SLA Compliance ≥ 70% | First Contact Resolution ≥ 60%

---

## Dashboard Preview

![IT Support Dashboard](https://i.imgur.com/xsHo67m.png)

---

## Summary

| 🎯 Goal | ⚙️ Process | 💡 Insights |
|---|---|---|
| Deliver a data-driven Power BI solution that consolidates IT support data into an interactive dashboard, enabling real-time monitoring of SLA compliance, FCR rate, agent workload, and ticket trends for an EdTech organization. | 1. Generating synthetic ticket data (2,672 tickets, Q3 2025 – Q1 2026) with Python. 2. Designing PostgreSQL schema with constraints, indexes, and data quality rules. 3. Building ETL pipeline with pandas and psycopg2. 4. Authoring 28 DAX measures in Tabular Editor 2 via C# scripts. 5. Building Power BI data model with Calendar table and calculated columns. 6. Designing multi-block dashboard with conditional formatting, bookmarks, and slicers. | 1. SLA compliance is **68%**, below the 70% target, with Engineering (66.2%) and Analytics (66.1%) as the weakest departments. 2. **Tuesday 9–11 AM** is the peak load window with 124 tickets, pointing to a clear staffing gap. 3. FCR rates range from **52.9% to 60.1%** across agents, with David Harris showing the most room for improvement. |

---

## Top 5 Insights

**1. SLA and FCR are both below target with no sign of recovery**
SLA compliance sits at 68% against a 70% goal, and FCR at 57.3% against 60%. The monthly trend lines show both metrics have been consistently underperforming since July 2025 with no upward movement. The team is not getting better over time.

**2. Ticket volume is falling but quality is not improving**
Total tickets dropped from roughly 400 per month in summer 2025 to under 250 by January 2026. A lighter workload should make it easier to hit SLA and FCR targets, yet both remain flat. This points to a process or skills issue rather than a capacity problem.

**3. High priority tickets dominate the active queue**
Of the 21 currently open tickets, the vast majority are High priority. Only 1 Critical ticket is open, but 10 High priority tickets are unresolved, meaning a significant portion of the active queue carries elevated business risk right now.

**4. Tuesday and Wednesday mornings are the peak load window**
The heat map shows 9–11 AM on Tuesday generating 124 tickets, the highest single window of the week. Wednesday and Thursday follow at 112 each in the same slot. Without adequate morning coverage on these days, tickets pile up before the team can respond.

**5. Agent performance varies significantly and James Carter needs attention**
James Carter handles the highest volume on the team at 417 tickets with 4 currently open, yet has the lowest SLA compliance at 64.3%. Ryan Johnson is the only agent meeting the SLA target at 70.5%, while David Harris has the lowest FCR at 52.9%, meaning nearly half his tickets require a follow-up contact.

---

## Key Features

- **KPI Overview**: Total tickets, active tickets, avg and median resolution hours, SLA %, FCR %
- **Trend Analysis**: Line charts for ticket volume, SLA compliance, and FCR with target reference lines and dynamic date granularity (Day / Month)
- **Bottleneck Detection**: Interactive table (Departments / Agents / Categories) with conditional formatting on SLA and FCR; data bars on volume and resolution time
- **Heat Map**: Ticket volume by hour of day x day of week to identify peak load windows
- **Priority View**: Active tickets by priority (Critical / High / Medium / Low) with color-coded bars sorted correctly
- **Active Tickets Table**: Filtered to open tickets only, sorted by creation date, with clean human-readable column names
- **Slicers**: Filter the entire dashboard by Department, Agent, Priority, and Period

---

## Design Decisions

**1. "Active tickets card is useful. Add a breakdown by status too"**
The KPI card shows the combined active total (21). The active tickets table below is filtered exclusively to Open / In Progress / Waiting for Approval statuses and sorted by creation date, giving team leads an immediate action list without mixing in resolved or canceled tickets.

**2. "Technical field names like `employee_department` should not be visible to users"**
All column headers across every table are renamed to clean, human-readable labels: Agent, Department, Category, Status, Priority, Employee, Project, Created.

**3. "Showing only average resolution hours can be misleading. Add median too"**
Both Avg Resolution Hours (22.1h) and Median Resolution Hours (22.0h) are shown as separate KPI cards side by side, allowing users to immediately spot distribution skew.

**4. "SLA and FCR cards need trend context next to them"**
Three dedicated line charts sit directly below the KPI row with dashed red reference lines at target values (70% and 60%). A Date Granularity slicer lets users switch between Day and Month granularity.

**5. "Tickets by priority should show only active tickets, sorted Critical to Low"**
The Active Tickets by Priority bar chart shows only open tickets with correct sort order controlled via a `Priority Sort` calculated column (1-Critical, 2-High, 3-Medium, 4-Low) and custom colors per priority level.

**6. "Departments / Agents / Categories should be one unified table, not separate charts"**
A single interactive table with a bookmark switcher (Departments / Agents / Categories) shows all key metrics side by side: Active tickets, Total tickets, Avg resolution hours, SLA compliance %, FCR rate %. Conditional formatting highlights underperforming cells in red.

**7. "Color logic should be consistent. Red only for SLA/FCR violations, not open status"**
Red is used exclusively for below-target values: SLA below 70% and FCR below 60% in the table, and Critical priority in the bar chart. Open/active ticket status is shown in blue or amber to avoid false urgency.

**8. "Peak load windows matter. Show when and where bottlenecks occur by time"**
A heat map matrix (Hour Bin x Weekday) with a green gradient immediately reveals Tuesday 9–11 AM as the highest-volume window across the entire week.

---

## Key Metrics (Q3 2025 – Q1 2026)

| KPI | Result | Target | Status |
|---|---|---|---|
| Total Tickets | 2,672 | | |
| Active Tickets | 21 | | |
| Avg Resolution Hours | 22.1h | | |
| Median Resolution Hours | 22.0h | | |
| SLA Compliance % | 68.0% | ≥ 70% | ⚠️ Below target |
| FCR % | 57.3% | ≥ 60% | ⚠️ Below target |
| Resolution: Critical | ≤ 8h | tracked per ticket | |
| Resolution: High | ≤ 16h | tracked per ticket | |
| Resolution: Medium | ≤ 30h | tracked per ticket | |
| Resolution: Low | ≤ 50h | tracked per ticket | |

---

## Tools & Technologies

| Layer | Tool |
|---|---|
| Database | PostgreSQL (local) |
| ETL | Python: `pandas`, `psycopg2` |
| BI Platform | Power BI Desktop |
| DAX Authoring | Tabular Editor 2 (C# scripts) |
| Data Modeling | DAX: 28 measures in dedicated `_DAX` table |
| Database Client | DBeaver |

---

## Repository Structure

```
it-support-bi-dashboard/
│
├── README.md                     # Project overview and documentation
├── DAX_MEASURES.md               # All 28 DAX measures with descriptions and TE2 setup script
├── LICENSE
│
├── create_schema.sql             # PostgreSQL table DDL, indexes, and constraints
├── load_data.py                  # Python ETL pipeline (pandas + psycopg2)
├── validation_queries.sql        # Senior-level SQL validation and analytics queries
└── support_tickets_en.xlsx       # Source dataset (2,672 tickets)
```

---

## Data Model

The dashboard is powered by a single PostgreSQL table `public.support_tickets` with **2,672 tickets** covering Q3 2025 – Q1 2026.

**Key schema decisions:**
- `is_sla_breached` is NULL for active tickets, excluded from SLA % calculation automatically
- `is_first_contact_resolution` is NOT NULL for all tickets, always included in FCR calculation
- `hours` = `closed_at - created_at` in hours, NULL for active tickets
- `original_ticket_id` links repeat tickets for FCR tracking

**Power BI model:**
- Custom `Calendar` table with `MonthSort` column for correct chronological axis ordering
- Calculated columns: `created_date`, `Weekday`, `Hour Bin`, `Hour Bin Sort`, `Priority Sort`
- All 28 DAX measures organized in 6 subfolders inside a dedicated `_DAX` table with no cross-measure dependencies

---

## How to Use

1. Clone this repository
```bash
git clone https://github.com/timdatapro/it-support-bi-dashboard.git
```

2. Set up the database
```bash
psql -U postgres -d edtech_support -f create_schema.sql
python load_data.py
```

3. Open Power BI Desktop and connect to your PostgreSQL database

4. Import the DAX measures using the Tabular Editor 2 script in `DAX_MEASURES.md`

---

## Business Impact

- Replaced manual weekly reporting with a live, filterable dashboard available to IT managers and department leads
- Identified peak load window (Tue 9–11 AM) enabling proactive staffing decisions
- Surfaced SLA and FCR gaps by agent, department, and category in a single view
- Active tickets table gives team leads an immediate priority-sorted action list for daily standups

---

## Author

👤 **Tim Fateev**
Data Analyst | SQL · Power BI · Tableau · Python · PostgreSQL

[![LinkedIn](https://img.shields.io/badge/LinkedIn-tim--datapro-blue?logo=linkedin)](https://www.linkedin.com/in/tim-datapro/)
[![GitHub](https://img.shields.io/badge/GitHub-timdatapro-black?logo=github)](https://github.com/timdatapro)
