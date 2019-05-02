test_that(
  "Vectorization"
  , {
    expect_identical(
      add_lua_filter(filter_name = c("replace_ampersands", "wordcount"), report = "silent")
      , c(add_replace_ampersands_filter(report = "silent"), add_wordcount_filter(report = "silent"))
    )

    expect_identical(
      add_custom_filter(filter_path = c("foo/bar", "bar/foo"), lua = c(TRUE, FALSE), report = "silent")
      , c("--lua-filter", "foo/bar", "--filter", "bar/foo")
    )

    expect_identical(
      add_custom_filter(filter_path = c("foo/bar", "bar/foo"), lua = TRUE, report = "silent")
      , c("--lua-filter", "foo/bar", "--lua-filter", "bar/foo")
    )
  }
)