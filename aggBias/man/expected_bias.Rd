\name{expected_bias}
\alias{expected_bias}
\title{Expected Bias}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{expected_bias(model, group, mu = NULL, covariance = NULL, weights = NULL)}
\arguments{
\item{group}{Industry group labels; columns follow sorted unique labels.}
\item{model}{An io_model result.}
\item{mu}{Mean level shock; NULL uses zero.}
\item{covariance}{Shock covariance; NULL uses diag(f squared).}
\item{weights}{Nonnegative industry priorities; group weight is maximum member priority.}
}
\value{A nonnegative scalar expected squared error.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
