# r2dropSmart

Sync entire folders to dropbox with rdrop2 package

## Install

```
devtools::install_github("lpantano/r2dropSmart")
```

## Usage

To sync an entire folder use:

```
sync(".", "path/in/dropbox", token = token, dry = TRUE)
```

`dry` option will show the files to update but do nothing.

This will copy the content of the current `.` folder to `path/in/dropbox`.

Use `pattern` option to include only specific files, 
or use `blackList` to ignore others. The latest allows more than one character.
For instance, `blackList = c("data", "Rmd", ".yaml", ".bib")`

The option `share` will return the sharing url from dropbox.

More complex example:

```
library(r2dropSmart)
token <- readRDS("~/.droptoken.rds")

sync(".", remote = dropdir, token = token,
     blackList = c("cache", "data", "Rmd", "R$", "_files", "_cache"),
     dry = T,
     share = T)
```

**shared link gets copied to clipboard at the end of the sync**

## How it works

It uses list.files to get all the files from the folder and the upload with
`rdrop2::drop_upload`. It keeps the `dir` structure from the `local` 
folder you want to sync. That means that if `path` is the local folder, and 
`remote` is your remote folder, all that is in `path` goes to `remote`.

It uses `pattern` from `list.files` to include only some files, or `blackList`,
a character vector, to exclude files matching any of the values in there.

The first time it would create a `cache` file in the `local` folder under the
name `.r2dropSmart_cache` that will be used to compare versions. NOTE: IT IS
NOT COMPARING FROM THE REMOTE, BUT FROM THE LAST TIME YOU UPLOADED FILES.

It won't remove files that are not in local but are in remote.

It uses `rdrop2::drop_shate` to create the link. The info is stored 
in `.r2dropSamrt` in the `local` folder.
