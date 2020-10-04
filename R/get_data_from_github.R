# Transform XML files into tidy dataframes
# https://community.rstudio.com/t/generate-a-data-frame-from-many-xml-files/10214/7

library(xml2)
library(tidyverse)

# Make a temporary file (tf) and a temporary folder (tdir)
tf <- tempfile(tmpdir = tdir <- tempdir())

## Download the zip file 
download.file("https://github.com/eRougemont/livres/archive/master.zip", tf)

## Unzip it in the temp folder
xml_files <- unzip(tf, exdir = tdir)

files_to_import <- xml_files %>%
  str_subset(pattern = ".xml$")

head(files_to_import)

t <- read_xml(xml_files[4])

require(XML)
xmlToDataFrame(files_to_import[1]) %>%
  as_data_frame()

xml2::read_xml(files_to_import[1]) %>%
  xml2::url_parse("chapter")

df <- xml_find_all(t, "//VALDISTRIKT") %>% 
  map_dfr(~ {
    # extract the attributes from the parent tag as a data.frame
    parent <- xml_attrs(.x) %>% enframe() %>% spread(name, value)
    # make a data.frame out of the attributes of the kids
    kids <- xml_children(.x) %>% map_dfr(~ as.list(xml_attrs(.x)))
    # combine them (bind_cols does not repeat parent rows)
    cbind.data.frame(parent, kids) %>% set_tidy_names() %>% as_tibble() 
  })
