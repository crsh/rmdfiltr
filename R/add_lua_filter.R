#' Add Lua filter to pandoc arguments
#'
#' Adds a Lua filter supplied by \pkg{rmdfiltr} to the vector of pandoc command
#' line arguments.
#'
#' @param args Character. (Vector of) pandoc command line arguments.
#' @param filter_name Character. Name of the Lua filter to add. See details.
#' @inheritParams verify_pandoc_version
#'
#' @details The following Lua filters are available. Convenience functions named
#'   after the filter are available (e.g. \code{add_*_filter()}).
#'
#' \describe{
#'   \item{\code{wordcount}}{The body of the text and reference sections are
#'   counted separately. The word count for the text body does not contain,
#'   tables or images (or their captions). The filter reports the word count in
#'   the console or the R Markdown tab in RStudio.}
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

add_lua_filter <- function(args = NULL, filter_name, report = "error") {
  if(!is.null(args)) assertthat::assert_that(is.character(args))
  assertthat::assert_that(is.character(filter_name))

  if(verify_pandoc_version(report = report)) {
    for(i in filter_name) {
      filter_path <- system.file(paste0(i, ".lua"), package = "rmdfiltr")
      args <- c(args, "--lua-filter", filter_path)
    }
  }

  args
}

#' Add  to count words
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

add_wordcount_filter <- function(args = NULL, report = "error") {
  add_lua_filter(args, "wordcount")
}
