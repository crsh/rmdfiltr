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
    report_fun("Lua-filters require pandoc 2.0 or later (https://pandoc.org/).")
  }

  lua_available
}


#' Add Lua-filter to pandoc arguments
#'
#' Adds a Lua-filter supplied by \pkg{rmdfiltr} to the vector of pandoc command
#' line arguments.
#'
#' @param args Character. (Vector of) pandoc command line arguments.
#' @param filter_name Character. Name of the Lua-filter to add. See details.
#'
#' @details The following Lua-filters are available. Convenience functions named
#'   after the filter are available (e.g. \code{add_*_filter()}).
#'
#' \describe{
#'   \item{\code{}}{}
#' }
#'
#' @return Character vector of pandoc command line arguments.
#'
#' @family add_lua_filter
#' @export
#'
#' @examples
#'
#' add_lua_filter(NULL, "wordcount")

add_lua_filter <- function(args, filter_name) {
  if(!is.null(args)) assertthat::assert_that(is.character(args))
  assertthat::assert_that(length(filter_name) == 1)
  assertthat::assert_that(is.character(filter_name))

  verify_pandoc_version()

  filter_path <- system.file(filter_name, package = "rmdfiltr")
  args <- c(args, "--lua-filter", filter_path)

  args
}

#' Add Lua-filter to count words
#'
#' Adds a Lua-filter to count words to the vector of pandoc command line
#' arguments.
#'
#' @inheritParams add_lua_filter
#'
#' @return Character vector of pandoc command line arguments.
#' @family add_lua_filter
#' @rdname add_lua_filter
#' @export
#'
#' @examples
#' add_wordcount_filter(NULL)

add_wordcount_filter <- function(args) {
  add_lua_filter(args, "wordcount")
}
