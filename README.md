# CashFlew

A Flutter app for visualizing personal finance data exported from [Cashew](https://github.com/jameskoko);. Import your Cashew database or a CSV file and get interactive spending charts and transaction breakdowns.

## Features

- **Line graphs** — spending over time, grouped by day or month, with per-category breakdowns
- **Pie charts** — category-level spending distribution
- **Transaction count graph** — number of transactions over time
- **Transaction list** — searchable list of individual transactions
- **Filtering** — filter by date range, category, subcategory, and transaction name
- **Month selector** — quick navigation between months
- **Custom category colors** — configurable via the settings page
- **Data import** — supports `.db`, `.sqlite`, `.sqlite3`, `.sql`, and `.csv` files

## Getting Started

### Prerequisites

- Flutter SDK `^3.7.2`

### Install & Run

```bash
flutter pub get
flutter run
```

## Importing Data

Tap the upload icon in the app bar to import a file. The app accepts Cashew database files (`.db`, `.sqlite`, `.sqlite3`, `.sql`) or a CSV export.

### CSV Format

The CSV must have a header row followed by data rows with the following columns (in order):

| # | Column | Description | Example |
|---|--------|-------------|---------|
| 0 | **Account** | Wallet / account name | `Bank` |
| 1 | **Amount** | Transaction amount (numeric) | `499.00` |
| 2 | **Currency** | ISO currency code | `INR` |
| 3 | **Title** | Transaction name | `Groceries` |
| 4 | **Note** | Optional note | `Weekly run` |
| 5 | **Date** | ISO 8601 date string | `2025-03-15T10:30:00.000` |
| 6 | **Income** | `true` if income, `false` if expense | `false` |
| 7 | **Type** | _(ignored)_ | |
| 8 | **Category Name** | Main category | `Food` |
| 9 | **Subcategory Name** | Subcategory (optional) | `Restaurants` |
| 10 | **Color** | Category color | `0xFFE57373` |
| 11 | **Icon** | Icon name | `restaurant` |
| 12 | **Emoji** | Emoji icon (optional) | `🍔` |
| 13 | **Budget** | _(ignored)_ | |
| 14 | **Objective** | _(ignored)_ | |

#### Example

```csv
Account,Amount,Currency,Title,Note,Date,Income,Type,Category Name,Subcategory Name,Color,Icon,Emoji,Budget,Objective
Bank,150.00,INR,Coffee,,2025-03-01T09:00:00.000,false,,Food,Cafe,0xFFE57373,local_cafe,☕,,
Bank,5000.00,INR,Salary,,2025-03-01T00:00:00.000,true,,Income,,0xFF81C784,attach_money,,,
UPI,250.00,INR,Uber,,2025-03-02T18:30:00.000,false,,Transport,,0xFF64B5F6,directions_car,,,
```

When a CSV is imported, the app converts it into an SQLite database on-the-fly — creating wallets, categories, subcategories, and transactions from the rows.

## Project Structure

```
lib/
├── main.dart                  # App entry point & home page
├── database_provider.dart     # Database lifecycle & import logic
├── database/
│   ├── tables.dart            # Drift schema, queries & models
│   └── databaseGlobal.dart    # Global DB constants
├── graphs/
│   ├── line_graphs/           # Line graph widgets & helpers
│   └── pie_charts/            # Pie chart widgets
├── logic/
│   ├── helpers.dart           # Date utils, CSV preprocessing
│   ├── constants.dart         # App-wide constants
│   └── category_color_manager.dart
└── presentation/
    ├── pages/                 # Settings page
    ├── widgets/               # Filter dialog, month selector, spend summary, transaction list
    └── resources/             # Theme, colors, typography, spacing
```
