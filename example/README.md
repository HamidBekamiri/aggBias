# aggBias CSV-based numerical example

This is the four-industry numerical validation example included in the tests of `aggBias` version 0.1.0, adapted so every input is read from CSV instead of being typed into R code. It illustrates the paper's expected aggregation-bias equation, but it is **not** the full Danish 117-industry empirical dataset.

## Run

From Terminal, in this folder:

```bash
Rscript run_example.R
```

Or set the working directory in RStudio to this example folder and run `source("run_example.R")`. The script automatically installs `aggBias` from `HamidBekamiri/aggBias` if needed.

## Inputs

- `transactions.csv`: intermediate transaction matrix `Z`, industries as rows and columns.
- `final_demand.csv`: final demand `f` for each industry.
- `shocks.csv`: mean final-demand shock `mu` and one realized shock.
- `covariance.csv`: shock covariance matrix `Sigma`.
- `initial_grouping.csv`: each industry's starting sector label.

Industry names and their ordering must match across all files.

## Outputs

- `output_shock_responses.csv`
- `output_grouping.csv`
- `output_frontier.csv`
- `output_frontier.png`

The expected squared bias for the initial grouping should be approximately `0.057755803080969614`. Units depend on the supplied data. A multistart search finds a local best grouping; it is not guaranteed globally optimal.
