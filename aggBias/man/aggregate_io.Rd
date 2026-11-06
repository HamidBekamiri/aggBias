\name{aggregate_io}
\alias{aggregate_io}
\title{Aggregate Io}
\description{Shock-aware input-output aggregation using the manuscript expected squared error objective.}
\usage{aggregate_io(model, group)}
\arguments{
\item{group}{Industry group labels; columns follow sorted unique labels.}
\item{model}{An io_model result.}
}
\value{An aggregated IO model.}
\details{The method uses local search and does not guarantee a global optimum. See the project README for equations, constraints and information-rung conventions.}
