context("Paths")

test_that("clean", {
    expect_equal(clean("test/trailing/"), "test/trailing")
})

test_that("fix", {
    expect_equal(fix("remote/final", "."), "remote/final")
    expect_equal(fix("remote/final", "./man/file.R"), "remote/final/man")
    expect_equal(fix("remote/final", "./man/man2/file.R"), "remote/final/man/man2")
})

test_that("sync", {
    print(getwd())
    expect_error(sync(123, "remote", "token"))
    expect_error(sync(".fake", "remote", "token"))
    expect_true(any(grepl("Rproj", sync("../..", "remote", dry = TRUE))))
    expect_false(any(grepl("Rproj", sync("../..", "remote", blackList = "Rproj", dry = TRUE))))
    expect_true(any(grepl("sync.R", sync("../..", "remote", pattern = ".R", dry = TRUE))))
})
