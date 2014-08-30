" NOTE: q-args are quoted with '"'
com! -nargs=1 -bar ECHO call autotype#echo('"'.eval(<q-args>).'"')
com! -nargs=1 -bar BLINK call autotype#blink('"'.eval(<q-args>).'"')
com! -nargs=1 -bar TYPE call autotype#type_line('"'.eval(<q-args>).'"')
" XXX Met can not use -bang  as always get a E15 error
com! -nargs=1 -bar -bang NORMAL call autotype#normal("<bang>", <q-args>)

com! -nargs=? -complete=file AtpSpd call autotype#atp_spd(<q-args>)

com! -nargs=? -complete=file AutoType call autotype#type_file(<q-args>)

