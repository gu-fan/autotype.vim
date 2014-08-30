call autotype#init()

let s:path = join([$VIMRUNTIME, split(&rtp,',')[0]],',')
let s:paths = split(globpath(s:path, "syntax/vim.vim"), '\n')

let s:s = g:_autotype.syn

if !empty(s:paths) 
    " if !exists("b:syntax_loaded") || b:syntax_loaded == 0
        let vim_path = fnameescape(s:paths[0])
        unlet! b:current_syntax
        exe "syn include @autotype_vim ".vim_path
        exe "syn region autotypeCmds matchgroup=autotypeCmdPair start='" . s:s.cmds_bgn
                    \."' end='". s:s.cmds_end
                    \."' contains=@autotype_vim keepend"
        unlet vim_path
        " let b:syntax_loaded = 1
    " endif
else 
    exe "syn region autotypeCmds matchgroup=autotypeCmdPair start='" . s:s.cmds_bgn
                \."' end='". s:s.cmds_end . "'"
endif

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
hi def link autotypeCmds String
hi def link autotypeVar Number
hi def link autotypeVarPair Include
hi def link autotypeOnce Keyword
