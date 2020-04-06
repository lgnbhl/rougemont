## Making a hex sticker for BFS
library(hexSticker)
library(magick)
library(magrittr)
library(showtext)

font_add_google("Indie Flower")
## Automatically use showtext to render text
showtext_auto()

# ref: "https://upload.wikimedia.org/wikipedia/commons/d/df/Chevron_up_font_awesome.svg"
hexSticker::sticker("man/figures/empty_white.png",
                    package = "Rougemont 2.0",
                    p_color = "white", 
                    p_family = "Indie Flower",
                    p_size = 6,
                    p_y = 1,
                    h_size = 1.5, 
                    h_color = "grey80",
                    h_fill = "grey60", 
                    filename="man/figures/logo_large.png")

# MOD with Gimp: removing red borders.

rougemont_logo <- magick::image_read("man/figures/logo_large.png")
magick::image_scale(rougemont_logo, "130") %>%
  magick::image_write(path = "man/figures/logo.png", format = "png")

