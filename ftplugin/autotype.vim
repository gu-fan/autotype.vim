
" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo-=C

call autotype#init()

setlocal com=sr:{#\ ,mb:\ ,e:\ #}
" Comments start with a double quote
setlocal commentstring={#\ %s\ #}

let &cpo = s:cpo_save
unlet s:cpo_save
