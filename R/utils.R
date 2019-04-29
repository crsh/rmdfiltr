#' Verify minimum pandoc version
#'
#' Verifies that pandoc version 2.0 or later is available.
#'
#' @param report Character. In case pandoc version is < 2.0 errors if
#'   \code{error}, warns if \code{warn}, or remains silent otherwise.
#'
#' @return Logical. \code{TRUE} if pandoc version is 2.0 or later, \code{FALSE}
#'   otherwise.
#' @export
#'
#' @examples
#'
#' verify_pandoc_version(report = "silent")

verify_pandoc_version <- function(report = "error") {
  assertthat::assert_that(length(report) == 1)
  assertthat::assert_that(is.character(report))

  lua_available <- utils::compareVersion("2.0", as.character(rmarkdown::pandoc_version())) <= 0

  report_fun <- switch(
    report
    , "error" = stop
    , "warn" = function(x) { warning(x); return(FALSE) }
    , function(x) return(FALSE)
  )

  if(!lua_available) {
    report_fun("Lua filters require pandoc 2.0 or later (https://pandoc.org/).")
  }

  lua_available
}