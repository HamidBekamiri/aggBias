\name{aggregation_frontier}
\alias{aggregation_frontier}
\title{Aggregation Frontier}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{aggregation_frontier(model, ks, mu = NULL, covariance = NULL, ...)}
\arguments{
\item{model}{An io_model result.}
\item{mu}{Mean level shock; NULL uses zero.}
\item{covariance}{Shock covariance; NULL uses diag(f squared).}
\item{ks}{Candidate group counts.}
\item{...}{Additional arguments to optimize_aggregation.}
}
\value{A list with a frontier table and fits at each K.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
