test_that(
  "Convenience functions"
  , {
    expect_identical(add_lua_filter("wordcount"), add_wordcount_filter())
  }
)