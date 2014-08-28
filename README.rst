Autotype.vim
============

:version: 0.9

..

    Yes, Vim will type for you.

    -- autotype.vim


.. figure:: https://github.com/Rykka/github_things/raw/master/image/autotype.gif
   :align: center

   Auto typing in vim.


Install
=======

Using Vundle or NeoBundle.

``Bundle Rykka/autotype.vim``


Useage
======


AutoType [filename]
   Start auto typing into current buffer with filename.

   You can use ``Ctrl-C`` to stop.

Options
=======

g:autotype_by_char
    Auto typing by each char.

    default is ``1``

    If your computer is a bit slow, set it to 0, 
    Then word will be use by typing.


g:autotype_char_sleep
    Wait [m]ms after typing each char

    default is ``40``

g:autotype_word_sleep
    Wait [m]ms after typing each word
    
    default is ``150``

g:autotype_line_sleep
    Wait [m]ms after typing each line

    default is ``400``


g:autotype_cursor_aug
    Used for running autocommands with ``CursorMoved,CursorMovedI``

    set ``aug_ptn`` seperate with ``,``

    default is ``'*.rst,<buffer>'``

