#' Syncronize full folder to dropbox path
#'
#' Copy an entire folder to dropbox. It allows filtering by
#' pattern or/and blacklist.
#' It optionally creates the sharing link.
#' It upload only changed files, using [tools::md5sum()] to
#' compare versions.
#'
#' @param path Local path in the computer
#' @param remote Remote path in dropbox
#' @param token Security token. [rdrop2::drop_auth()]
#' @param pattern Expression pattern to keep only those files.
#'   Pass into [base::list.files()].
#' @param blackList Character vector that will be used to remove
#'   files that match those expression.
#' @param share Whether create a sharing link or not.
#' @param dry Not perform action but list the files to be upload.
#' @param ... Options to pass to [rdrop2::drop_share()]
#'
#' @examples
#'
#' local <- "."
#' remote <- "path/to/drobox"
#' library(rdrop2)
#' # token <- readRDS("~/.droptoken.rds")
#' # sync(loca, remote, pattern = ".R", dry = TRUE)
#' @export
sync <- function(path, remote, token = NULL,
                 pattern = NULL, blackList = NULL, share = FALSE, dry = FALSE, ...) {
    stopifnot(is.character(path))
    stopifnot(dir.exists(path))
    remote <- clean(remote)
    path <- normalizePath(clean(path))
    message("Syncing ", path, " into ", remote)
    cache_fn <- file.path(path, ".r2dropSmart_cache.rda")
    share_fn <- file.path(path, ".r2dropSmart_share.rda")
    current_path <- getwd()
    fns <- list.files(path, full.names = TRUE, pattern = pattern, recursive = TRUE)
    if (!is.null(blackList)){
        black_matrix <- sapply(blackList, function(b){
            grepl(b, fns)
        })
        fns <- fns[which(rowSums(black_matrix) == 0)]
    }

    null = lapply(fns, function(fn){
        update(fn, remote, path, token, cache_fn, dry)
    })
    if(dry){
        return(invisible())
    }
    cache <- md5sum(fns)
    save(cache, file = cache_fn)
    if (share & !file.exists(share_fn)){
        s <- drop_share(remote, ...)
        save(s, file = share_fn)
    }
    if (share & file.exists(share_fn)){
        load(share_fn)
        return(s[["url"]])
    }
    invisible()
}

update <- function(fn, remote, parent, token, cache_fn, dry){
    cache = vector()
    if (file.exists(cache_fn)){
        load(cache_fn)
    }
    if (! fn %in% names(cache))
        cache[fn] = 0
    if (cache[fn] == md5sum(fn))
        message(fn, " is already updated. Skipping.")
    if (dry){
        if (cache[fn] != md5sum(fn))
            message("uploading ", fn, " into ", fix(remote, fn, parent))
        return(NULL)
    }
    if (cache[fn] != md5sum(fn))
        drop_upload(normalizePath(fn), path = fix(remote, fn, parent), dtoken = token)
}

fix <- function(dir, fn, parent){
    fn <- normalizePath(fn)
    subFolder <- clean(gsub(parent, "", dirname(fn)))
    if (parent == dirname(fn))
        return(dir)
    return(file.path(dir, subFolder))
}

clean <- function(dir){
    folders <- strsplit(dir, .Platform$file.sep)[[1]]
    do.call(file.path, as.list(folders[folders != ""]))
}
