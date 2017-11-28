context("Paths")

test_that("clean", {
    expect_equal(clean("test/trailing/"), "test/trailing")
})

test_that("fix", {
    parent <- normalizePath(file.path(getwd(), "..", ".."))
    expect_equal(fix("remote/final", "../../DESCRIPTION", parent), "remote/final")
    expect_equal(fix("remote/final", "../../man/sync.Rd", parent), "remote/final/man")
    expect_equal(fix("remote/final", "../../tests/testthat/test_internal.R", parent), "remote/final/tests/testthat")
})

test_that("sync", {
    expect_error(sync(123, "remote", "token"))
    expect_error(sync(".fake", "remote", "token"))

    expect_message(sync("../..", "remote", dry = TRUE), "Rproj")
    # expect_message(sync("../..", "remote", blackList = "Rproj", dry = TRUE))
    expect_message(sync("../..", "remote", pattern = ".R", dry = TRUE), "sync.R")
})
