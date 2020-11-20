# refresh the database by automating regional queries to soil series server
print("Installing dependencies...")

install.packages("textreadr")

library(textreadr)

# TODO: download ZIPs (pain in the butt; automate ASPX form submission by region?)
# 
print("Downloading data...")

print("Refreshing OSDs...")

# unzip to single directory of .doc files
lapply(file.path("raw", list.files("raw", "zip", ignore.case = TRUE)), unzip, exdir = "raw/doc")

# read .doc files
osds <- lapply(file.path("raw/doc", list.files("raw/doc")), read_doc, trim = TRUE, format = FALSE)

# TODO: save as .txt to correct (first letter) folders

print("Done!")
