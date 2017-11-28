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

Use `pattern` option to include only specific files, or use `blackList` to ignore others.

The option `share` will return the sharing url from dropbox.
