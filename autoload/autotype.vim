let s:save_cpo = &cpo
set cpo&vim

" OPTS: "{{{
let s:tempfile = tempname()
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
fun! s:init_speed() "{{{
    if g:autotype_speed == 'mankind'
        let s:speed = 30
    elseif g:autotype_speed == 'turtle'
        let s:speed = 2
    elseif g:autotype_speed == 'swift'
        let s:speed = 400
    elseif g:autotype_speed == 'lighting'
        let s:speed = 30000
    else
        let s:speed = str2nr(g:autotype_speed)
    endif
    let s:speed = s:speed <= 0 ? 1 : s:speed
    let spd = s:speed

    if spd <= 400 
        call s:set("g:autotype_skip_by", 'char')
    elseif  spd <= 1000
        call s:set("g:autotype_skip_by", 'word')
    else
        call s:set("g:autotype_skip_by", 'line')
    endif

    " Do some math.
    "
    " Char sleep_ time is 1000/spd
    " Word is 5 time of it
    " Line is 4 Time of word
    " CMD is 4 Time of Line
    " ECHO is 2 Time of Command

    " TODO 
    " tune speed for each level
    let speed_opt = [
                \ ["g:autotype_sleep_word", 2500/(spd+5)],
                \ ["g:autotype_sleep_line", 8000/(spd+9)],
                \ ["g:autotype_sleep_char", 700/spd],
                \ ["g:autotype_sleep_cmd",  (30000/(spd+25))],
                \ ["g:autotype_sleep_echo", (75000/(spd+20))],
                \ ]

    " call extend(opts, speed_opt)
    for [opt, val] in speed_opt
        call s:set(opt, val)
        unlet val
    endfor
    " echom string(speed_opt)
endfun "}}}
fun! autotype#init() "{{{
    let def_list = [
        \ ["g:autotype_speed", '30'],
        \ ["g:autotype_syntax_type", 'jinja'],
        \ ["g:autotype_cursor_aug", '*.rst,<buffer>'],
        \ ["g:autotype_file_directory", ''],
        \ ["g:autotype_global_context", {}],
        \ ["g:autotype_debug", 0],
        \ ]


    for [opt, val] in def_list
        call s:default(opt, val)
        unlet val
    endfor

    let opts = []

    " Basic:
    " Turtle/ManKind/Swift/Lighting
    
    call s:init_speed()


    if g:autotype_syntax_type == 'jinja'
        let syn_opt = [
            \ ["g:autotype_syn_cmd_bgn",  '{%'],
            \ ["g:autotype_syn_cmd_end",  '%}'],
            \ ["g:autotype_syn_cmt_bgn",  '{#'],
            \ ["g:autotype_syn_cmt_end",  '#}'],
            \ ["g:autotype_syn_var_bgn",  '{{'],
            \ ["g:autotype_syn_var_end",  '}}'],
            \ ["g:autotype_syn_cmds_bgn", '{@'],
            \ ["g:autotype_syn_cmds_end", '@}'],
            \ ["g:autotype_syn_cmd_once", '^_'],
            \ ] 
    else
        let syn_opt = [
            \ ["g:autotype_syn_cmd_bgn", '\^\['],
            \ ["g:autotype_syn_cmd_end", '\^\]'],
            \ ["g:autotype_syn_cmt_bgn",  '\^<'],
            \ ["g:autotype_syn_cmt_end",  '\^>'],
            \ ["g:autotype_syn_var_bgn", '\^[{]'],
            \ ["g:autotype_syn_var_end", '\^[}]'],
            \ ["g:autotype_syn_cmds_bgn", '\^\[\^\['],
            \ ["g:autotype_syn_cmds_end", '\^\]\^\]'],
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
    let s:c_bgn = '!\@<!'.g:autotype_syn_cmd_bgn.'\(-\=\)'
    let s:c_end = '!\@<!\(-\=\)'. g:autotype_syn_cmd_end
    let s:c_once = '!\@<!'.g:autotype_syn_cmd_once
    let s:cs_bgn = '^\s*'.g:autotype_syn_cmds_bgn.'\s*$'
    let s:cs_end = '^\s*'.g:autotype_syn_cmds_end.'\s*$'
    let s:v_bgn = '!\@<!'.g:autotype_syn_var_bgn
    let s:v_end = '!\@<!'.g:autotype_syn_var_end
    let s:cm_bgn = '^\s*!\@<!'.g:autotype_syn_cmt_bgn
    let s:cm_end = '!\@<!'. g:autotype_syn_cmt_end.'\s*$'

    " NOTE: include the \s in s:once to ignore input suffix whitespace
    let s:ptn_once = s:c_once .'\([^[:space:]]\+\)\(\s\|$\)'
    let s:ptn_cmd = s:c_bgn.'\(.\{-}\)'.s:c_end
    let s:ptn_var = s:v_bgn.'\(.\{-}\)'.s:v_end
    " The pattern for strip '\r'
    let s:ptn_rstrip = '-'.s:end.'\s*$'
    let s:ptn_lstrip = '^\s*'.s:bgn.'-'

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
    let s:s.cmt_bgn = s:cm_bgn
    let s:s.cmt_end = s:cm_end

endfun "}}}
"}}}
" MAIN: "{{{
fun! s:append(bang, str, ...) abort "{{{

    if a:bang == '!'
        noa exe "norm! A". a:str
    else
        noa exe "norm! a". a:str
    endif

    for au_ptn in split(g:autotype_cursor_aug, ',')
        sil! noa exec "doau CursorMoved ". au_ptn
    endfor

    redraw

    call s:sleep(a:0 ? a:1 : g:autotype_sleep_char )
endfun "}}}
fun! s:insert(bang, str, ...) abort "{{{

    if a:bang == '!'
        noa exe "norm! I". a:str
    else
        noa exe "norm! i". a:str
    endif
    
    for au_ptn in split(g:autotype_cursor_aug, ',')
        sil! noa exec "doau CursorMoved ". au_ptn
    endfor

    redraw

    call s:sleep(a:0 ? a:1 : g:autotype_sleep_char )
endfun "}}}

fun! s:type_norm(line, idx) "{{{
    " Type a normal line, by char or by word
    
    " NOTE: Append Or Insert?
    " When typing in a line already has charactes.
    " The append will one char after the first char as typing 'a'
    "
    " But it's not the default behavior as typing in vim insert mode
    "
    " So we must insert the char if it's the first char of line.
    " We can get this by it's idx.

    let line = a:line
    let idx = a:idx
    " XXX 
    " Still Met some issues with strip tags
    if s:_lstrip == 1
        let idx = 1
        let line = substitute(line, '^\s*', '','')
        let s:_lstrip = 0
    endif

    if g:autotype_skip_by == 'char'
        let chars = split(line, '.\zs')
        for char in chars
            if idx == 0
                call s:insert('', char, g:autotype_sleep_char)
                let idx = 1
            else
                call s:append('', char, g:autotype_sleep_char)
            endif
        endfor
    elseif g:autotype_skip_by == 'word'
        let words = split(line, '[[:space:]]\+\zs')
        for word in words
            if idx == 0
                call s:insert('', word, g:autotype_sleep_char)
                let idx = 1
            else
                call s:append('', word, g:autotype_sleep_word)
            endif
        endfor
    else 
        if idx == 0
            call s:insert('', line, g:autotype_sleep_line)
            let idx = 1
        else
            call s:append('', line, g:autotype_sleep_line)
        endif
    endif
endfun "}}}

fun! s:type_cmd(cmd) "{{{
    call extend(l:, s:_ctx)
    try
        exe a:cmd
    catch /^Vim\%((\a\+)\)\=:E\|^AUTOTYPE:/	" catch all Vim errors and AutoType errors
        call s:echo('!', 0, v:exception)
        call s:echo('!', 0 ,"from line ".s:_ctx.__lnum__.": ".s:_ctx.__line__)
        if g:autotype_debug == 1 | throw v:exception | endif
    endtry
    call extend(s:_ctx , l:)
    redraw
    call s:sleep(g:autotype_sleep_cmd)
endfun "}}}
fun! s:exe_cmds(cmds) "{{{
    " cmds is a list of lines
    call writefile([
                \'fun! s:_temp()',
                \'call extend(l:, g:_autotype_context)']
                \+ a:cmds +
                \['call extend(g:_autotype_context,l:)',
                \'endfun',
                \'call s:_temp()'], s:tempfile)
    try
        exe "so " s:tempfile
    catch /^Vim\%((\a\+)\)\=:E\|^AUTOTYPE:/	" catch all Vim errors and AutoType errors
        call s:echo('!', 0, v:exception)
        call s:echo('!', 0 ,"from line ".s:_ctx.__lnum__.": ".s:_ctx.__line__)
        if g:autotype_debug == 1 | throw v:exception | endif
        " break
    endtry
    
    " NOTE: we can not :execute a 'for' or 'while'
    " call extend(l:, s:_ctx)
    " try
    "     for cmd in a:cmds
    "         " echom cmd
    "         exe cmd
    "     endfor
    " catch /^Vim\%((\a\+)\)\=:E/	" catch all Vim errors
    "     call s:echo("caught".v:exception,{'hl':'ErrorMsg'})
    "     break
    " endtry
    " call extend(s:_ctx , l:)
   
    redraw
    call s:sleep(g:autotype_sleep_word)
endfun "}}}

fun! s:type_var(var) "{{{
    " Insert the variable in place.
    call extend(l:, s:_ctx)
    try
        let v = eval(a:var)
        if type(v) == type([]) || type(v) == type({})
            exe "norm! a".string(v)
        else
            exe "norm! a".v
        endif
        unlet v
    catch /^Vim\%((\a\+)\)\=:E\|^AUTOTYPE:/	" catch all Vim errors and AutoType errors
        call s:echo('!', 0, v:exception)
        call s:echo('!', 0 ,"from line ".s:_ctx.__lnum__.": ".s:_ctx.__line__)
        if g:autotype_debug == 1 
            throw v:exception 
        endif
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
            let trim_cmd = substitute(_list[1],'^\s*\|\s*$','','g')
            let line = substitute(line, s:ptn_once, '@@\1\2', '')
            call add(parts, 
                    \ {'type': 'cmd',
                    \ 'str': _list[0],
                    \ 'cmd': 'norm '.trim_cmd,
                    \ 'idx':idx,'end':end})
        endif
        
        if line =~  s:ptn_cmd
            let _list = matchlist(line, s:ptn_cmd)
            let idx = match(line, s:ptn_cmd)
            let end = matchend(line, s:ptn_cmd)
            let line = substitute(line, s:ptn_cmd, '@<\1\2\3>@', '')
            let trim_cmd = substitute(_list[2],'^\s*\|\s*$','','g')
            call add(parts,
                        \{'type': 'cmd',
                        \'str':_list[0],
                        \'cmd':trim_cmd,
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
        " >>> echo p[1].type == 'cmd'
        " 1
        "
        
        " Assume This ptn will consume the whole line.
        " >>> let line = '{%- heelo %}'
        " >>> let p = s:parse_line(line)
        " >>> echo len(p) == 1
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
    " return 0 if this line typed nothing
    let line = a:line
    let parts = s:parse_line(line)
    let _t = 0
    " call s:echo(string(parts))

    for p in parts
        if p['type']  == 'cmd'
            call s:type_cmd(p['cmd'])
        endif
        if p['type']  == 'norm'
            call s:type_norm(p['str'], p.idx)
            let _t = 1
        endif
        if p['type']  == 'var'
            call s:type_var(p['var'])
        endif
    endfor
    return _t
    
endfun "}}}

fun! s:type_lines(lines) abort "{{{
    " lines are a list contain lines
    " Each line are split by " " and typed
    let cmds = []
    let cmd_mode = 0
    let cmt_mode = 0

    
    let end = len(a:lines) - 1
    let s:_lstrip = 0
    for i in range(end+1)
        let line = a:lines[i]
        let s:_ctx.__line__ = line
        let s:_ctx.__lnum__ = (i+1)


        " lines in ^[^[ are commands
        if line =~ s:cs_bgn && cmd_mode == 0 && cmt_mode != 1
            let cmds = []
            let cmd_mode = 1
            continue
        endif

        if line =~ s:cs_end && cmd_mode == 1
            call s:exe_cmds(cmds)
            let cmd_mode = 0
            continue
        endif

        if cmd_mode == 1
            call add(cmds, line)
            continue
        endif

        " lines in {# are comments, Just escape them
        if line =~ s:cm_bgn && cmt_mode == 0 && cmd_mode != 1
            " A one line comment
            if line =~ s:cm_end
                continue
            endif
            let cmt_mode = 1
            continue
        endif

        if line =~ s:cm_end && cmt_mode == 1
            let cmt_mode = 0
            continue
        endif

        if cmt_mode == 1
            continue
        endif


        let _typed = s:type_line(line)

        " The New Line Control
        " EOF_LINE: end line which is not in inlcuded file will not return '\r'
        " LSTRIP: line starts with '{%-' pattern will make last line not return '\r'
        " RSTRIP: line end with '-%}' pattern will not return '\r'
        if ( i == end  && s:_ctx.__is_included__ != 1 )
                \ || line =~ s:ptn_rstrip
                \ || (i != end && a:lines[i+1] =~ s:ptn_lstrip )

            " if lstrip , then next line should append 
            " instead of insert
            if i != end && a:lines[i+1] =~ s:ptn_lstrip
                let s:_lstrip = 1
            endif
            continue
        else
            " Warning: APPEND or append
            " Append '\r' to current cursor postition
            " This will lead to miskate input with movements.
            " See Syntax_Overview_ in README
            
            " NOTE:  append or insert
            " To act as Human input,
            " A line typed nothing we must INSERT the '\r'
            " Otherwise it will after one existing char on current line.
            "
            if _typed
                call s:append('', "\r", g:autotype_sleep_word)
            else
                if s:_lstrip == 1
                    call s:append('', "\r", g:autotype_sleep_word)
                    let s:_lstrip = 0
                else
                    call s:insert('', "\r", g:autotype_sleep_word)
                endif
            endif

        endif

    endfor
endfun "}}}
"}}}
" MISC:{{{
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
fun! s:echo(bang, count, arg) "{{{
    " @arg
    " if arg is a dict,
    " set hl to arg.hl
    " then echo the arg.echo
    " if arg is a list,
    " loop list item and echo
    " if arg is a str
    " echo it
    "
    " @bang
    " set hl to 'ErrorMsg' if is '!'
    "
    " @count
    " when it's 0, then sleep with echo time
    " when it's -1, then don't sleep
    " else sleep with the count seconds
    
    if a:bang == '!'
        let hl = 'ErrorMsg'
    else
        let hl = 'ModeMsg'
    endif
    let ct = a:count==-1 ? 0 : a:count==0 ? g:autotype_sleep_echo : (1000*a:count)

    if type(a:arg) == type({})
        let hl = get(a:arg,'hl', hl)
        let arg = get(a:arg, 'arg', '')
    else
        let arg = a:arg
    endif

    if type(arg) ==type([])
        let strs = arg
    else
        let strs= [arg]
    endif

    for str in strs
        exe "echohl ". hl | echom '[AUTOTYPE] '.str | redraw
        echo '[AutoType]' | echohl Normal | echon ' '.str
        redraw
        call s:sleep(ct)
    endfor
endfun "}}}
fun! s:blink(bang, count, arg,...) "{{{
    " blinking version of autotype#echo
    
    if a:bang == '!'
        let hl = 'ErrorMsg'
    else
        let hl = 'ModeMsg'
    endif
    let ct = a:count==-1 ? 0 : a:count==0 ? g:autotype_sleep_echo : (1000*a:count)
    let lp = str2nr(ct)/160
    let bt = 100

    if type(a:arg) == type({})
        let hl = get(a:arg,'hl', hl)
        let arg = get(a:arg, 'arg', '')
    else
        let arg = a:arg
    endif

    if type(arg) ==type([])
        let strs = arg
    else
        let strs= [arg]
    endif

    for str in strs
        exe "echohl ". hl | echom '[AUTOTYPE] '.str | redraw
        for i in range(lp)
            echohl Normal | echo '[AUTOTYPE]'
            echon ' '.str | redraw
            call s:sleep(bt)

            exe "echohl ". hl | echo '[AUTOTYPE]'
            echohl Normal | echon ' '.str | redraw
            call s:sleep(bt)
        endfor
    endfor
endfun "}}}
"}}}
" PORT: "{{{
fun! autotype#type_file(f) "{{{

    call autotype#init()
    let t = s:time()
    let f = a:f

    unlet! g:_autotype_context
    let g:_autotype_context = extend({'__arg__':f,
                \'__file__': expand('%:p'),
                \'__speed__': s:speed,
                \'__include__': [],
                \'__time__': localtime()}, g:autotype_global_context)
    let s:_ctx = g:_autotype_context



    try
        if !filereadable(f)
            " Try to find an autotype file:
            " with autotype extension and under  &rtp

            if f == '' 
                let f = '*.autotype'
            elseif fnamemodify(f, ':e') == ''
                let f = f.'.autotype'
            endif

            let files = split(globpath(g:autotype_file_directory, f),'\n')
            let files += split(globpath(&rtp, 'autotype/'.f),'\n')

            if empty(files)
                call s:echo('', -1,
                        \{'hl': "PreProc",
                        \'arg': "File Not Found."})
                return
            elseif len(files) > 1
                let i = inputlist(['[AutoType] Choose an autotyping source:']+files)
                if i == 0
                    call s:echo('', -1 ,  
                        \{'hl': "WarningMsg",
                        \'arg': "No File Chosen."})
                    return
                else
                    let f = files[i-1]
                endif
            else
                let f = files[0]
            endif
        endif
        let f = fnamemodify(f, ':p')
        let s:_ctx.__source__ = f
        let s:_ctx.__sourcing__ = f
        let s:_ctx.__is_included__ = 0
        call add(s:_ctx.__include__, f)
        call s:echo("", -1 , "Typing Start")
        call s:type_lines(readfile(f))

    catch /^Vim:Interrupt$/	" catch interrupts (CTRL-C)
        call s:echo("", -1,
                    \{'arg': "Typing Stopped by user.",
                    \'hl': "WarningMsg"})
    endtry

    let time = printf("%.3f",(s:time() - t))
    let s:_ctx.__exec_time__ = time
    call s:echo("",-1,
                \{"arg": "Typing finished. Using ". time ." seconds.",
                \'hl': "MoreMsg"})

    unlet! g:autotype_last_context
    let g:autotype_last_context = copy(s:_ctx)
    unlet! s:_ctx
endfun "}}}

fun! autotype#include(f) "{{{

    " INCLUDE Tag
    if !exists("s:_ctx")
        throw 'AUTOTYPE: INCLUDE can only be used in Tag/Block.'
    endif
    let f = a:f

    if !filereadable(f)
        if f == '' 
            let f = '*.autotype'
        elseif fnamemodify(f,':e') == ''
            let f = f.'.autotype'
        endif

        let files = split(globpath(g:autotype_file_directory, f),'\n')
        let files += split(globpath(&rtp, 'autotype/'.f),'\n')

        if empty(files)
            call s:echo('', -1, "File:".f." Not Found")
            return
        else
            let f = files[0]
        endif
    endif

    if index(s:_ctx.__include__, f) != -1
        throw 'AUTOTYPE: Recursive include.'
    endif
    call s:echo('',0 ,"INCLUDING:".f )
    call add(s:_ctx.__include__, f)
    let _s = s:_ctx.__sourcing__
    let s:_ctx.__sourcing__ = f
    let s:_ctx.__is_included__ = 1
    call s:type_lines(readfile(f))
    let s:_ctx.__is_included__ = 0
    let s:_ctx.__sourcing__ = _s

endfun "}}}
fun! autotype#append(bang, line) "{{{
    " NOTE: Use line as Constant-String.
    " Wrap a:bang, and a:line with '"'
    " Then "\r" will be expanded to special chars 'Enter'
    
    exe 'call s:append("'.a:bang.'","'.a:line.'")'
endfun "}}}
fun! autotype#insert(bang, line) "{{{
    exe 'call s:insert("'.a:bang.'","'.a:line.'")'
endfun "}}}

fun! autotype#echo(bang, count, arg) "{{{
    call s:echo(a:bang, a:count, a:arg)
endfun "}}}
fun! autotype#blink(bang, count, arg) "{{{
    call s:blink(a:bang, a:count, a:arg)
endfun "}}}
fun! autotype#normal(bang, str) "{{{
    " Wrap the string with "" 
    " Act as ``exe "norm \<c-w>\<c-w>"``
    
    exe 'exe "norm'.a:bang.' '.a:str.'"'
endfun "}}}
fun! autotype#atp_spd(str) "{{{
    if a:str != ''
        let g:autotype_speed = a:str
    else
        let _l = split('turtle,mankind,swift,lighting', ',')
        let _k = split('2,30,400,30000', ',')
        let _n = map(range(len(_l)), 'printf(" %-12s",_l[v:val])."| "._k[v:val]')
        let k = inputlist(['[AutoType] Choose a Speed, Current:'.g:autotype_speed.'|'.s:speed]+_n)
        if k != 0
            let g:autotype_speed = _l[k-1]
        else
            call s:echo('',-1, 'Abort Speed Setup.')
            return
        endif
    endif
    call s:init_speed()
    call s:echo('', -1, 'Speed Set to "'.g:autotype_speed.'"('.s:speed.')')
endfun "}}}
"}}}

call autotype#init()

let &cpo = s:save_cpo
unlet s:save_cpo
