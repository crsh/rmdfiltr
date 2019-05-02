test_that(
  "Convenience functions"
  , {
    expect_identical(
      add_lua_filter(filter_name = "wordcount", report = "silent")
      , add_wordcount_filter(report = "silent")
    )

    expect_identical(
      add_lua_filter(filter_name = "replace_ampersands", report = "silent")
      , add_replace_ampersands_filter(report = "silent")
    )

    citeproc_path <- utils::getFromNamespace("pandoc_citeproc", "rmarkdown")

    expect_identical(
      add_citeproc_filter(NULL)
      , c("--filter", citeproc_path())
    )
  }
)
