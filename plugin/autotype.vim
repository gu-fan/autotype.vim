" NOTE: q-args are quoted with '"'
com! -nargs=1 -bar ECHO call autotype#echo(<q-args>)
com! -nargs=1 -bar BLINK call autotype#blink(<q-args>)
com! -nargs=1 -bar TYPE call autotype#type_line(<q-args>)
" XXX Met can not use -bang  as always get a E15 error
com! -nargs=1 -bar -bang NORMAL call autotype#normal("<bang>", <q-args>)

com! -nargs=1 -complete=file AutoType call autotype#type_file(<q-args>)

