" TAGS: "{{{
" NOTE: q-args are quoted with '"'
com! -nargs=1 -count=0 -bar -bang ECHO call autotype#echo(<q-bang>, <count>, <args>)
com! -nargs=1 -count=0 -bar -bang BLINK call autotype#blink(<q-bang>,<count>, <args>)

com! -nargs=1 -bar -bang TYPE call autotype#append(<q-bang>,<args>)
com! -nargs=1 -bar -bang APPEND call autotype#append(<q-bang>,<args>)
com! -nargs=1 -bar -bang INSERT call autotype#insert(<q-bang>, <args>)

" XXX Met can not use -bang  as always get a E15 error
com! -nargs=1 -bar -bang NORMAL call autotype#normal("<bang>", <q-args>)

com! -nargs=1 INCLUDE call autotype#include(<q-args>)
"}}}

" MAIN: "{{{
com! -nargs=? -complete=file AtpSpd call autotype#atp_spd(<q-args>)
com! -nargs=? -complete=file AutoType call autotype#type_file(<q-args>)
"}}}
