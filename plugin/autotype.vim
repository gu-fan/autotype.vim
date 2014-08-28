if !exists("g:autotype_cursor_aug")
    let g:autotype_cursor_aug = '*.rst,<buffer>'
endif
if !exists("g:autotype_word_sleep")
    let g:autotype_word_sleep = 200
endif
if !exists("g:autotype_line_sleep")
    let g:autotype_line_sleep = 500
endif

function! s:time() "{{{
    if has("reltime")
        return str2float(reltimestr(reltime()))
    else
        return localtime()
    endif
endfunction "}}}
fun! s:auto_type(lines) abort "{{{
    " lines are a list contain lines
    " Each line are split by " " and typed
    for line in a:lines
        " >>> echo split("1 2 3",'[[:space:]]\+\zs')
        " ['1 ', '2 ', '3']
        let words = split(line, '[[:space:]]\+\zs')
        for word in words
            call s:type(word)
        endfor
        call s:type("\r", g:autotype_line_sleep)
    endfor
endfun "}}}

fun! s:type(str,...) abort "{{{
    let t= a:0 ? a:1 : g:autotype_word_sleep
    exe "sleep ".t."m"
    exe "norm! a". a:str
    redraw

    for au_ptn in split(g:autotype_cursor_aug, ',')
        " doau CursorMoved,CursorMovedI *.rst
        " doau CursorMoved,CursorMovedI <buffer>
        exec "doau CursorMoved,CursorMovedI ". au_ptn
    endfor
endfun "}}}

fun! s:type_file(f) "{{{
    let o_t = s:time()
    try
        echom '[AUTOTYPE] Started.'
        call s:auto_type(readfile(a:f))
    catch /^Vim:Interrupt$/	" catch interrupts (CTRL-C)
        echom '[AUTOTYPE] Stoped by user.'
    endtry
    let e_t = s:time()
    let time = printf("%.4f",(e_t-o_t))
    echom "[AUTOTYPE] Typing finished. Using " . time . " seconds." 
endfun "}}}

com! -nargs=1 -complete=file AutoType call s:type_file(<q-args>)
