if !exists("g:autotype_cursor_aug")
    let g:autotype_cursor_aug = '*.rst,<buffer>'
endif
if !exists("g:autotype_word_sleep")
    let g:autotype_word_sleep = 150
endif
if !exists("g:autotype_line_sleep")
    let g:autotype_line_sleep = 400
endif
if !exists("g:autotype_char_sleep")
    let g:autotype_char_sleep = 30
endif
if !exists("g:autotype_by_char")
    let g:autotype_by_char = 1
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
        if g:autotype_by_char
            let chars = split(line, '.\zs')
            for char in chars
                call s:type(char, g:autotype_char_sleep)
            endfor
        else
            let words = split(line, '[[:space:]]\+\zs')
            for word in words
                call s:type(word, g:autotype_word_sleep)
            endfor
        endif
        call s:type("\r", g:autotype_line_sleep)
    endfor
endfun "}}}

fun! s:type(str,t ) abort "{{{
    exe "sleep ".a:t."m"
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
        echom '[AUTOTYPE] Typing Started.'
        call s:auto_type(readfile(a:f))
    catch /^Vim:Interrupt$/	" catch interrupts (CTRL-C)
        echom '[AUTOTYPE] Typing Stoped by user.'
    endtry
    let e_t = s:time()
    let time = printf("%.4f",(e_t-o_t))
    redraw
    echom "[AUTOTYPE] Typing finished. Using " . time . " seconds." 
endfun "}}}

com! -nargs=1 -complete=file AutoType call s:type_file(<q-args>)
