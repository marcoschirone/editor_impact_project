# Editorial board membership and citation elite status in sustainability science journals

*Replication code, data documentation, and analytical workflow for the STI 2026 paper.*

**Internal project name:** `editorial_board_membership`

---

## Overview

Editorial board members play a central role in the governance of scientific journals. Through their involvement in editorial decision-making, peer review, and journal strategy, they influence the development of research fields and the dissemination of scientific knowledge. At the same time, editorial positions are frequently occupied by highly productive and influential scholars. Whether editorial board members are disproportionately represented among the scientific elite, however, remains an open empirical question.

This repository contains the code, documentation, and reproducibility materials supporting the study:

> **Rahman, A. I. M. J., & Schirone, M. (2026). Editorial board membership and citation elite status in sustainability science journals.** Proceedings of the International Conference on Science and Technology Indicators (STI 2026).

The study investigates whether editorial board members (EBMs) of sustainability science journals are disproportionately represented among highly cited publications and other indicators of scientific and societal impact.

The analysis combines editorial board information, Scopus Author IDs, publication metadata, citation-based indicators, policy-citation indicators, and patent-citation indicators to evaluate the relationship between editorial board membership and scientific prominence.

The study is based on:

- 29 Scopus-indexed sustainability science journals;
- 80,709 articles and reviews published between 2020 and 2024;
- 2,120 editorial board members identified across the journal set;
- 1,823 editors successfully matched to valid Scopus Author IDs.

The analytical framework evaluates editor participation among:

- Top 1% most-cited publications;
- Top 10% most-cited publications;
- Policy-cited publications;
- Patent-cited publications.

Observed rates of editor participation are compared with expected baseline rates derived from the overall publication population. Statistical evidence is reported using proportion tests, confidence intervals, and comparative effect measures.

The underlying publication and citation data are obtained from proprietary databases (Scopus, SciVal) and cannot be redistributed. To allow the workflow to be run and inspected without those licences, the repository ships a **synthetic sample dataset** in `data/raw/` (see `data/raw/README.md`). The **published** tables and figures from the paper are included in `output/figures/` and `output/tables/` and are tracked in version control.

---

## Repository status

This repository contains the final analytical workflow used in the STI 2026 paper.

The repository includes:

- analytical code;
- project configuration files;
- data-collection scripts;
- documentation;
- the publication DOI list (`STI_2026_paper_DOIs.txt`);
- a synthetic sample dataset that lets the workflow run without the licensed data (`data/raw/`);
- the published tables and figures reported in the paper (`output/figures/`, `output/tables/`).

The repository is intended to facilitate transparency, reproducibility, and methodological reuse.

Some underlying bibliometric datasets originate from proprietary databases and cannot be redistributed publicly. Consequently, the repository focuses on sharing code, documentation, metadata, identifiers (DOIs), and reproducible analytical procedures rather than the licensed source records.

---

## Repository structure

```text
editorial_board_membership/
├── README.md
├── LICENSE
├── CITATION.cff
├── .gitignore
├── config.R
├── run_all.R
├── make_sample_data.R          # regenerates the synthetic sample in data/raw/
├── editorial_board_membership.Rproj
├── STI_2026_paper_DOIs.txt      # DOI list of the analysed publication corpus
│
├── R/                          # Analysis scripts (sourced by run_all.R)
│
├── data/
│   ├── raw/                    # SYNTHETIC sample inputs (see data/raw/README.md)
│   └── processed/              # Generated intermediate objects (regenerated; not tracked)
│
├── data-collection/           # Scopus API harvesting scripts (Phase 1)
│
└── output/                    # PUBLISHED figures and tables from the paper (tracked)
    ├── figures/               #   fig1_overview.png … fig5_societal_impact.png
    └── tables/                #   table1_main_results.csv … table3_rq_answers.csv
```

The analytical workflow is orchestrated through `run_all.R`, which sources the required scripts, loads the configured datasets, executes all analyses, and writes outputs to `output/`. The published figures and tables from the paper are kept under version control in `output/`. Re-running the pipeline on the synthetic sample data overwrites these files in your working copy with illustrative versions; the published versions remain in the Git history and can be restored at any time with `git checkout -- output/`.

---

## Research questions

The repository supports analyses addressing the following questions.

### RQ1. Citation elite status

Are editorial board members disproportionately represented among highly cited publications in sustainability science?

This question is examined through:

- Top 1% citation percentile publications;
- Top 10% citation percentile publications.

### RQ2. Policy impact

Are editorial board members disproportionately represented among publications receiving policy attention?

This question is examined through policy-citation indicators.

### RQ3. Technological impact

Are editorial board members disproportionately represented among publications receiving technological attention?

This question is examined through patent-citation indicators.


---

## Requirements

### Software

The project requires:

- R version 4.1 or later;
- RStudio (recommended but not required).

### Main R packages

#### Analysis workflow

The analytical workflow relies primarily on:

- data.table
- readxl
- ggplot2
- scales
- writexl

#### Data collection

The data-collection scripts additionally use:

- httr2
- jsonlite
- cli

Additional package dependencies are loaded automatically where required by the scripts.

### Operating systems

The repository relies on standard R functionality and relative file paths and is expected to run on:

- Windows;
- macOS;
- Linux.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/marcoschirone/editorial_board_membership.git
cd editorial_board_membership
```

Install the required packages:

```r
install.packages(c(
  "data.table",
  "readxl",
  "ggplot2",
  "scales",
  "writexl",
  "httr2",
  "jsonlite",
  "cli"
))
```

Open the project in RStudio or set the working directory to the repository root before running the workflow.

---

## Scopus API access

Several scripts in the `data-collection/` directory interact with the Scopus APIs.

Users wishing to reproduce the data-collection stage must provide their own Scopus API key through an environment variable:

```r
Sys.setenv(SCOPUS_API_KEY = "your_api_key")
```

API credentials are not distributed through this repository. No API keys are stored in version-controlled files.

---

## Data

### Synthetic sample data (what ships in `data/raw/`)

The files in `data/raw/` are a **synthetic sample**, not the licensed Scopus/SciVal data. They are artificial records generated by `make_sample_data.R` (with a fixed random seed) so that the full analysis pipeline can be executed, inspected, and tested without access to the proprietary databases.

The sample uses the **same file names** and the **same column** (`Scopus Author Ids`) that the real exports would use, so `run_all.R` runs unchanged. **The numbers it produces are illustrative only and do not reproduce the published results.** A full description is given in:

```text
data/raw/README.md
```

To reproduce the published findings, replace the synthetic files in `data/raw/` with the corresponding real Scopus/SciVal exports of the same names. Licensed data must not be committed to version control.

### Editor–Scopus ID mapping

The analytical workflow uses an editor–author matching file:

```text
data/raw/scopus_author_ids.csv
```

This file links editorial board members to Scopus Author IDs and enables the identification of editor-authored publications throughout the publication corpus. The version shipped in `data/raw/` is the synthetic sample; the real mapping is produced by the data-collection scripts (see *Reproducibility workflow*).

### SciVal exports

The study uses five SciVal exports covering the publication window 2020–2024. The repository ships **synthetic stand-ins** for these files under the names below; the real licensed exports are **not** included.

```text
1_Total_pub_2020-2024.xlsx
2_Top10_citation.xlsx
3_Top1_citation.xlsx
4_Policy_citation.xlsx
5_Patent_citation.xlsx
```
| File | Description |
|--------|-------------|
| 1_Total_pub_2020-2024.xlsx | Complete publication population |
| 2_Top10_citation.xlsx | Publications in the top 10% citation percentile |
| 3_Top1_citation.xlsx | Publications in the top 1% citation percentile |
| 4_Policy_citation.xlsx | Publications receiving policy citations |
| 5_Patent_citation.xlsx | Publications receiving patent citations |



In the real study, these datasets form the basis of all statistical analyses reported in the paper. In this repository they are represented by synthetic samples.

### Editorial board roster

The editor-identification workflow relies on a compiled editorial-board dataset containing editor names, roles, and affiliations across the 29 sustainability science journals included in the study. The roster was used to identify editors and subsequently match them to Scopus Author IDs. It is derived from public journal websites and is not redistributed here.

### Publication DOI list

The repository includes:

```text
STI_2026_paper_DOIs.txt
```

This file contains the DOI list associated with the publication corpus analysed in the study. DOIs are identifiers rather than licensed records, so the list is provided to facilitate transparency and independent verification while respecting the licensing restrictions of the proprietary databases.

---

## Data availability

This repository contains analytical code, documentation, the publication DOI list, a synthetic sample dataset, and the published outputs. It does **not** redistribute proprietary bibliometric records obtained through Scopus or SciVal subscriptions.

Researchers with appropriate institutional access to Scopus and SciVal can reproduce the workflow using the code and documentation provided here.

---

## Reproducibility workflow

The workflow consists of two distinct phases:

1. **Data collection**, which requires access to the Scopus APIs and SciVal.
2. **Analysis**, which reproduces the statistical results, tables, and figures reported in the STI 2026 paper.

### Phase 1 – Data collection

#### Step 1: Editorial board compilation

Editorial board rosters were compiled for the 29 sustainability science journals included in the study. Information collected included editor names, editorial roles, and institutional affiliations. These rosters formed the basis for all subsequent author-identification procedures.

#### Step 2: Author identification

Editorial board members were matched to Scopus Author IDs using name and affiliation information, establishing a reliable link between individual editors and their publication records. The matching process produced `scopus_author_ids.csv`, the primary linkage file between editors and publications.

#### Step 3: Publication retrieval

Publication metadata were retrieved using the Scopus APIs and publication identifiers. This stage produced the publication corpus used in the study and enabled the identification of publications authored or co-authored by editorial board members.

#### Step 4: Impact indicator extraction

Citation and impact indicators were obtained through SciVal exports covering the period 2020–2024. The resulting datasets identify publications belonging to the top 1% citation percentile, the top 10% citation percentile, policy-cited sets, and patent-cited sets.

### Phase 2 – Analysis

The analytical workflow is executed through:

```r
source("run_all.R")
```

The master script orchestrates all stages of the analysis. Specifically, the workflow:

1. loads project configuration settings;
2. imports editor–author mappings;
3. imports publication and indicator datasets;
4. identifies editor involvement in each publication set;
5. computes observed participation rates;
6. calculates expected baseline rates;
7. performs statistical tests;
8. generates summary tables;
9. produces publication-ready figures.

Outputs are written to `output/tables/` and `output/figures/`.

> **Important.** With the bundled synthetic sample data, running `run_all.R` produces **illustrative** outputs only, written to `output/`. These overwrite the published figures and tables in your working copy, but the published versions are committed to Git and can be restored at any time with `git checkout -- output/`. To reproduce the published figures and tables, replace the synthetic files in `data/raw/` with the real Scopus/SciVal exports of the same names before running.

---

## Statistical approach

The analyses compare the observed representation of editorial board members within different publication subsets against expected baseline rates derived from the overall publication population.

The primary analytical outputs include publication counts, participation rates, expected rates, ratios of observed versus expected values, confidence intervals, and statistical significance tests.

The analytical objective is to determine whether editorial board members are represented at levels greater than would be expected by chance.

---

## Outputs

The tables and figures reported in the STI 2026 paper are stored in `output/tables/` and `output/figures/` and are tracked in version control.

#### Tables

| File | Description |
|--------|-------------|
| table1_main_results.csv | Summary statistics across all impact indicators |
| table2_statistical_tests.csv | Statistical test results comparing observed and expected rates |
| table3_rq_answers.csv | Research-question-level summary of findings |

#### Figures

| File | Description |
|--------|-------------|
| fig1_overview.png | Overview of editor publication shares across impact indicators |
| fig2_observed_vs_expected.png | Observed versus expected participation rates |
| fig3_editor_participation.png | Share of editors participating in each impact category |
| fig4_societal_impact.png | Policy-citation and patent-citation outcomes |

Running `run_all.R` writes tables and figures with these same file names into `output/`. With the synthetic sample data the generated versions are illustrative; with the real Scopus/SciVal exports they reproduce the published files listed above. Because the pipeline writes to the same paths, a sample run overwrites the published copies in your working tree — they remain in the Git history and can be restored with `git checkout -- output/`.

---

## Interpretation of outputs

The figures and tables should be interpreted alongside the STI 2026 paper, which provides the theoretical framework, methodological rationale, and substantive discussion of the findings. While the repository enables reproduction of the reported results, interpretation of those results should be guided by the full study.

---

## Computational environment

The analyses reported in the STI 2026 paper were conducted using R. For exact reproducibility, users are encouraged to archive the output of `sessionInfo()` alongside any reproduced analyses, recording:

- R version;
- operating system;
- package versions;
- date of data extraction;
- date of analysis execution.

### Reproducibility considerations

Scopus and SciVal are continuously updated databases. Data extracted at a later date may therefore differ slightly from the datasets used in the original study. The published results correspond to the data snapshot available during preparation of the STI 2026 paper.

---

## Citation

If you use this code or the derived results, please cite the paper:

> Rahman, A. I. M. J., & Schirone, M. (2026). Editorial board membership and citation elite status in sustainability science journals [Conference paper]. Proceedings of the International Conference on Science and Technology Indicators (STI 2026). https://doi.org/\<DOI — placeholder\>

To cite the **repository/software** itself, point to its GitHub page:

> Schirone, M., & Rahman, A. I. M. J. (2026). *Editorial board membership and citation elite status in sustainability science journals* (Version 1.0.0) [Computer software]. GitHub. https://github.com/marcoschirone/editorial_board_membership

Machine-readable metadata are provided in `CITATION.cff`; GitHub's "Cite this repository" button generates the repository citation automatically, with the paper retained as a related reference. The DOI placeholder should be completed once the proceedings metadata become available.

---

## License

The repository is distributed under the terms specified in the `LICENSE` file (MIT for the source code). Unless otherwise stated, the licence applies to source code, documentation, repository metadata, and generated outputs that do not contain proprietary source records.

### Third-party data

The repository does **not** grant rights to proprietary datasets obtained through Scopus, SciVal, or other subscription-based bibliometric services. Users remain responsible for complying with all applicable licensing agreements associated with those services.

---

## Reproducibility notes

### Synthetic sample data

The data in `data/raw/` are synthetic and exist only to make the pipeline runnable without the licensed sources. They are regenerated by `make_sample_data.R`. Results obtained from them are illustrative and are not the published findings.

### Proprietary data

The analyses rely on publication and citation information obtained through Scopus and SciVal subscriptions. The underlying proprietary records cannot be redistributed. To support transparency while respecting these restrictions, the repository provides analytical code, documentation, the publication DOI list, and the published outputs.

### Editorial-board snapshot

Editorial board membership was recorded at a single point in time. Subsequent changes to editorial boards are not reflected in the study and may affect attempts to reconstruct the dataset in the future.

### Database evolution

Citation counts, publication metadata, and journal indicators evolve over time as databases are updated. Re-running the data-collection workflow at a later date may therefore yield slightly different results.

### API credentials

No API credentials are stored in this repository. Users reproducing the data-collection workflow must provide their own Scopus API credentials through environment variables.

### Exact replication

Exact replication of the published results requires access to equivalent Scopus and SciVal exports corresponding to the study period. Researchers without access to these services can still inspect the analytical workflow, review the DOI corpus, and run the computational procedures on the synthetic sample data.

---

## Acknowledgements

The authors acknowledge the use of Scopus and SciVal data in the preparation of the study. Any errors or interpretations presented in the repository remain the responsibility of the authors.

---

## Contact

Questions, comments, suggestions, and bug reports are welcome through GitHub Issues. Researchers interested in reproducing, extending, or reusing the workflow are encouraged to open an issue in the repository.
