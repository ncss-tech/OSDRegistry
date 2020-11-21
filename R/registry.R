#' Refresh the repository/package data by automating regional queries to soil series server
#' @return Text files written to alphabetical folders containing raw Official Series Description text. Derivative calculations output to X. Etc.
#' @export
#' @importFrom textreadr read_doc
refresh_registry <- function() {
  
  # message("Downloading data...")
  
  # TODO: download ZIPs (pain in the butt; automate ASPX form submission by region?)
  
  message("Refreshing OSDs...")
  
  # unzip to single directory of .doc files
  
  lapply(file.path("raw", list.files("raw", "zip", ignore.case = TRUE)), unzip, exdir = "raw/doc")
  
  # read .doc files
  
  docfiles <-  list.files("raw/doc", "doc$")
  docletters <- substr(docfiles, 0, 1)
  
  osds <- file.path("raw/doc", docfiles)
  
  osdlist <- split(unlist(osds), docletters)
  
  # cat(names(osdlist))
  
  lapply(file.path("OSD", LETTERS), function(x) if (!dir.exists(x)) dir.create(x, recursive = TRUE))
  
  result <- lapply(1:length(LETTERS), function(i) {
      lapply(osdlist[[LETTERS[i]]], function(f) {
          write(try(textreadr::read_doc(f)), file.path("OSD", LETTERS[i], gsub("\\.doc", "\\.txt", basename(f))))
        })
    })
  
  message("Done!")
  
  return((length(result) == 26) - 1)
}
