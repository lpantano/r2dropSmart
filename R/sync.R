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
#' @param force Force to upload files to drobox.
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
                 pattern = NULL, blackList = NULL, share = FALSE,
                 dry = FALSE, force = FALSE, ...) {
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

    invisible(lapply(fns, function(fn){
        update(fn, remote, path, token, cache_fn, dry, force)
    }))
    if(dry){
        return(invisible())
    }
    cache <- md5sum(fns)
    save(cache, file = cache_fn)
    if (share & !file.exists(share_fn)){
        s <- drop_smart_share(remote, dtoken = token, ...)
        save(s, file = share_fn)
    }
    if (share & file.exists(share_fn)){
        load(share_fn)
        write_clip(gsub("dl=0", "dl=1", s))
        return(s)
    }
    invisible()
}

update <- function(fn, remote, parent, token, cache_fn, dry, force){
    cache = vector()
    if (file.exists(cache_fn)){
        load(cache_fn)
    }
    if (! fn %in% names(cache))
        cache[fn] = 0
    if (cache[fn] == md5sum(fn))
        message("Skipping: ", basename(fn), ", is already updated. ")
    if (dry){
        if (cache[fn] != md5sum(fn))
            message("Uploading: ", basename(fn), " into ", fix(remote, fn, parent))
        return(NULL)
    }
    if (cache[fn] != md5sum(fn) | force)
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

#' Share or get a path in your dropbox account
#'
#' It will create a shared link with public settings or
#' get the link if already exists.
#'
#' @param path Local path in the computer
#' @param token Security token. [rdrop2::drop_auth()]
#'
#' @examples
#' dropdir = "test/folder"
#' # token <- readRDS("~/.droptoken.rds")
#' # drop_smart_share(dropdir, dtoken = token)
#' @export
drop_smart_share <-
    function (path, dtoken)
    {
        if (length(path) && !grepl("^/", path)) {
            path <- paste0("/", path)
        }
        # browser()
        share_url <- "https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings"
        req <- httr::POST(url = share_url, httr::config(token = dtoken),
                          body = list(path = path), encode = "json")
        response <- httr::content(req)
        browser()
        if ("url"  %in% response){
            write_clip(gsub("dl=0", "dl=1", response[["url"]]))
            return(response[["url"]])
        }
        message("It seems link already exists. Getting url.")
        share_url <- "https://api.dropboxapi.com/2/sharing/share_folder"
        req <- httr::POST(url = share_url, httr::config(token = dtoken),
                          body = list(path = path), encode = "json")
        res <- httr::content(req)
        link <- NULL
        if ("preview_url"  %in%  names(res))
            link <- res$preview_url
        if ("error"  %in% names(res))
            link <- res$error$bad_path$preview_url
        if (!is.null(link)){
            write_clip(gsub("dl=0", "dl=1", link))
            return(link)
        }
        return(link)
    }

