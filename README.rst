Autotype.vim
============

:version: 0.10.3

..

    Yes, Vim will work for you.

    -- autotype.vim


Auto typing in vim.

.. figure:: https://github.com/Rykka/github_things/raw/master/image/autotype.gif
       :align: center

Install
=======

Using Vundle or NeoBundle.

``Bundle 'Rykka/autotype.vim'``


Useage
======


AutoType [source_file]
   Start auto typing source_file into current buffer with filename.

   All contents of that file will be typed into current buffer.

   You can use ``Ctrl-C`` to stop.

   When source_file is omitted, All autotype file under '&rtp' will
   be found for you.

Advancing
=========

Advancing usage.

You can define commands and variables in specific tags.

See below.

:WARNING: Behavior of using window/cmdline commands and 
          mappings are not predictable.

          **USE THEM WITH CAUTION**

          And **DON'T EVER** run other's autotype file 
          without double checking.

Syntax
------

The syntax default is jinja like, and files with '.autotype' extensions will be recongized as ``autotype`` filetype and highlighted.

vim commands are used directly in these tags.

You can have a try with ``:AutoType syntax``

Syntax overview::

    Variable Tag: 
    {{ range(10) + [1, 2, 3] }}

    Command Tag:
    {% ECHO 'GO START' | NORM! 0  | TYPE SOMETHING | NORM! $ %}

    Command Blocks:
    {@
        let l = input('Please input the line:')
        for i in range(10)
            TYPE 'LINE '.i.':'.l.'\r'
        endfor
    @}
    
    Simple Command: (!^_xxx)

    Yank 
    Something ^_yy

    Then Paste 
    ^_P

:NOTE: Variables are only valid in it's Tag/Block.

       You can use 'b:var' or 'g:var' for a global variable.

Help Commands
-------------

*commands that can be used both in tags and vim*

NORMAL[!] commands here
    Like ':normal', And words like \<C-W> will be convert 
    to that special character

    Add ``!`` to act as ``:normal!``

    example::

        NORM :ECHO 'Hello '.input('Your name:')\<CR>Auto\<CR>
        " will produce:
        " Hello Auto

APPEND[!] 'text here'
    Append things with current cursor position.
    Act as ``a`` in normal mode

    Add ``!`` and act as ``A``

    example::

        APPEND string(range(4))
        " will append to current line with
        " [0, 1, 2, 3]

INSERT[!] 'text here'
    Insert things with current cursor position.
    Act as ``i`` in normal mode

    Add ``!`` and act as ``I``

ECHO[!] 'text here'
    Echo things like ':echo', And will show for a longer time.

    Add ``!`` to use ``ErrorMsg`` Highlight.

    Echoed things will be shown in 'message'.

BLINK[!] 'text here'
    A blinking ':echo'

    Add ``!`` to use ``ErrorMsg`` Highlight.

:Note: **Bar**

       They both receive the ``|`` command.

       See ':h :command-bar'

:Note: **Quotes**

       In ``INSERT/APPEND/ECHO/BLINK``,
       Strings passed must all using single quote ``'``.

       In ``INSERT/APPEND``: works as double quoted,

           Then you can use ``\r`` as a return.
           To insert a ``\``, escape as ``\\``

       In ``ECHO/BLINK``: works as single quoted.

       See ':h expr-string'.

:Note: **Special Characters**

        In ``NORMAL``, Trigger special keys using ``\<C-XX>``

        If you met something unexpected with command line input
        action.

        First check if enough ``\<CR>`` are used.

        Then you can try typing raw Special charactes there.
        See ``:h i_Ctrl-V`` for details.


Options
=======

g:autotype_speed

    Auto typing speed (char per second), range from (1 to more),
    default is ``30``, which is mankind.

    A Slow turtle? use '2'.

    Fast as swift? use '400'.

    Blazing lighting? use '30000' or more.

    You can set it with one of 
    ``turtle,mankind,swift,lighting``,

    Then it's at the relevent speed.

    ``:AtpSpd`` can be used as a quick speed setup.

g:autotype_syntax_type

    Default is 'jinja'.
        1. Command tag is '{% cmds %}'
        2. Variable tag is '{{ var }}'
        3. Command block is '{@' and '@}',
           both in single line
        4. Inline Command is ``^_cmds``
        5. To prevent exec of tags, add a '!' before the tag.

    Then the 'autotype'
        1. Command tag is '^[ cmds ^]'
        2. Variable tag is '^{ var ^}'
        3. Command block is '^[^[' and '^]^]',
           both in single line
        4. Inline Command is ``^_cmds``

    You can define your tags
    with following list of options::
        
            ["g:autotype_syn_cmd_bgn",  '{%'],
            ["g:autotype_syn_cmd_end",  '%}'],
            ["g:autotype_syn_cmds_bgn", '{@'],
            ["g:autotype_syn_cmds_end", '@}'],
            ["g:autotype_syn_var_bgn",  '{{'],
            ["g:autotype_syn_var_end",  '}}'],
            ["g:autotype_syn_cmd_once", '^_'],

    .. NOTE:: You should set g:autotype_syntax_type with your name

        And the value should be a pattern for matching.

        for example: '^' should be escaped as ``'\^'``

g:autotype_file_directory
    The user directory for your autotype source files.

    Default is ''.

    The ``:AutoType`` will search in this path
    and the ``&rtp/autotype/`` directory for All '\*.autotype' file
    to match the filename.

    You can add multiple paths seperated with comma ','.

g:autotype_cursor_aug
    Used for running autocommands with ``CursorMoved,CursorMovedI``

    set ``aug_ptn`` seperate with ``,``

    default is ``'*.rst,<buffer>'``

TODO
====

1. Make autotype auto write articles.
2. Make autotype auto write programs.

And before, there are some ``misc`` things need to do.
You can find one thing and contribute to it at github_

    1. Add local context support for commands and variables
    2. Add Comment Tag And Block And Syntax.
    3. Make input with Special Keys more workable.
    4. Make Literal-String and Constant-String always working.
    5. Make more autotype sources.
    6. Make it more stable and useful.
    7. Helping others.


.. _github: https://github.com/Rykka/autotype.vim
