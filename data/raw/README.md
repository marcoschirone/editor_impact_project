# Sample data (synthetic)

This folder contains a **synthetic** dataset that stands in for the proprietary
Scopus / SciVal exports used in the study. Its only purpose is to let the analysis
pipeline (`run_all.R`) execute end to end **without access to the licensed data**, so
that the code can be inspected, tested, and demonstrated.

> **These data are entirely artificial.** Editor names, Scopus Author IDs, and
> publication records are fabricated. They do **not** correspond to any real person,
> publication, journal, or result reported in the paper, and the numbers they produce
> are **not** the published findings. The licensed Scopus/SciVal data cannot be
> redistributed; only the real list of publication DOIs is intended to be shared
> separately.

## How it was generated

All files here are produced by `make_sample_data.R` (in the repository root), which
uses a fixed random seed. To regenerate them:

```r
source("make_sample_data.R")   # writes the files below into data/raw/
```

Because a synthetic sample only needs to be structurally correct (not byte-identical),
re-running the generator produces statistically equivalent data.

## Files and what the pipeline reads

| File | Rows | Purpose |
|------|------|---------|
| `scopus_author_ids.csv` | 108 | Editor → Scopus ID mapping. |
| `1_Total_pub_2020-2024.xlsx` | 1,000 | Baseline publication set. |
| `2_Top10_citation.xlsx` | 200 | Top 10% citation percentile set. |
| `3_Top1_citation.xlsx` | 30 | Top 1% citation percentile set. |
| `5_Policy_citation.xlsx` | 150 | Policy-cited set. |
| `6_Patent_citation.xlsx` | 70 | Patent-cited set. |

The pipeline (`01_load_data.R`) consumes only:

- **From `scopus_author_ids.csv`:** the `scopus_id` and `match_count` columns. Rows are
  kept when `scopus_id` is non-empty and `match_count > 0`. (Eight deliberately
  "unmatched" rows are included so this filtering step is exercised; 100 valid editors
  remain.)
- **From each `.xlsx`:** the **row count** and a single column named exactly
  **`Scopus Author Ids`**, holding the publication's author IDs separated by the pipe
  character (`|`). The other columns (`Title`, `Year`, `DOI`) are illustrative only and
  are ignored by the code.

## Column schemas

**`scopus_author_ids.csv`**

| Column | Type | Notes |
|--------|------|-------|
| `row_id` | integer | Row index. |
| `editor_name` | string | Synthetic name. |
| `full_name` | string | Synthetic name. |
| `affiliation` | string | Synthetic affiliation. |
| `scopus_id` | string | Synthetic ID in the `90000000xx` range; blank for unmatched editors. |
| `match_count` | integer | Number of candidate matches; `0` for unmatched editors. |

**SciVal-style `.xlsx` files**

| Column | Type | Notes |
|--------|------|-------|
| `Title` | string | Placeholder title (ignored by the pipeline). |
| `Year` | integer | 2020–2024 (ignored by the pipeline). |
| `DOI` | string | **Left blank.** A real list of DOIs for the publication set can be added here later. |
| `Scopus Author Ids` | string | Pipe-separated (`\|`) author IDs. IDs in the `90000000xx` range are "editors"; `80000000xx` are other authors. **This is the only column the pipeline reads.** |

## Adding the real DOI list later

The blank `DOI` column is the natural place to record real publication DOIs once they
are available, or they can be shipped as a separate identifier file (e.g.
`publication_dois.csv`). DOIs and EIDs are identifiers rather than licensed records, so
sharing them is consistent with the project's open-science statement; the underlying
Scopus/SciVal records remain proprietary and are not included here.
