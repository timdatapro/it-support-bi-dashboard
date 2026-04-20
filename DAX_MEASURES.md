# DAX Measures Reference : IT Support Dashboard

All 28 measures live in a dedicated `_DAX` table, organized into 6 subfolders. This keeps them visually separated from data tables in the Fields pane and makes the model easier to navigate.

---

## Quick Setup : Tabular Editor 2

The fastest way to create all measures at once is via a C# script in Tabular Editor 2.

### Step 1 : Create the _DAX table

Open Tabular Editor 2, connect to your Power BI model, paste this script and run it:

```csharp
var dax = Model.Tables.FirstOrDefault(t => t.Name == "_DAX");
if (dax == null) dax = Model.AddTable("_DAX");

var partition = dax.Partitions.FirstOrDefault();
if (partition == null) dax.AddMPartition("_DAX");
partition = dax.Partitions.FirstOrDefault();
partition.Expression = "let Source = #table({}, {}) in Source";
dax.IsHidden = true;
Output("_DAX table ready.");
```

### Step 2 : Create all measures

Paste and run the script below. It creates all 28 measures with correct folder assignments and format strings:

```csharp
var t = Model.Tables["_DAX"];

// Helper to add a measure safely
System.Action<string, string, string, string> addMeasure = (name, expr, folder, fmt) => {
    var existing = t.Measures.FirstOrDefault(m => m.Name == name);
    if (existing != null) existing.Delete();
    var m = t.AddMeasure(name, expr, folder);
    if (!string.IsNullOrEmpty(fmt)) m.FormatString = fmt;
};

// 1. Volume
addMeasure("Total Tickets",
    "COUNTROWS('public support_tickets')",
    "1. Volume", "0");

addMeasure("Active Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"})",
    "1. Volume", "0");

addMeasure("Open Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] = \"Open\")",
    "1. Volume", "0");

addMeasure("Resolved Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] = \"Resolved\")",
    "1. Volume", "0");

addMeasure("Canceled Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] = \"Canceled\")",
    "1. Volume", "0");

addMeasure("Closed Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Resolved\",\"Canceled\"})",
    "1. Volume", "0");

addMeasure("Critical Active",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"},'public support_tickets'[priority_id] = \"Critical\")",
    "1. Volume", "0");

addMeasure("High Active",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"},'public support_tickets'[priority_id] = \"High\")",
    "1. Volume", "0");

addMeasure("Medium Active",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"},'public support_tickets'[priority_id] = \"Medium\")",
    "1. Volume", "0");

addMeasure("Low Active",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"},'public support_tickets'[priority_id] = \"Low\")",
    "1. Volume", "0");

// 2. Resolution Time
addMeasure("Avg Resolution Hours",
    "CALCULATE(AVERAGEX(FILTER('public support_tickets','public support_tickets'[status] = \"Resolved\" && NOT ISBLANK('public support_tickets'[hours]) && 'public support_tickets'[hours] > 0),'public support_tickets'[hours]))",
    "2. Resolution Time", "0.0");

addMeasure("Median Resolution Hours",
    "CALCULATE(MEDIANX(FILTER('public support_tickets','public support_tickets'[status] = \"Resolved\" && NOT ISBLANK('public support_tickets'[hours]) && 'public support_tickets'[hours] > 0),'public support_tickets'[hours]))",
    "2. Resolution Time", "0.0");

// 3. SLA
addMeasure("SLA Compliance %",
    "VAR _total = CALCULATE(COUNTROWS('public support_tickets'),NOT ISBLANK('public support_tickets'[is_sla_breached])) VAR _met = CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[is_sla_breached] = FALSE()) RETURN IF(_total = 0, BLANK(), DIVIDE(_met, _total))",
    "3. SLA", "0.0%");

addMeasure("SLA Target",
    "0.70",
    "3. SLA", "0%");

addMeasure("SLA vs Target",
    "VAR _total = CALCULATE(COUNTROWS('public support_tickets'),NOT ISBLANK('public support_tickets'[is_sla_breached])) VAR _met = CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[is_sla_breached] = FALSE()) VAR _sla = IF(_total = 0, BLANK(), DIVIDE(_met, _total)) RETURN _sla - 0.70",
    "3. SLA", "+0.0%;-0.0%;0.0%");

addMeasure("SLA Breached Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[is_sla_breached] = TRUE())",
    "3. SLA", "0");

// 4. FCR
addMeasure("FCR %",
    "DIVIDE(CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[is_first_contact_resolution] = TRUE()),COUNTROWS('public support_tickets'))",
    "4. FCR", "0.0%");

addMeasure("FCR Target",
    "0.60",
    "4. FCR", "0%");

addMeasure("FCR vs Target",
    "DIVIDE(CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[is_first_contact_resolution] = TRUE()),COUNTROWS('public support_tickets')) - 0.60",
    "4. FCR", "+0.0%;-0.0%;0.0%");

// 5. Agent Performance
addMeasure("Agent Resolved Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] = \"Resolved\")",
    "5. Agent Performance", "0");

addMeasure("Agent Active Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"})",
    "5. Agent Performance", "0");

addMeasure("Agent SLA %",
    "VAR _total = CALCULATE(COUNTROWS('public support_tickets'),NOT ISBLANK('public support_tickets'[is_sla_breached])) VAR _met = CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[is_sla_breached] = FALSE()) RETURN IF(_total = 0, BLANK(), DIVIDE(_met, _total))",
    "5. Agent Performance", "0.0%");

addMeasure("Agent FCR %",
    "DIVIDE(CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[is_first_contact_resolution] = TRUE()),COUNTROWS('public support_tickets'))",
    "5. Agent Performance", "0.0%");

addMeasure("Agent Avg Resolution Hours",
    "CALCULATE(AVERAGEX(FILTER('public support_tickets','public support_tickets'[status] = \"Resolved\" && NOT ISBLANK('public support_tickets'[hours])),'public support_tickets'[hours]))",
    "5. Agent Performance", "0.0");

// 6. Project Impact
addMeasure("Project Total Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),NOT ISBLANK('public support_tickets'[project_name]))",
    "6. Project Impact", "0");

addMeasure("Project Active Tickets",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"},NOT ISBLANK('public support_tickets'[project_name]))",
    "6. Project Impact", "0");

addMeasure("Project Critical+High Open",
    "CALCULATE(COUNTROWS('public support_tickets'),'public support_tickets'[status] IN {\"Open\",\"In Progress\",\"Waiting for Approval\"},'public support_tickets'[priority_id] IN {\"Critical\",\"High\"})",
    "6. Project Impact", "0");

addMeasure("Project Avg Resolution Hours",
    "CALCULATE(AVERAGEX(FILTER('public support_tickets','public support_tickets'[status] = \"Resolved\" && NOT ISBLANK('public support_tickets'[hours])),'public support_tickets'[hours]))",
    "6. Project Impact", "0.0");

Output("All 28 measures created successfully.");
```

> **Note:** In Tabular Editor 2, string interpolation (`$"..."`) is not supported. Use concatenation (`+`) instead. The `DataType` property is read-only : use `FormatString` to control number formatting.

---

## Measures Reference

### Folder 1 : Volume

| Measure | Description | Format |
|---|---|---|
| `Total Tickets` | Count of all rows in the table | `0` |
| `Active Tickets` | Tickets with status Open, In Progress, or Waiting for Approval | `0` |
| `Open Tickets` | Tickets with status Open only | `0` |
| `Resolved Tickets` | Tickets with status Resolved | `0` |
| `Canceled Tickets` | Tickets with status Canceled | `0` |
| `Closed Tickets` | Resolved + Canceled combined | `0` |
| `Critical Active` | Active tickets with Critical priority | `0` |
| `High Active` | Active tickets with High priority | `0` |
| `Medium Active` | Active tickets with Medium priority | `0` |
| `Low Active` | Active tickets with Low priority | `0` |

```dax
Total Tickets =
COUNTROWS('public support_tickets')

Active Tickets =
CALCULATE(
    COUNTROWS('public support_tickets'),
    'public support_tickets'[status] IN {"Open","In Progress","Waiting for Approval"}
)

Critical Active =
CALCULATE(
    COUNTROWS('public support_tickets'),
    'public support_tickets'[status] IN {"Open","In Progress","Waiting for Approval"},
    'public support_tickets'[priority_id] = "Critical"
)
```

---

### Folder 2 : Resolution Time

| Measure | Description | Format |
|---|---|---|
| `Avg Resolution Hours` | Average hours from created_at to closed_at for Resolved tickets | `0.0` |
| `Median Resolution Hours` | Median of the same : less sensitive to outliers | `0.0` |

> Both measures filter to `status = "Resolved"` and exclude NULL or zero `hours` values. Active tickets have NULL hours and are automatically excluded.

```dax
Avg Resolution Hours =
CALCULATE(
    AVERAGEX(
        FILTER(
            'public support_tickets',
            'public support_tickets'[status] = "Resolved"
                && NOT ISBLANK('public support_tickets'[hours])
                && 'public support_tickets'[hours] > 0
        ),
        'public support_tickets'[hours]
    )
)

Median Resolution Hours =
CALCULATE(
    MEDIANX(
        FILTER(
            'public support_tickets',
            'public support_tickets'[status] = "Resolved"
                && NOT ISBLANK('public support_tickets'[hours])
                && 'public support_tickets'[hours] > 0
        ),
        'public support_tickets'[hours]
    )
)
```

---

### Folder 3 : SLA

| Measure | Description | Format |
|---|---|---|
| `SLA Compliance %` | % of closed tickets resolved within SLA target hours | `0.0%` |
| `SLA Target` | Constant reference value (0.70) for chart reference lines | `0%` |
| `SLA vs Target` | Difference between SLA % and 0.70 : positive is good | `+0.0%;-0.0%;0.0%` |
| `SLA Breached Tickets` | Count of tickets where is_sla_breached = TRUE | `0` |

> **Key logic:** `is_sla_breached` is NULL for active tickets (Open/In Progress/Waiting for Approval). The measure uses `NOT ISBLANK()` to exclude these rows from both numerator and denominator, so only closed tickets count toward SLA %.

```dax
SLA Compliance % =
VAR _total = CALCULATE(
    COUNTROWS('public support_tickets'),
    NOT ISBLANK('public support_tickets'[is_sla_breached])
)
VAR _met = CALCULATE(
    COUNTROWS('public support_tickets'),
    'public support_tickets'[is_sla_breached] = FALSE()
)
RETURN IF(_total = 0, BLANK(), DIVIDE(_met, _total))

SLA Target = 0.70
```

---

### Folder 4 : FCR

| Measure | Description | Format |
|---|---|---|
| `FCR %` | % of all tickets resolved on first contact (no follow-up) | `0.0%` |
| `FCR Target` | Constant reference value (0.60) for chart reference lines | `0%` |
| `FCR vs Target` | Difference between FCR % and 0.60 | `+0.0%;-0.0%;0.0%` |

> **Key logic:** `is_first_contact_resolution` is NOT NULL for all tickets, so FCR % is calculated across the full dataset including active tickets. A ticket has FCR = FALSE when `original_ticket_id` is populated, meaning the same issue was raised before.

```dax
FCR % =
DIVIDE(
    CALCULATE(
        COUNTROWS('public support_tickets'),
        'public support_tickets'[is_first_contact_resolution] = TRUE()
    ),
    COUNTROWS('public support_tickets')
)

FCR Target = 0.60
```

---

### Folder 5 : Agent Performance

| Measure | Description | Format |
|---|---|---|
| `Agent Resolved Tickets` | Resolved ticket count, used in agent table | `0` |
| `Agent Active Tickets` | Active ticket count, used in agent table | `0` |
| `Agent SLA %` | SLA compliance per agent : same logic as global SLA % | `0.0%` |
| `Agent FCR %` | FCR rate per agent : same logic as global FCR % | `0.0%` |
| `Agent Avg Resolution Hours` | Average resolution time per agent | `0.0` |

> These measures are functionally identical to the global measures but are kept in a separate folder to make the Fields pane cleaner when building agent-level visuals.

---

### Folder 6 : Project Impact

| Measure | Description | Format |
|---|---|---|
| `Project Total Tickets` | All tickets linked to a project (project_name not blank) | `0` |
| `Project Active Tickets` | Active tickets linked to a project | `0` |
| `Project Critical+High Open` | Active tickets with Critical or High priority | `0` |
| `Project Avg Resolution Hours` | Avg resolution time for project-linked tickets | `0.0` |

```dax
Project Total Tickets =
CALCULATE(
    COUNTROWS('public support_tickets'),
    NOT ISBLANK('public support_tickets'[project_name])
)

Project Critical+High Open =
CALCULATE(
    COUNTROWS('public support_tickets'),
    'public support_tickets'[status] IN {"Open","In Progress","Waiting for Approval"},
    'public support_tickets'[priority_id] IN {"Critical","High"}
)
```

---

## Calculated Columns

These columns live in `public support_tickets`, not in `_DAX`.

| Column | Purpose | Notes |
|---|---|---|
| `created_date` | Strips time from `created_at` : used for Calendar relationship | Must be Date type |
| `Weekday No` | Integer 1-5 (Mon-Fri), hidden : used to sort `Weekday` | BLANK for weekends |
| `Weekday` | Mon/Tue/Wed/Thu/Fri label : sorted by `Weekday No` | BLANK for weekends |
| `Hour Bin` | Time window label (9-11 AM, 12-2 PM, etc.) | Used in heat map rows |
| `Hour Bin Sort` | Integer 1-5 : used to sort `Hour Bin` correctly | Hidden |
| `Priority Sort` | Prefixed text (1-Critical, 2-High, etc.) : forces correct bar chart order | Replaces alphabetical sort |
| `Status Group` | Groups Open/In Progress/Waiting as "Active", rest as "Closed" | Used for high-level filtering |

```dax
created_date =
DATE(
    YEAR('public support_tickets'[created_at]),
    MONTH('public support_tickets'[created_at]),
    DAY('public support_tickets'[created_at])
)

Hour Bin =
VAR h = HOUR('public support_tickets'[created_at])
RETURN
    IF(h >= 9 && h < 12, "9-11 AM",
    IF(h >= 12 && h < 15, "12-2 PM",
    IF(h >= 15 && h < 18, "3-5 PM",
    IF(h >= 18 && h < 21, "6-8 PM",
    IF(h >= 21, "9-11 PM", BLANK())))))

Priority Sort =
SWITCH('public support_tickets'[priority_id],
    "Critical", "1-Critical",
    "High",     "2-High",
    "Medium",   "3-Medium",
    "Low",      "4-Low",
    "Other"
)
```

---

## Known Gotchas

- **New Card visual abbreviates numbers** : use Card (classic) for exact figures like "2,672"
- **Tabular Editor 2 does not support `ContainsName`** : use `FirstOrDefault(m => m.Name == name)` instead
- **`Move()` does not exist in TE2** : recreate measures in the target table via `AddMeasure()` then delete originals
- **`is_sla_breached` is NULL for active tickets** : always use `NOT ISBLANK()` as the denominator filter for SLA %, never just count FALSE rows
- **Calendar LocalDateTables** : disable Auto date/time in Power BI Options before saving, or TE2 will throw a save conflict error
- **`MonthSort = YEAR * 100 + MONTH`** : always needed for correct chronological axis ordering when Month is a text label like "Jul 2025"
****
