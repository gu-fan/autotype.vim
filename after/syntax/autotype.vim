call autotype#init()

let s:s = g:_autotype.syn


let s:path = join([$VIMRUNTIME, split(&rtp,',')[0]],',')
for code in  ['vim', 'python']
    let paths = split(globpath(s:path, "syntax/".code.".vim"), '\n')

    if !empty(paths) 
        " if !exists("b:syntax_loaded") || b:syntax_loaded == 0
            let code_path = fnameescape(paths[0])
            unlet! b:current_syntax
            exe "syn include @autotype_".code." ".code_path
            exe "syn region autotypeCode_".code." matchgroup=autotypeCodePair_".code." start='" .s:s['code_'.code.'_bgn'] 
                        \."' end='". s:s['code_'.code.'_end']
                        \."' contains=@autotype_".code." keepend"
            unlet code_path
            " let b:syntax_loaded = 1
        " endif
    else 
        exe "syn region autotypeCode_".code." matchgroup=autotypeCodePair_".code." start='" .s:s['code_'.code.'_bgn']  
                    \."' end='". s:s['code_'.code.'_end']. "'"
    endif
endfor

exe "syn region autotypeCmt matchgroup=autotypeCmtPair start='" . s:s.cmt_bgn
                \."' end='". s:s.cmt_end . "'"

exe "syn match autotypeCmdPair '". s:s.cmd_p
            \."' contained"
exe "syn match autotypeCmd '". s:s.cmd
            \."' contains=autotypeCmdPair"

exe "syn match autotypeVarPair '". s:s.var_p
            \."' contained"
exe "syn match autotypeVar '". s:s.var
            \."' contains=autotypeVarPair"

exe "syn match autotypeOnce '". s:s.once ."'"

hi def link autotypeCmd Statement
hi def link autotypeCmdPair Delimiter
hi def link autotypeCmt Comment
hi def link autotypeCmtPair Comment
hi def link autotypeCode_vim String
hi def link autotypeCode_python String
hi def link autotypeCodePair_vim Typedef
hi def link autotypeCodePair_python Keyword
hi def link autotypeVar Number
hi def link autotypeVarPair Include
hi def link autotypeOnce Keyword
