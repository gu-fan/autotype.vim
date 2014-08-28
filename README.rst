Autotype.vim
============


    Yes, Vim will type for you.

    -- autotype.vim

Useage
======


AutoType [filename]
   Start autotyping into current buffer with filename.

Options
=======

g:autotype_cursor_aug
    Used for running autocommands with ``CursorMoved,CursorMovedI``

    set ``aug_ptn`` seperate with ``,``

    default is ``'*.rst,<buffer>'``

g:autotype_word_sleep
    Wait [m]ms after typing each word
    
    default is 150

g:autotype_line_sleep
    Wait [m]ms after typing each line

    default is 400
