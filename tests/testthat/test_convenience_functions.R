test_that(
  "Convenience functions"
  , {
    expect_identical(add_lua_filter(filter_name = "wordcount"), add_wordcount_filter())
    expect_identical(add_lua_filter(filter_name = "replace_ampersands"), add_replace_ampersands_filter())
  }
)
