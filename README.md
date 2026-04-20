# IT Support Dashboard (EdTech Company)

📊 **Power BI Project** | Business Intelligence | IT Operations | EdTech Industry

## Overview

This project showcases an end-to-end **IT Support Analytics Dashboard** built for an EdTech company.  
The goal is to give IT managers and team leads a single place to monitor **ticket volume, SLA compliance, first-contact resolution rate, and agent performance** and identify bottlenecks before they escalate.

The project covers the **full data pipeline**: from synthetic data generation and PostgreSQL schema design, through Python ETL, DAX modeling in Power BI, to an interactive multi-block dashboard with conditional formatting, bookmarks, and slicers.

> **KPI Targets:** SLA Compliance ≥ 70% | First Contact Resolution ≥ 60%

---

## Dashboard Preview

![IT Support Dashboard](dashboard/preview.png)

---

## Key Features

- **KPI Overview** — Total tickets, active tickets, avg/median resolution hours, SLA %, FCR %
- **Trend Analysis** — Daily/monthly line charts for ticket volume, SLA compliance, and FCR with target reference lines
- **Bottleneck Detection** — Interactive table (Departments / Agents / Categories) with conditional formatting on SLA and FCR; data bars on volume and resolution time
- **Heat Map** — Ticket volume by hour of day × day of week to identify peak load periods
- **Priority View** — Active tickets by priority (Critical / High / Medium / Low) with color-coded bars
- **Active Tickets Table** — Live table filtered to open tickets, sorted by created date, with visual priority indicators
- **Slicers** — Filter by Department, Agent, Priority, and Period

---

## Tools & Technologies

| Layer | Tool |
|---|---|
| Database | PostgreSQL (local) |
| ETL | Python — `pandas`, `psycopg2` |
| BI Platform | Power BI Desktop |
| DAX Authoring | Tabular Editor 2 (C# scripts) |
| Data Modeling | DAX — 28 measures in dedicated `_DAX` table |
| Database Client | DBeaver |

---

## Project Structure

```
it-support-dashboard/
│
├── dashboard/
│   ├── IT_Support_Dashboard.pbix     # Power BI file
│   └── preview.png                   # Dashboard screenshot
│
├── source/
│   ├── generate_data.py              # Synthetic data generator
│   ├── load_data.py                  # PostgreSQL ETL pipeline
│   ├── schema.sql                    # Table DDL + indexes + constraints
│   └── support_tickets_sample.csv    # Sample dataset (100 rows)
│
└── README.md
```

---

## Data Model

The dashboard is powered by a single PostgreSQL table `public.support_tickets` with **2,672 tickets** covering Q3 2025 – Q1 2026.

**Schema highlights:**
- `is_sla_breached` — NULL for active tickets (excluded from SLA calculation)
- `is_first_contact_resolution` — NOT NULL for all tickets (included in FCR calculation)
- `hours` — resolution time in hours, NULL for active tickets
- SLA targets by priority: Critical=8h, High=16h, Medium=30h, Low=50h

**Power BI model:**
- Custom `Calendar` table with `MonthSort` column for correct chronological axis ordering
- Calculated columns: `created_date`, `Weekday`, `Hour Bin`, `Hour Bin Sort`, `Priority Sort`
- All 28 DAX measures organized in 6 subfolders inside a dedicated `_DAX` table

---

## Key Metrics (Q3 2025 – Q1 2026)

| KPI | Result | Target | Status |
|---|---|---|---|
| Total Tickets | 2,672 | — | — |
| Active Tickets | 21 | — | — |
| Avg Resolution Hours | 22.1h | — | — |
| Median Resolution Hours | 22.0h | — | — |
| SLA Compliance % | 68.0% | ≥ 70% | ⚠️ Below target |
| FCR % | 57.3% | ≥ 60% | ⚠️ Below target |

---

## How to Use

1. Clone this repository
   ```bash
   git clone https://github.com/timdatapro/it-support-dashboard.git
   ```

2. Set up the database
   ```bash
   psql -U postgres -d edtech_support -f source/schema.sql
   python source/load_data.py
   ```

3. Open `dashboard/IT_Support_Dashboard.pbix` in Power BI Desktop

4. Update the PostgreSQL connection string in **Transform Data → Data Source Settings**

---

## Business Impact

- Replaced manual ticket tracking with an automated, filterable dashboard
- Identified peak load windows (Wed 9–11 AM) for proactive staffing decisions
- Surfaced SLA and FCR gaps by agent, department, and category in a single view
- Active tickets table gives team leads an immediate action list sorted by urgency

---

## Author

👤 **Tim Fateev**  
Data Analyst | SQL · Power BI · Tableau · Python · PostgreSQL

[![LinkedIn](https://img.shields.io/badge/LinkedIn-tim--datapro-blue?logo=linkedin)](https://www.linkedin.com/in/tim-datapro/)
[![GitHub](https://img.shields.io/badge/GitHub-timdatapro-black?logo=github)](https://github.com/timdatapro)
