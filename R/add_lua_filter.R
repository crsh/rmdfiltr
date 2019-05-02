#' Add filter to pandoc arguments
#'
#' Adds a filter call to the vector of pandoc command line arguments.
#'
#' @param args Character. (Vector of) pandoc command line arguments.
#' @param filter_name Character. Name(s) of the Lua filter to add. See details.
#' @param filter_path Character. Path to filter file.
#' @param lua Logical. Whether the filter(s) was written in Lua (results in
#'   \code{--lau-filter}-call) or not (results in \code{--filter}-call). Will be
#'   recycled to fit length of \code{filter_path}.
#' @inheritParams verify_pandoc_version
#'
#' @details The following Lua filters are available from \pkg{rmdfiltr}.
#'   Convenience functions named after the filter are available
#'   (e.g. \code{add_*_filter()}).
#'
#'   \describe{
#'     \item{\code{replace_ampersands}}{Searches for citations added by
#'       \code{pandoc-citeproc} and replaces \code{&} with \code{and} in all
#'       in-text citations (e.g., as required by APA style). If \code{lang} is
#'       specified in the documents YAML front matter, the corresponding
#'       translation is used, if available. Be sure to set \code{citeproc: no} in
#'       the YAML front matter of the document and call \code{pandoc-citeproc}
#'       manually (e.g., using \code{add_citeproc_filter}). For details see
#'       \code{vignette("replace_ampersands", package = "rmdfiltr")}.}
#'     \item{\code{wordcount}}{The body of the text and reference sections are
#'       counted separately. The word count for the text body does not contain,
#'       tables or images (or their captions). The filter reports the word count in
#'       the console or the R Markdown tab in 'RStudio'. For details see
#'       \code{vignette("wordcount", package = "rmdfiltr")}.}
#'   }
#'
#' @export
#'
#' @examples
#'
#' add_lua_filter(NULL, "wordcount", report = "silent")

add_lua_filter <- function(args = NULL, filter_name, report = "error") {
  assertthat::assert_that(is.character(filter_name))

  filter_path <- system.file(paste0(filter_name, ".lua"), package = "rmdfiltr")
  add_custom_filter(args, filter_path = filter_path, lua = TRUE, report = report)
}

#' @rdname add_lua_filter
#' @export
#' @examples
#' add_wordcount_filter(NULL, report = "silent")

add_wordcount_filter <- function(args = NULL, report = "error") {
  add_lua_filter(args, "wordcount", report = report)
}

#' @rdname add_lua_filter
#' @export
#' @examples
#' add_replace_ampersands_filter(NULL, report = "silent")

add_replace_ampersands_filter <- function(args = NULL, report = "error") {
  add_lua_filter(args, "replace_ampersands", report = report)
}

#' @rdname add_lua_filter
#' @export
#' @examples
#' add_citeproc_filter(NULL)

add_citeproc_filter <- function(args = NULL, report = "error") {
  citeproc_path <- utils::getFromNamespace("pandoc_citeproc", "rmarkdown")
  add_custom_filter(args, filter_path = citeproc_path(), lua = FALSE, report = report)
}

#' @rdname add_lua_filter
#' @export
#' @examples
#' add_custom_filter(NULL, filter_path = "foo/bar")

add_custom_filter <- function(args = NULL, filter_path, lua = FALSE, report = "error") {
  if(!is.null(args)) assertthat::assert_that(is.character(args))
  assertthat::assert_that(is.character(filter_path))
  assertthat::assert_that(is.logical(lua))

  if(any(lua)) verify_pandoc_version(report = report)

  lua <- rep_len(lua, length(filter_path))
  filter_call <- ifelse(lua, "--lua-filter", "--filter")

  for(i in seq_along(filter_path)) {
    args <- c(args, filter_call[i], filter_path[i])
  }

  args
}
