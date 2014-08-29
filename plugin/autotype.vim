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
if !exists("g:autotype_cmd_sleep")
    let g:autotype_cmd_sleep = 800
endif
if !exists("g:autotype_echo_sleep")
    let g:autotype_echo_sleep = 2000
endif
if !exists("g:autotype_by_char")
    let g:autotype_by_char = 1
endif

" NOTE: We should make sure this is single quote string 
" That are used for patterns
" :h literal-string
if !exists("g:autotype_cmd_start")
    let g:autotype_cmd_start = '\^\['
endif
if !exists("g:autotype_cmd_end")
    let g:autotype_cmd_end = '\^\]'
endif
if !exists("g:autotype_var_start")
    let g:autotype_var_start = '\^{'
endif
if !exists("g:autotype_var_end")
    let g:autotype_var_end = '\^}'
endif
if !exists("g:autotype_cmd_once")
    let g:autotype_cmd_once = '\^_'
endif

" Only recongnize the ptn start without a preceding '!'
let s:bgn = g:autotype_cmd_start
let s:end =  g:autotype_cmd_end
let s:_bgn = '!\@<!'.g:autotype_cmd_start
let s:_end = '!\@<!'. g:autotype_cmd_end
let s:_once = '!\@<!'.g:autotype_cmd_once
let s:_bgns = '^'.s:bgn.s:bgn.'$'
let s:_ends = '^'.s:end.s:end.'$'
let s:v_bgn = '!\@<!'.g:autotype_var_start
let s:v_end = '!\@<!'.g:autotype_var_end
let s:tempfile = tempname()

let s:ptn_once = s:_once .'\(\w\+\)\%(\s\|$\)\ze'
let s:ptn_cmd = s:_bgn.'\(.\{-}\)'.s:_end
let s:ptn_var = s:v_bgn.'\(.\{-}\)'.s:v_end

function! s:time() "{{{
    if has("reltime")
        return str2float(reltimestr(reltime()))
    else
        return localtime()
    endif
endfunction "}}}

fun! s:blink(str,...) "{{{
    let hl = a:0 ? get(a:1, 'hl', 'ModeMsg') : 'ModeMsg'
    let t = a:0 ? get(a:1, 't', g:autotype_echo_sleep) : g:autotype_echo_sleep
    for i in range(str2nr(t)/300)

        echohl  Normal
        echo '[AUTOTYPE]'
        echohl Normal
        echon " ". a:str
        redraw
        sleep 150m

        exe "echohl ". hl
        echo '[AUTOTYPE]'
        echohl Normal
        echon " ". a:str
        redraw
        sleep 150m
    endfor
endfun "}}}
fun! s:echo(str,...) "{{{
    let hl = a:0 ? get(a:1, 'hl', 'ModeMsg') : 'ModeMsg'
    let t = a:0 ? get(a:1, 't', g:autotype_echo_sleep) : g:autotype_echo_sleep
    exe "echohl ". hl
    echo '[AUTOTYPE]'
    echohl Normal
    echon ' '. a:str
    redraw
    exe "sl ".t."m"
endfun "}}}
fun! s:normal(bang, str) "{{{
    " Wrap the string with "" for "\<C-W>" keys
    exe 'exe "norm'.a:bang.' '.a:str.'"'
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


fun! s:type_norm(line) "{{{
    " Type a normal line, by char or by word
    
    let line = a:line

    if g:autotype_by_char
        let chars = split(line, '.\zs')
        for char in chars
            call s:type(char, g:autotype_char_sleep)
        endfor
    else
        " >>> echo split("1 2 3",'[[:space:]]\+\zs')
        " ['1 ', '2 ', '3']
        let words = split(line, '[[:space:]]\+\zs')
        for word in words
            call s:type(word, g:autotype_word_sleep)
        endfor
    endif
endfun "}}}

fun! s:type_cmd(cmd) "{{{
    let cmd = a:cmd   
    exe a:cmd
    exe "slee ".g:autotype_cmd_sleep ."m"
endfun "}}}
fun! s:exe_cmds(cmds) "{{{
    " cmds is a list of lines
    " call writefile(a:cmds, s:tempfile)
    " exe "so " s:tempfile
    for cmd in a:cmds
        exe cmd
        echom cmd
    endfor
    exe "slee ".g:autotype_cmd_sleep ."m"
endfun "}}}



fun! s:parse_line(line)
    " parse each line and return the parsing object.
    " " Make ^_ working
    if line =~ s:ptn_once
        " >>> let line = '34^_567 8910' 
        " >>> let _list = matchlist(line, s:_once.'\(\w\+\)\%(\s\|$\)\ze')
        " >>> echo _list[1]
        " 567
        let _list = matchlist(line, s:ptn_once)
        let idx = match(line, s:ptn_once)
        " replace the pattern to ignore further catch
        call substitute(line, s:ptn_once, '!!\1', '')
        call add(parts, {'type': 'cmd', 'norm '._list[1], 'idx':idx})
    endif

    if line =~  s:ptn_cmd
        let _list = matchlist(line, s:ptn_cmd)
        let idx = match(line, s:ptn_cmd)
        " >>> let line = '^[343 3434 ^] ^[ 3434 343 4^]'
        " >>> echo  matchlist(line, s:ptn_cmd)
        " >>> echo  match(line, s:ptn_cmd)
        " >>> echo substitute(line, s:ptn_cmd, '!!\1!!', '')
        call substitute(line, s:ptn_cmd, '!!\1!!', '')
        call add(parts, {'type': 'cmd', _list[1], 'idx':idx})
    endif
    if line =~  s:ptn_var
        let _list = matchlist(line, s:ptn_var)
        let idx = match(line, s:ptn_var)
        " >>> let line = '^{343 3434 ^} ^[ 3434 343 4^]'
        " >>> echo  matchlist(line, s:ptn_var)
        " >>> echo  match(line, s:ptn_var)
        " >>> echo substitute(line, s:ptn_var, '!!\1!!', '')
        call substitute(line, s:ptn_var, '!!\1!!', '')
        call add(parts, {'type': 'var', _list[1], 'idx':idx})
    endif
    
endfun


fun! s:auto_type(lines) abort "{{{
    " lines are a list contain lines
    " Each line are split by " " and typed
    let cmds = []
    let cmd_mode = 0
    for line in a:lines

        " lines in ^[^[ are commands
        if line =~ s:_bgns
            let cmds = []
            let cmd_mode = 1
            continue
        endif
        if line =~ s:_ends
            call s:exe_cmds(cmds)
            let cmd_mode = 0
            continue
        endif

        if cmd_mode == 1
            call add(cmds, line)
            continue
        endif
        
        " parts are used for running
        " type: norm/var/cmd
        " str: str
        " parts = {{'type':'norm','str':str}}
        parts = []
        


        " " Make ^O working as in insert mode
        " if line =~ s:_once
        "     " >>> let line = '34567'
        "     " >>> let line = substitute(line, '\(\w\+\)\%(\s\|$\)\ze','norm \1','g')
        "     " >>> echo line
        "     " 34^[norm 567^]8910
        "     let line = substitute(line, s:_once.'\(\w\+\)\%(\s\|$\)\ze',s:bgn.'norm \1'.s:end,'g')
        " endif


        " " Lines contain ^[ ^] are commands
        " while line =~ s:_bgn.'.*'.s:_end
        "     " >>> let line = 'norm 1cmd 1 norm 2cmd 2 norm 3'
        "     " >>> let list = matchlist(line, '^\(.\{-}\)\(.\{-}\)\(.\{-}\)$')
        "     " >>> echo list[1] list[2]
        "     " norm 1 cmd 1
        "     let _list = matchlist(line, '^\(.\{-}\)'.s:_bgn.'\(.\{-}\)'.s:_end.'\(.\{-}\)$')
        "     let _nor = _list[1]
        "     let _cmd = _list[2]
        "     let line = _list[3]
        "
        "     call s:type_norm(_nor)
        "     call s:type_cmd(_cmd)
        " endwhile

        " " Lines contain ^{ ^} are variables
        " while line =~ s:v_bgn.'.*'.s:v_end
        "     " >>> let line = 'norm 1cmd 1 norm 2cmd 2 norm 3'
        "     " >>> let list = matchlist(line, '^\(.\{-}\)\(.\{-}\)\(.\{-}\)$')
        "     " >>> echo list[1] list[2]
        "     " norm 1 cmd 1
        "     let _list = matchlist(line, '^\(.\{-}\)'.s:_bgn.'\(.\{-}\)'.s:_end.'\(.\{-}\)$')
        "     let _nor = _list[1]
        "     let _cmd = _list[2]
        "     let line = _list[3]
        "
        "     call s:type_norm(_nor)
        "     call s:type_cmd(_cmd)
        " endwhile

        call s:type_norm(line)

        call s:type("\r", g:autotype_line_sleep)

    endfor
endfun "}}}

fun! s:type_file(f) "{{{
    let o_t = s:time()
    try
        call s:echo("Typing started.", {'hl': "MoreMsg", 't':1})
        call s:auto_type(readfile(a:f))
    catch /^Vim:Interrupt$/	" catch interrupts (CTRL-C)
        call s:echo("Typing Stopped by user.", {'hl': "WarningMsg",'t':1})
    endtry
    let e_t = s:time()
    let time = printf("%.4f",(e_t-o_t))
    call s:echo("Typing finished. Using " . time . " seconds.",{'hl': "MoreMsg", 't':1})
endfun "}}}

com! -nargs=1 -bar ECHO call s:echo(<q-args>)
com! -nargs=1 -bar BLINK call s:blink(<q-args>)

com! -nargs=1 -complete=file AutoType call s:type_file(<q-args>)

" XXX
" Met can not use -bang  as always get a E15 error
com! -nargs=1 -bar -bang NORMAL call s:normal("<bang>", <q-args>)
