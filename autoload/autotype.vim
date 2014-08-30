let s:save_cpo = &cpo
set cpo&vim

function! s:default(option,value) "{{{
    if !exists(a:option)
        let {a:option} = a:value
        return 0
    endif
    return 1
endfunction "}}}

function! s:set(option,value) "{{{
    " XXX
    " We can not use: let {g:opt_dict.key} = val
    " Don't know why...
    
    let {a:option} = a:value

endfunction "}}}
fun! autotype#init() "{{{
    let def_list = [
        \ ["g:autotype_speed", '30'],
        \ ["g:autotype_syntax_type", 'jinja'],
        \ ["g:autotype_cursor_aug", '*.rst,<buffer>'],
        \ ["g:autotype_file_directory", ''],
        \ ]

    let s:fdirs = expand('<sfile>:p:h:h').'/autotype'
    if g:autotype_file_directory != ''
        let s:fdirs .= ','.expand(g:autotype_file_directory)
    endif

    for [opt, val] in def_list
        call s:set(opt, val)
        unlet val
    endfor
    
    let opts = []
    let spd = str2nr(g:autotype_speed)
    let spd = spd != 0 ? spd : 30

    if spd <= 400 
        call s:set("g:autotype_skip_by", 'char')
    elseif  spd <= 1000
        call s:set("g:autotype_skip_by", 'word')
    else
        call s:set("g:autotype_skip_by", 'line')
    endif

    let speed_opt = [
                \ ["g:autotype_sleep_word", 2500/spd],
                \ ["g:autotype_sleep_line", 10000/spd],
                \ ["g:autotype_sleep_char", 700/spd],
                \ ["g:autotype_sleep_cmd",  (10000/spd)+100],
                \ ["g:autotype_sleep_echo", (30000/spd)+500],
                \ ]

    " call extend(opts, speed_opt)
    for [opt, val] in speed_opt
        call s:set(opt, val)
        unlet val
    endfor
    " echom string(speed_opt)


    if g:autotype_syntax_type == 'jinja'
        let syn_opt = [
            \ ["g:autotype_syn_cmd_bgn",  '{%'],
            \ ["g:autotype_syn_cmd_end",  '%}'],
            \ ["g:autotype_syn_cmds_bgn", '{@'],
            \ ["g:autotype_syn_cmds_end", '@}'],
            \ ["g:autotype_syn_var_bgn",  '{{'],
            \ ["g:autotype_syn_var_end",  '}}'],
            \ ["g:autotype_syn_cmd_once", '^_'],
            \ ] 
    else
        let syn_opt = [
            \ ["g:autotype_syn_cmd_bgn", '\^\['],
            \ ["g:autotype_syn_cmd_end", '\^\]'],
            \ ["g:autotype_syn_cmds_bgn", '\^\[\^\['],
            \ ["g:autotype_syn_cmds_end", '\^\]\^\]'],
            \ ["g:autotype_syn_var_bgn", '\^[{]'],
            \ ["g:autotype_syn_var_end", '\^[}]'],
            \ ["g:autotype_syn_cmd_once", '\^_'],
            \ ] 
    endif
    
    if g:autotype_syntax_type != 'autotype' && g:autotype_syntax_type != 'jinja' 
        for [opt, val] in syn_opt
            call s:default(opt, val)
            unlet val
        endfor
    else
        for [opt, val] in syn_opt
            call s:set(opt, val)
            unlet val
        endfor
    endif


    
    
    " Generate Syntax patterns
    
    " NOTE: We should make sure these are single quote string 
    " That are used for patterns
    " :h literal-string
    " Only recongnize the ptn start without a preceding '!'
    let s:bgn = g:autotype_syn_cmd_bgn
    let s:end =  g:autotype_syn_cmd_end
    let s:c_bgn = '!\@<!'.g:autotype_syn_cmd_bgn
    let s:c_end = '!\@<!'. g:autotype_syn_cmd_end
    let s:c_once = '!\@<!'.g:autotype_syn_cmd_once
    let s:cs_bgn = '^'.g:autotype_syn_cmds_bgn.'$'
    let s:cs_end = '^'.g:autotype_syn_cmds_end.'$'
    let s:v_bgn = '!\@<!'.g:autotype_syn_var_bgn
    let s:v_end = '!\@<!'.g:autotype_syn_var_end

    " NOTE: include the \s in s:once to ignore input suffix whitespace
    let s:ptn_once = s:c_once .'\([^[:space:]]\+\)\(\s\|$\)'
    let s:ptn_cmd = s:c_bgn.'\(.\{-}\)'.s:c_end
    let s:ptn_var = s:v_bgn.'\(.\{-}\)'.s:v_end

    " Syntax usage
    let g:_autotype = {'syn':{}}
    let s:s = g:_autotype.syn
    let s:s.once = s:ptn_once
    let s:s.var_p = s:v_bgn.'\|'.s:v_end
    let s:s.var = s:v_bgn.'.\{-}'.s:v_end
    let s:s.cmd_p = s:c_bgn.'\|'.s:c_end
    let s:s.cmd = s:c_bgn.'.\{-}'.s:c_end
    let s:s.cmds_bgn = s:cs_bgn
    let s:s.cmds_end = s:cs_end

endfun "}}}

function! s:time() "{{{
    if has("reltime")
        return str2float(reltimestr(reltime()))
    else
        return localtime()
    endif
endfunction "}}}
fun! s:sleep(t) "{{{
    let t = str2nr(a:t)
    if t <= 0
        " let t = 1
        return
    endif
    exe "sl ".t."m"
endfun "}}}
fun! autotype#blink(str,...) "{{{
    let hl = a:0 ? get(a:1, 'hl', 'ModeMsg') : 'ModeMsg'
    let t = a:0 ? get(a:1, 't', g:autotype_sleep_echo)
                \ : g:autotype_sleep_echo
    for i in range(str2nr(t)/150)

        echohl  Normal
        echo '[AUTOTYPE]'
        echohl Normal
        exe "echon ".a:str
        redraw
        call s:sleep(100)

        exe "echohl ". hl
        echo '[AUTOTYPE]'
        echohl Normal
        exe "echon ".a:str
        redraw
        call s:sleep(100)
    endfor
endfun "}}}
fun! autotype#echo(str,...) "{{{
    let hl = a:0 ? get(a:1, 'hl', 'ModeMsg') : 'ModeMsg'
    let t = a:0 ? get(a:1, 't', g:autotype_sleep_echo) 
                \ : g:autotype_sleep_echo
    exe "echohl ". hl
    echo '[AUTOTYPE]'
    echohl Normal
    " NOTE: use exe with q-args. works like echo.
    exe "echon ".a:str
    redraw
    call s:sleep(t)
endfun "}}}
fun! s:echo(str,...) "{{{
    " Script use this version

    let hl = a:0 ? get(a:1, 'hl', 'ModeMsg') : 'ModeMsg'
    let t = a:0 ? get(a:1, 't', g:autotype_sleep_echo) 
                \ : g:autotype_sleep_echo

    echom '[AUTOTYPE]'.a:str
    redraw

    exe "echohl ". hl
    echo '[AUTOTYPE]'
    echohl Normal
    echon a:str
    redraw
    call s:sleep(t)
    
endfun "}}}
fun! autotype#normal(bang, str) "{{{
    " Wrap the string with "" for "\<C-W>" keys
    exe 'exe "norm'.a:bang.' '.a:str.'"'
endfun "}}}

fun! s:type(str, t) abort "{{{
    noa exe "norm! a". a:str
    
    " let @z =a:str
    " noa exe 'norm! "zp'
    "
    " let line = getline('.').a:str
    " call setline(line('.'), line)
    

    for au_ptn in split(g:autotype_cursor_aug, ',')
        " doau CursorMoved,CursorMovedI *.rst
        " doau CursorMoved,CursorMovedI <buffer>
        sil! noa exec "doau CursorMoved ". au_ptn
    endfor

    redraw
    call s:sleep(a:t)

endfun "}}}

fun! s:type_norm(line) "{{{
    " Type a normal line, by char or by word
    
    let line = a:line

    if g:autotype_skip_by == 'char'
        let chars = split(line, '.\zs')
        for char in chars
            call s:type(char, g:autotype_sleep_char)
        endfor
    elseif g:autotype_skip_by == 'word'
        let words = split(line, '[[:space:]]\+\zs')
        for word in words
            call s:type(word, g:autotype_sleep_word)
        endfor
    else 
        call s:type(line, g:autotype_sleep_line)
    endif
endfun "}}}

fun! s:type_cmd(cmd) "{{{
    let cmd = a:cmd   
    try
        exe cmd
    catch /^Vim\%((\a\+)\)\=:E/	" catch all Vim errors
        call s:echo("caught".v:exception,{'hl':'ErrorMsg'})
    endtry
    redraw
    call s:sleep(g:autotype_sleep_cmd)
endfun "}}}
fun! s:exe_cmds(cmds) "{{{
    " cmds is a list of lines
    " call writefile(a:cmds, s:tempfile)
    " exe "so " s:tempfile
    for cmd in a:cmds
        try
            exe cmd
        catch /^Vim\%((\a\+)\)\=:E/	" catch all Vim errors
            call s:echo("caught".v:exception,{'hl':'ErrorMsg'})
            break
        endtry
    endfor
    redraw
    call s:sleep(g:autotype_sleep_word)
endfun "}}}

fun! s:type_var(var) "{{{
    " Insert the variable in place.
    try
        exe "norm! a".string(eval(a:var))
    catch /^Vim\%((\a\+)\)\=:E/	" catch all Vim errors
	    call s:echo("caught".v:exception,{'hl':'ErrorMsg'})
    endtry
endfun "}}}

fun! s:sort_parts(a, b) "{{{
    let a = a:a 
    let b = a:b
    return a['idx']== b['idx'] ? 0 : a['idx'] > b['idx'] ? 1 : -1
endfun "}}}


fun! s:parse_line(line) "{{{
    " parse each line and return the parsing object.
    
    let parts = []
    let line = a:line
    " NOTE: Use statemachine?
    
    while line =~ s:ptn_once || line =~ s:ptn_cmd || line =~ s:ptn_var

        " " Make ^_ working
        if line =~ s:ptn_once
            " >>> let line = '34^_567 8910' 
            " >>> let _list = matchlist(line, s:c_once.'\(\w\+\)\%(\s\|$\)\ze')
            " >>> echo _list[1]
            " 567
            let _list = matchlist(line, s:ptn_once)
            let idx = match(line, s:ptn_once)
            let end = matchend(line, s:ptn_once)
            " replace the pattern to ignore further catch
            " NOTE: when ptn_once is at EOL, no ! is added at end
            "
            let line = substitute(line, s:ptn_once, '@@\1\2', '')
            call add(parts, 
                    \ {'type': 'cmd',
                    \ 'str': _list[0],
                    \ 'cmd': 'norm '._list[1], 
                    \ 'idx':idx,'end':end})
        endif
        
        if line =~  s:ptn_cmd
            let _list = matchlist(line, s:ptn_cmd)
            let idx = match(line, s:ptn_cmd)
            let end = matchend(line, s:ptn_cmd)
            let line = substitute(line, s:ptn_cmd, '@<\1>@', '')
            call add(parts,
                        \{'type': 'cmd',
                        \'str':_list[0],
                        \'cmd':_list[1],
                        \'idx':idx,'end':end})
        endif

        if line =~ s:ptn_var
            let _list = matchlist(line, s:ptn_var)
            let idx = match(line, s:ptn_var)
            let end = matchend(line, s:ptn_var)
            let line = substitute(line, s:ptn_var, '@<\1>@', '')
            call add(parts,
                        \{'type': 'var',
                        \'str':_list[0],
                        \'var': _list[1],
                        \'idx':idx,
                        \'end':end})
        endif
    endwhile

    let sorted_parts = sort(copy(parts), 's:sort_parts')

    let _len = len(sorted_parts)
    
    " add whole line if no parts found
    if _len == 0 && line != ''
        call add(parts,{'type':'norm', 'str':line,'idx':0})
    endif
    
    for i in range(_len)
        let bgn = sorted_parts[i]['idx']
        let end = sorted_parts[i]['end']

        if i == 0
            if bgn != 0
                call add(parts,
                            \{'type':'norm',
                            \'str': line[0:(bgn-1)],'idx': 0})
            endif
            if i == (_len - 1)
                if end != len(line)
                    call add(parts,
                                \{'type':'norm',
                                \'str': line[end :], 'idx': end })
                endif
            endif
            continue
        endif

        if i == (_len - 1)
            if end != len(line)
                call add(parts,
                            \{'type':'norm',
                            \'str': line[end :], 'idx': end })
            endif
            " NOTE: Do not continue as we need add the norm before it.
            " continue
        endif
        
        " The concated string must equal to origin one
        " >>> let line = '{% heelo %}{% eref %}'
        " >>> let p = s:parse_line(line)
        " >>> for x in p | echon x['str'] | endfor
        " >>> echo line
        " {% heelo %}{% eref %}
        " {% heelo %}{% eref %}
        "
        " The Second Type should be CMD
        " >>> echo p[1].type =~ 'cmd'
        " 1
            
        let last_end = sorted_parts[i-1]['end']
        " NOTE: The [:] in vim
        " the last_end is end+1, so use it
        " end contains the end char, so -1.
        if bgn - 1 >= last_end
            call add(parts,{'type':'norm',
                        \'str': line[ last_end : bgn-1],
                        \'idx': last_end ,'end': bgn-1})
        endif
        
    endfor
    
    
    return sort(parts, 's:sort_parts')

endfun "}}}

fun! s:type_line(line) "{{{
    let line = a:line
    let parts = s:parse_line(line)
    " call s:echo(string(parts))
    "
    " let e_t = s:time()
    " let time = printf("%.4f",(e_t-o_t))
    " echom 'parse' time

    for p in parts
        if p['type']  == 'cmd'
            call s:type_cmd(p['cmd'])
        endif
        if p['type']  == 'norm'
            call s:type_norm(p['str'])
        endif
        if p['type']  == 'var'
            call s:type_var(p['var'])
        endif
    endfor
    
endfun "}}}

fun! s:type_lines(lines) abort "{{{
    " lines are a list contain lines
    " Each line are split by " " and typed
    let cmds = []
    let cmd_mode = 0
    
    let end = len(a:lines)
    for i in range(end)
        let line = a:lines[i]

        " let o_t = s:time()

        " lines in ^[^[ are commands
        if line =~ s:cs_bgn
            let cmds = []
            let cmd_mode = 1
            continue
        endif
        if line =~ s:cs_end
            call s:exe_cmds(cmds)
            let cmd_mode = 0
            continue
        endif

        if cmd_mode == 1
            call add(cmds, line)
            continue
        endif
        

        " let t_t = s:time()
        " let time = printf("%.4f",(t_t-e_t))
        " echom 'type' time

        call s:type_line(line)

        if i != (end-1)
            call s:type("\r", g:autotype_sleep_word)
        endif

    endfor
endfun "}}}

fun! autotype#type_file(f) "{{{
    call autotype#init()

    let o_t = s:time()

    let f = a:f
    try
        call s:echo("Typing started.",
                    \{'hl': "MoreMsg", 't':0})

        if filereadable(f)
            call s:type_lines(readfile(f))
        else
            let files = split(globpath(s:fdirs, f),'\n')
            if empty(files)
                call s:echo("File Not Found, Stop", {'hl': "WarningMsg",'t':1})
                return
            elseif len(files) > 1
                let i = inputlist(['Choose autotyping source:']+files)
                if i == 0
                    call s:echo("No File Choosed, Stop", {'hl': "WarningMsg",'t':1})
                endif
                call s:type_lines(readfile(files[i-1]))
            else
                call s:type_lines(readfile(files[0]))
            endif
            
        endif
    catch /^Vim:Interrupt$/	" catch interrupts (CTRL-C)
        call s:echo("Typing Stopped by user.",
                    \{'hl': "WarningMsg",'t':0})
    endtry

    let time = printf("%.3f",(s:time() - o_t))
    call s:echo("Typing finished. Using " . time . " seconds.",
                    \{'hl': "MoreMsg", 't':0})
endfun "}}}

fun! autotype#type_line(line) "{{{
    call s:type_line(a:line)
endfun "}}}

call autotype#init()

let &cpo = s:save_cpo
unlet s:save_cpo
