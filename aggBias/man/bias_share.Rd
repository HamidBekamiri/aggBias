\name{bias_share}
\alias{bias_share}
\title{Bias Share}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{bias_share(model, group, shocks)}
\arguments{
\item{group}{Industry group labels; columns follow sorted unique labels.}
\item{model}{An io_model result.}
\item{shocks}{Numeric matrix with shock draws in rows.}
}
\value{A vector of error fractions; NA for zero responses.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
