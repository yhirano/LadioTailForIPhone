#/bin/sh

sips -Z 30 clock.png --out tab_newly.png
sips -Z 60 clock.png --out tab_newly@2x.png
sips -Z 30 headphones_white.png --out tab_listeners.png
sips -Z 60 headphones_white.png --out tab_listeners@2x.png
sips -Z 30 mic.png --out tab_dj.png
sips -Z 60 mic.png --out tab_dj@2x.png
sips -Z 30 others.png --out tab_others.png
sips -Z 60 others.png --out tab_others@2x.png
sips -Z 30 text_letter_t.png --out tab_title.png
sips -Z 60 text_letter_t.png --out tab_title@2x.png

sips -Z 20 star_fav_white.png --out navbar_favorite_white.png
sips -Z 40 star_fav_white.png --out navbar_favorite_white@2x.png
sips -Z 20 star_fav_yellow.png --out navbar_favorite_yellow.png
sips -Z 40 star_fav_yellow.png --out navbar_favorite_yellow@2x.png
