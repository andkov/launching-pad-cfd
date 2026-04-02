# INPUT Manifest: Alberta Income Support Aggregated Caseload Data

Provides definitive information and metadata about the raw input file used in this project — before it is ingested by ETL scripts.

## Purpose

This manifest documents the **raw source data** downloaded from the Alberta Open Government portal and used as the entry point for the subsequent analytic pipeline.

For documentation of the **analysis-ready tables** see [`CACHE-manifest.md`](CACHE-manifest.md) which should be composed after the ETL pipelines is successfully stabilized.  

## Dataset Summary

| Field                    | Value |
|:-------------------------|:------|
| **Dataset Name**         | Income Support Caseload |
| **Publisher**            | Alberta Assisted Living and Social Services (ALSS), Government of Alberta |
| **License**              | [Open Government Licence – Alberta](https://open.alberta.ca/licence) |
| **Open Data Portal**     | <https://open.alberta.ca/opendata/income-support-aggregated-caseload-data> |
| **Dataset UUID**         | `e1ec585f-3f52-40f2-a022-5a38ea3397e5` |
| **Resource UUID**        | `4f97a3ae-1b3a-48e9-a96f-f65c58526e07` |
| **Direct CSV URL**       | <https://open.alberta.ca/dataset/e1ec585f-3f52-40f2-a022-5a38ea3397e5/resource/4f97a3ae-1b3a-48e9-a96f-f65c58526e07/download/is-aggregated-data-april-2005-sep-2025.csv> |
| **Local Copy**           | `data-public/raw/is-aggregated-data-april-2005-sep-2025.csv` |
| **Temporal Coverage**    | April 2005 – September 2025 (246 calendar months) |
| **Total Data Rows**      | 3,722 (excluding 2 header rows) |
| **Update Frequency**     | Monthly (new months appended as data becomes available) |
| **Geography**            | Province of Alberta (all rows) |

## Raw File Format

The CSV file uses a **two-row header** pattern:

- **Row 1** (title): `"Alberta Assisted Living and Social Services\nIncome Support Caseload"` — a merged label spanning the first column; all other columns are empty.
- **Row 2** (column headers): `Ref_Date`, `Geography`, `Measure Type`, `Measure`, `Value` — followed by 9 trailing empty columns.
- **Rows 3+** (data): One observation per row. Each row reports a single `(month × measure type × measure)` combination.

## Client Type Definitions:

- **Expected to Work (ETW)**: Clients assessed as able to participate in employment activities. Subdivided by whether they are currently working, available for work but not working, or temporarily unavailable. ETW clients are generally expected to pursue employment and may receive income supplementation for low earnings.
- **Barriers to Full Employment (BFE)**: Clients facing significant, often long-term, barriers that preclude full-time employment. Barriers may include chronic physical or mental health conditions (of more than six months' duration), caregiving responsibilities, or other life circumstances. BFE clients generally receive higher benefit levels reflecting more complex needs.
