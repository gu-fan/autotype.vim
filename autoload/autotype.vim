" vim:fdm=marker:
let s:save_cpo = &cpo
set cpo&vim

" OPTS: "{{{
" Import
function! autotype#get_vital() "{{{
  if !exists('s:V')
    let s:V = vital#of('autotype')
  endif
  return s:V
endfunction"}}}
function! s:get_json() "{{{
  if !exists('s:JSON')
    let s:JSON = autotype#get_vital().import('Web.JSON')
  endif
  return s:JSON
endfunction"}}}
function! s:json_decode(...) "{{{
  return call(s:get_json().decode, a:000)
endfunction"}}}
function! s:json_encode(...) "{{{
  return call(s:get_json().encode, a:000)
endfunction"}}}

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
        let s:speed = 120
    elseif g:autotype_speed == 'storm'
        let s:speed = 600
    elseif g:autotype_speed == 'lighting'
        let s:speed = 3000
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
        \ ["g:autotype_moveback", 1],
        \ ["g:autotype_default_char", 'AUTOTYPE'],
        \ ["g:autotype_default_hl", 'ModeMsg'],
        \ ["g:autotype_code_list", 'vim,sh,python,python3,ruby,perl,lua,javascript'],
        \ ["g:autotype_code_runner", {}],
        \ ["g:autotype_code_cmd", {}],
        \ ["g:autotype_code_syntax", {'python3': 'python'}],
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
            \ ["g:autotype_syn_code_bgn", '{@'],
            \ ["g:autotype_syn_code_end", '@}'],
            \ ] 
    else
        let syn_opt = [
            \ ["g:autotype_syn_cmd_bgn", '\^\['],
            \ ["g:autotype_syn_cmd_end", '\^\]'],
            \ ["g:autotype_syn_cmt_bgn",  '\^<'],
            \ ["g:autotype_syn_cmt_end",  '\^>'],
            \ ["g:autotype_syn_var_bgn", '\^[{]'],
            \ ["g:autotype_syn_var_end", '\^[}]'],
            \ ["g:autotype_syn_code_bgn", '\^\[\^\['],
            \ ["g:autotype_syn_code_end", '\^\]\^\]'],
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
    " let s:c_once = '!\@<!'.g:autotype_syn_cmd_once
    let s:v_bgn = '!\@<!'.g:autotype_syn_var_bgn
    let s:v_end = '!\@<!'.g:autotype_syn_var_end
    let s:cm_bgn = '^\s*!\@<!'.g:autotype_syn_cmt_bgn
    let s:cm_end = '!\@<!'. g:autotype_syn_cmt_end.'\s*$'


    " NOTE: include the \s in s:once to ignore input suffix whitespace
    " let s:ptn_once = s:c_once .'\([^[:space:]]\+\)\(\s\|$\)'
    let s:ptn_cmd = s:c_bgn.'\(.\{-}\)'.s:c_end
    let s:ptn_var = s:v_bgn.'\(.\{-}\)'.s:v_end
    " The pattern for strip '\r'
    let s:ptn_rstrip = '-'.s:end.'\s*$'
    let s:ptn_lstrip = '^\s*'.s:bgn.'-'

    " Syntax usage
    let g:_autotype = {'syn':{'syntax':{} }}
    let s:s = g:_autotype.syn
    " let s:s.once = s:ptn_once
    let s:s.var_p = s:v_bgn.'\|'.s:v_end
    let s:s.var = s:v_bgn.'.\{-}'.s:v_end
    let s:s.cmd_p = s:c_bgn.'\|'.s:c_end
    let s:s.cmd = s:c_bgn.'.\{-}'.s:c_end
    let s:s.cmt_bgn = s:cm_bgn
    let s:s.cmt_end = s:cm_end

    let s:code_list = split(g:autotype_code_list, ',')
                      
    let s:code_bgn = '^\s*'.g:autotype_syn_code_bgn
    let s:code_end = '^\s*'.g:autotype_syn_code_end.'\s*$'
    let s:code_vim = s:code_bgn. '\s*$'
    let s:s.code = {'vim': s:code_vim}
    let s:s.code_end = s:code_end
    for code in s:code_list
        let s:code_{code} = '^\s*'.g:autotype_syn_code_bgn
                                \.'\s\+\c'.code.'\s*$'
        let s:s.code[code] = s:code_{code}
        if exists("g:autotype_code_syntax['".code."']")
            let s:s.syntax[code] = g:autotype_code_syntax[code]
        else
            let s:s.syntax[code] = code
        endif
    endfor

    fun! s:get_tempfile() "{{{
        if !exists("s:tempfile")
            let s:tempfile = tempname()
        endif
        return s:tempfile
    endfun "}}}
    call s:get_tempfile()
    let s:temp_log = s:tempfile.".log"
    let s:temp_err =  s:tempfile.".err"
    let s:temp_return =  s:tempfile.".return"
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
        sil! exec "doau CursorMoved ". au_ptn
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
        sil! exec "doau CursorMoved ". au_ptn
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
    
    " We should reset them all when met one.
    if s:_lstrip == 1 || s:_rstrip == 1
        let idx = 1
        let line = substitute(line, '^\s*', '','')
        let s:_lstrip = 0
        let s:_rstrip = 0
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
            redraw
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
        if g:autotype_moveback
            norm! G$
        endif
    catch /^Vim\%((\a\+)\)\=:E\|^AUTOTYPE:/	" catch all Vim errors and AutoType errors
        call s:echo('!', 0, v:exception)
        call s:echo('!', 0 ,"from line ".s:_ctx.__lnum__.": ".s:_ctx.__line__)
        if g:autotype_debug == 1 | throw v:exception | endif
    endtry
    call extend(s:_ctx , l:)
    redraw
    call s:sleep(g:autotype_sleep_cmd)
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
    
    while line =~ s:ptn_cmd || line =~ s:ptn_var

        " " " Make ^_ working
        " if line =~ s:ptn_once
        "     " >>> let line = '34^_567 8910' 
        "     " >>> let _list = matchlist(line, s:c_once.'\(\w\+\)\%(\s\|$\)\ze')
        "     " >>> echo _list[1]
        "     " 567
        "     let _list = matchlist(line, s:ptn_once)
        "     let idx = match(line, s:ptn_once)
        "     let end = matchend(line, s:ptn_once)
        "     " replace the pattern to ignore further catch
        "     " NOTE: when ptn_once is at EOL, no ! is added at end
        "     let trim_cmd = substitute(_list[1],'^\s*\|\s*$','','g')
        "     let line = substitute(line, s:ptn_once, '@@\1\2', '')
        "     call add(parts, 
        "             \ {'type': 'cmd',
        "             \ 'str': _list[0],
        "             \ 'cmd': 'norm '.trim_cmd,
        "             \ 'idx':idx,'end':end})
        " endif
        
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


    for p in parts
        if p['type']  == 'cmd'
            " XXX Infact , check typed in cmd are 
            " not predictable.
            " So this will make Typing works wrong sometimes.
            call s:type_cmd(p['cmd'])
        endif
        if p['type']  == 'norm'
            let str = substitute(p['str'], '\s', '_','g')
            " let str = p['str']
            call s:type_norm(p['str'], p.idx)
            " call s:type_norm(str, p.idx)
            let _t = 1
        endif
        if p['type']  == 'var'
            call s:type_var(p['var'])
            let _t = 1
        endif
    endfor
    return _t
    
endfun "}}}

fun! s:type_lines(lines) abort "{{{
    " lines are a list contain lines
    " Each line are split by " " and typed
    let code_lines = []
    let code_mode = 0
    let cmt_mode = 0

    
    let end = len(a:lines) - 1
    for i in range(end+1)
        let line = a:lines[i]
        let s:_ctx.__line__ = line
        let s:_ctx.__lnum__ = (i+1)


        " Code Block
        if line =~ s:code_bgn && code_mode == 0 && cmt_mode != 1
            let code_type = ''
            for [code, ptn] in items(s:s['code'])
                if line =~ ptn
                    let code_type = code
                    continue
                endif
            endfor
            if code_type == ''
                throw 'AUTOTYPE: Unknow Code Block Tag:line '.(i+1)
            endif
            let code_lines = []
            let cmd_indent = matchstr(line, '^\s*')
            let code_mode = 1
            continue
        endif
        
        if  line =~ s:code_end && code_mode == 1
            call s:run_code(code_lines, code_type)
            let code_mode = 0
            continue
        endif

        if code_mode == 1
            " remove indent for python block
            let line = substitute(line, '^'.cmd_indent, '','')
            call add(code_lines, line)
            continue
        endif

        " Comments Block
        if line =~ s:cm_bgn && cmt_mode == 0 && code_mode != 1
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
        
        if  i == end  && s:_ctx.__is_included__ != 1
            continue
        elseif line =~ s:ptn_rstrip
            " If current line is rstrip, 
            " then next line should append 
            " instead of insert
            let s:_rstrip = 1
            continue
        elseif i != end && a:lines[i+1] =~ s:ptn_lstrip
            " if next line is lstrip
            " then next line should append 
            " instead of insert
            let s:_lstrip = 1
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
            " 123456789
            " aaaaIaaaa
            " 
            " As we are simulating Insert in Normal mode.
            "
            "
            if _typed
                call s:append('', "\r", g:autotype_sleep_word)
            else
                " NOT _typed. Then this is an empty line
                " with '\r', so rstrip and lstrip should 
                " considered
                " And we will reset them to 0 
                " if consumed one
                if s:_lstrip == 1 || s:_rstrip == 1
                    call s:append('', "\r", g:autotype_sleep_word)
                    let s:_lstrip = 0
                    let s:_rstrip = 0
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
fun! s:get_echo_args(bang, count, arg) "{{{
    if a:bang == '!'
        let hl = 'ErrorMsg'
    else
        let hl = g:autotype_default_hl
    endif
    let ct = a:count==-1 ? 0 : a:count==0 ? g:autotype_sleep_echo : (1000*a:count)

    if type(a:arg) == type({})
        let hl = get(a:arg,'hl', g:autotype_default_hl)
        let arg = get(a:arg, 'arg', '')
        let char = get(a:arg, 'char', g:autotype_default_char)
    else
        let arg = a:arg
        let char = 'AUTOTYPE'
    endif

    if type(arg) ==type([])
        let strs = arg
    else
        let strs= [arg]
    endif
    return [hl, ct, char, strs]
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
    

    let [hl, ct, char, strs] = s:get_echo_args(a:bang, 
                                \a:count, a:arg)
    for str in strs
        exe "echohl ". hl | echom '['.char.'] '.str | redraw
        echo '['.char.']' | echohl Normal | echon ' '.str
        redraw
        call s:sleep(ct)
    endfor
endfun "}}}
fun! s:blink(bang, count, arg,...) "{{{
    " blinking version of s:echo
    
    let [hl, ct, char, strs] = s:get_echo_args(a:bang, 
                                \a:count, a:arg)

    let lp = str2nr(ct)/160
    if lp < 2
        let lp = 2
        let bt = 50
    else
        let bt = 100
    endif

    for str in strs
        exe "echohl ". hl | echom '['.char.'] '.str | redraw
        for i in range(lp)
            echohl Normal | echo '['.char.']'
            echon ' '.str | redraw
            call s:sleep(bt)

            exe "echohl ". hl | echo '['.char.']'
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
        let s:_lstrip = 0
        let s:_rstrip = 0
        call s:type_lines(readfile(f))

    catch /^\(Vim\|AUTOTYPE\):Interrupt$/	
        " catch interrupts (CTRL-C)
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

fun! s:run_code(lines, type) "{{{
    try
        if index(s:code_list, a:type) != -1
            let ctx = autotype#{a:type}_lines(a:lines, s:_ctx)
            if g:autotype_moveback
                norm! G$
            endif
            if type(ctx) == type({})
                call extend(s:_ctx, ctx)
            endif
        else
            throw 'AUTOTYPE: Unknow Code Type For Execute'
        endif
    catch /^Vim:Interrupt$/	" catch interrupts (CTRL-C)
        throw 'AUTOTYPE:Interrupt'
    catch /.*/
        call s:echo('!', -1, v:exception)
        " call s:echo('!', 0 ,v:throwpoint)
        call s:echo('!', -1 ,"from ".s:_ctx.__sourcing__." line ".s:_ctx.__lnum__.": ".s:_ctx.__line__)
        if g:autotype_debug == 1 | throw v:exception | endif
    endtry
   
    redraw
    call s:sleep(g:autotype_sleep_word)
endfun "}}}
fun! autotype#vim_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['vim']")
        return g:autotype_code_runner.vim(a:lines, a:context)
    else
        if exists("g:autotype_code_cmd['vim']")
            let cmd = g:autotype_code_cmd['vim']
            call writefile([a:lines , s:tempfile)
            exe cmd . "  " . s:tempfile
        else
            let g:_autotype._context = a:context
            " hook 'l:' to local context
            call writefile([
                        \'fun! s:_temp()',
                        \'call extend(l:, g:_autotype._context)']
                        \+ a:lines +
                        \['call extend(g:_autotype._context,l:)',
                        \'endfun',
                        \'call s:_temp()'], s:tempfile)
            exe "so ".s:tempfile
            return g:_autotype._context
        endif
    endif
endfun "}}}
fun! autotype#shell_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['shell']")
        return g:autotype_code_runner.shell(a:lines, a:context)
    else
        if exists("g:autotype_code_cmd['shell']")
            let cmd = g:autotype_code_cmd['shell']
            call writefile( a:lines , s:tempfile)
            exe cmd . "  " . s:tempfile
        else
            for line in a:lines
                exe "!".line
            endfor
        else
            throw 'AUTOTYPE: No shell interpreter found'
        endif
        return 0
    endif
endfun "}}}
fun! autotype#python_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['python']")
        return g:autotype_code_runner.python(a:lines, a:context)
    else
        let l:context = a:context
        if exists("g:autotype_code_cmd['python']")
            let cmd = g:autotype_code_cmd['python']
            call writefile([a:lines , s:tempfile)
            exe cmd . "  " . s:tempfile
        elseif has('python')
            " Hook to local context.
            call writefile([
                        \'def _temp():',
                        \'  import vim',
                        \'  _ = vim.bindeval("l:context")']
                        \+ map(a:lines, '"  ".v:val') 
                        \+['_temp()'], s:tempfile)
            exe 'pyfile ' s:tempfile
        else
            throw 'AUTOTYPE: No python interpreter found'
        endif
        return l:context
    endif
endfun "}}}
fun! autotype#python3_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['python3']")
        return g:autotype_code_runner.python3(a:lines, a:context)
    else
        let l:context = a:context

        if exists("g:autotype_code_cmd['python3']")
            let cmd = g:autotype_code_cmd['python3']
            call writefile([a:lines , s:tempfile)
            exe cmd . "  " . s:tempfile
        elseif has('python3')
            call writefile([
                        \'def _temp():',
                        \'  import vim',
                        \'  _ = vim.bindeval("l:context")']
                        \+ map(a:lines, '"  ".v:val') 
                        \+['_temp()'], s:tempfile)
            exe 'py3file ' s:tempfile
        else
            throw 'AUTOTYPE: No python3 interpreter found'
        endif
        return l:context
    endif
endfun "}}}
fun! autotype#ruby_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['ruby']")
        return g:autotype_code_runner.ruby(a:lines, a:context)
    else
        if exists("g:autotype_code_cmd['ruby']")
            let cmd = g:autotype_code_cmd['ruby']
        elseif has('ruby')
            let cmd = 'rubyfile'
        else
            throw 'AUTOTYPE: No ruby interpreter found'
        endif
        call writefile( a:lines , s:tempfile)
        exe cmd . "  ".s:tempfile
        return 0
    endif
endfun "}}}
fun! autotype#perl_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['perl']")
        return g:autotype_code_runner.perl(a:lines, a:context)
    else
        if exists("g:autotype_code_cmd['perl']")
            let cmd = g:autotype_code_cmd['perl']
            call writefile( a:lines , s:tempfile)
            exe cmd . "  " . s:tempfile
        elseif has('perl')
            for line in a:lines
                if line =~ '^\s*$'
                    continue
                endif
                exe "perl ".line
            endfor
        else
            throw 'AUTOTYPE: No perl interpreter found'
        endif
        return 0
    endif
endfun "}}}
fun! autotype#lua_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['lua']")
        return g:autotype_code_runner.lua(a:lines, a:context)
    else
        if exists("g:autotype_code_cmd['lua']")
            let cmd = g:autotype_code_cmd['lua']
        elseif has('lua')
            let cmd = 'luafile'
        else
            throw 'AUTOTYPE: No lua interpreter found'
        endif
        call writefile( a:lines , s:tempfile)
        exe cmd . "  " . s:tempfile
        return 0
    endif
endfun "}}}
fun! autotype#javascript_lines(lines, context) "{{{
    if exists("*g:autotype_code_runner['javascript']")
        return g:autotype_code_runner.javascript(a:lines,
                                    \ a:context)
    else
        if exists("g:autotype_code_cmd['javascript']")
            let jscmd = g:autotype_code_cmd['javascript']
        elseif executable('node')
            let jscmd = '!node'
        elseif executable('/System/Library/Frameworks/JavaScriptCore.framework/Resources/jsc')
            let jscmd = '!/System/Library/Frameworks/JavaScriptCore.framework/Resources/jsc'
        elseif executable('js')
            let jscmd = '!js'
        else
            throw 'AUTOTYPE: No javascript interpreter found'
        endif

        let json = s:json_encode(a:context)

        let lines = ['(function(__){ ']+a:lines+[' require("fs").writeFileSync("'.s:temp_return.'",JSON.stringify(__));return __;}('.json.'))']
        call writefile( lines , s:tempfile)
        exe jscmd. " ".s:tempfile . ' 1>'.s:temp_log. ' 2>'.s:temp_err


        for line in readfile(s:temp_log)
            echom line
        endfor
        let err =  readfile(s:temp_err)
        if !empty(err)
            for line in err
                call s:echo('!',-1,line)
            endfor
            throw 'AUTOTYPE: Javascript throws an error'
        endif

        return s:json_decode(join(readfile(s:temp_return),''))
    endif
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
        let _l = split('turtle,mankind,swift,storm,lighting', ',')
        let _k = split('2,30,120,600,3000', ',')
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
