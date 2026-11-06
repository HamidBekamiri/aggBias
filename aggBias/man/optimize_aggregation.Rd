\name{optimize_aggregation}
\alias{optimize_aggregation}
\title{Optimize Aggregation}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{optimize_aggregation(model, k, mu = NULL, covariance = NULL,
  starts = list(), n_random = 5L, seed = 1L, max_pass = 20L,
  tolerance = 1e-9, weights = NULL, closed = list(),
  must_link = list(), cannot_link = list())}
\arguments{
\item{model}{An io_model result.}
\item{mu}{Mean level shock; NULL uses zero.}
\item{covariance}{Shock covariance; NULL uses diag(f squared).}
\item{weights}{Nonnegative industry priorities; group weight is maximum member priority.}
\item{k}{Number of nonempty groups.}
\item{starts}{List of feasible partitions labelled 1 through k.}
\item{n_random}{Number of balanced random starts.}
\item{seed}{Random seed; caller random state is restored.}
\item{max_pass}{Maximum greedy passes.}
\item{tolerance}{Minimum absolute decrease to accept a move.}
\item{closed}{List of exclusive blocks using 1-based industry indices.}
\item{must_link}{List of disjoint blocks that move together.}
\item{cannot_link}{List of pairs that must remain separate.}
}
\value{A list with group, loss, rms_bias and per-start runs.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
