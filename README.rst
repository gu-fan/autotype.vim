Autotype.vim
============

:version: 0.10.6

..

    Yes, Vim will work for you.

    -- autotype.vim


An auto typing engine for vim.


.. figure:: https://github.com/Rykka/github_things/raw/master/image/autotype.gif
       :align: center



Install
=======

Download from Github_, Or 

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

:WARNING: **USE THEM WITH CAUTION**

          Behavior of using commands and mappings are not predictable.
          As users have different settings.

          And **DON'T EVER** run other's autotype file 
          without double checking.

Advancing usage.

You can define commands and variables in specific tags.

See below.


Syntax
------

The syntax for autotype sources.

Default it's jinja like, and files with '.autotype' extensions will be recongized as ``autotype`` filetype and highlighted.

vim commands are used directly in these tags.

Try with ``:AutoType syntax``
See ``autotype/syntax.autotype`` for details. 

Syntax overview::

    Comments 
    {# This is a line of Comments #}

    Comments Block
    {# Multiline Comments 
       Can be used Too #}

    Command Tag:
    {% ECHO 'GO START' | NORM! 0  | TYPE 'SOMETHING' | NORM! $ %}

    Command Blocks:
    {@
        let a = 10
        " Insert line number for last 10 lines
        exe 'norm! '.a.'k'
        for i in range(a)
            norm! 0
            INSERT 'LINE '.i.' '
            norm! j
        endfor
    @}
    
    Variable Tag: 
    {{ range(10) + [1, 2, 3] }}

    local variable:  a = {{ a }}
    context variable: {{ __file__ }}

    Simple Command Tag: 
    (^_xxx follow with a space or end of line)

    Yank 
    Something ^_yy

    Then Paste and go end of line ^_p$

:Warning: 

      **Work With Moving Commands**

      When using moving command like ``{{% norm 0 %}}``

      Following lines will be typed **AT** that position.
      This will make output totally different from autotype source.

      **BUT IT IS THE DESIRED BEHAVIOR**

      *AS THIS IS AN AUTOTYPE ENGINE, NOT A TEMPLATE ENGINE.*

      So you must always keep in mind where is the correct position.

      e.g.:

      An autotype file::

          {# WRONG ONE #}
          THE {% NORM 0 | INSERT 'THIS' %} IS
          CORRECT
          POSITION

      will produce::

          THIS IS
          CORRECT
          POSITIONTHE 

      You need to add a movement back to make it work::

          {# CORRECT ONE #}
          THE {% NORM 0 | INSERT 'THIS' %} IS {% norm $ %}
          CORRECT
          POSITION

      Then this will produce::

          THIS IS THE
          CORRECT
          POSITION

      You can use the simple command tag::

          {# SIMPLE ONE 
             Note: the command will consume one space
              So we must type 2 space here.  #}
          THE ^_0iTHIS  IS ^_$
          CORRECT
          POSITION

      See The effects with ``AutoType position``.

      File is at ``autotype/position.autotype``

Variables
---------

Variables are valid in each running context.

You can use 'b:var' or 'g:var' for global variables across 
sources.

See ``autotype/var.autotype`` for a example.

**Context Variables**

There are some predefined context variables.

    __file__
        The file name that running ``AutoType`` command
    __source__
        The autotype source file. 
    __arg__
        Argument passed to ``AutoType``
    __line__
        Executing line
    __lnum__
        Executing line number
    __time__
        Start time
    __exec_time__
        Total executed time (Not avaliable during executing)
    __speed__
        The executing speed

You can set global context variables 
by setting ``g:autotype_global_context``, e.g.::
        
    let g:autotype_global_context = {'__author__': 'AutoType'}

You can get last context with ``g:autotype_last_context``.

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

    :NOTE: To add to the beginning of line, instead of 
           beginning of line content.

           You should use ``NORM 0`` to move there.

TYPE[!] 'text here'
    Same as ``APPEND``.


[n]ECHO[!] [str/list/dict]
    Echo things like ':echo', And will show for a longer time.


    Add ``!`` to use ``ErrorMsg`` highlight,
    Default is ``ModeMsg`` highlight.

        You can pass a dictionary with 'hl' to use that
        hightlight, 'arg' is needed then.

        e.g.:  ``{'hl':'Function','arg':'Echo Strings'}``

    Add ``n`` to wait ``n`` second.
    Default is dynamic by current speed.

    The things echoed will also be shown in ':message'.

    example::

        ECHO range(10,1,-1) | 1BLINK 'Hello World'

    :XXX: A plain number passed to echo can not be shown.
          like ``:ECHO 3``

[n]BLINK[!] [str/list/dict]
    A blinking versoin of ':echo' 

[n]BLINK[!] [str/list/dict]
    A blinking versoin of ':echo' 

:Note: **Bar**

       ``NORM|ECHO|TYPE|APPEND|BLINK|INSERT`` 
       both receives the ``|`` command.

       See ':h :command-bar'

:Note: **Quotes**

       In ``INSERT/APPEND/TYPE/ECHO/BLINK``,

       Strings passed must all using single quote ``'``.
       You can escape it with ``''``.

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

        Then you can try typing raw special charactes there.
        See ``:h i_Ctrl-V`` for details.



INCLUDE source_file[.autotype]
    Include a autotype source file in Command Tag/Block.
    Can not be executed as Vim Command.

    It searches the source file from 
    local/``g:autotype_file_directory``/&rtp

    See effects with ``AutoType include``
    You can check with ``autotype/include.autotype``


    
Options
=======

g:autotype_speed
    Auto typing speed (char per second), range from (1 to more),
    default is ``30``, which is mankind.

    Slow as turtle? use '2'.

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
        3. Comment tag is '{# var #}'
        4. Command block is '{@' and '@}',
           both in single line
        5. Inline Command is ``^_cmds``
        6. To prevent exec of tags, add a '!' before the tag.

    Then the 'autotype'
        1. Command tag is '^[ cmds ^]'
        2. Comment tag is '^< var ^>'
        3. Variable tag is '^{ var ^}'
        4. Command block is '^[^[' and '^]^]',
           both in single line
        5. Inline Command is ``^_cmds``

    You can define your own tag syntax if needed.
    Following list of options can be changed::
        
            ["g:autotype_syn_cmd_bgn",  '{%'],
            ["g:autotype_syn_cmd_end",  '%}'],
            ["g:autotype_syn_cmds_bgn", '{@'],
            ["g:autotype_syn_cmds_end", '@}'],
            ["g:autotype_syn_cmt_bgn",  '{#'],
            ["g:autotype_syn_cmt_end",  '#}'],
            ["g:autotype_syn_var_bgn",  '{{'],
            ["g:autotype_syn_var_end",  '}}'],
            ["g:autotype_syn_cmd_once", '^_'],

    :NOTE: ``g:autotype_syntax_type`` **SHOULD** be set
            with a name other than 'jinja' or 'autotype'

            And these options should be a pattern for matching.

            e.g: '^' should be escaped as ``'\^'``

            See ':h pattern-atoms' for details

g:autotype_file_directory
    The user directory for your autotype source files.

    Default is ``''``.

    The ``:AutoType source_file`` will search file in current dir,
    then in this path and the ``&rtp/autotype/`` directory
    for all '\*.autotype' file to match the filename.

    You can add multiple paths seperated with comma ','.

g:autotype_global_context
    You can predefine variable in context.

    e.g.::
        
        let g:autotype_global_context = {'__author__': 'AutoType'}

    See Variables_ for context details.


g:autotype_cursor_aug
    Used for running autocommands with ``CursorMoved``

    Set ``aug_ptn`` seperate with ``,``

    Default is ``'*.rst,<buffer>'``

    This is mainly for updating buffer with InstantRst_

ISSUES
======

Post issues at github_

You can contribute to them as well.

Currently, there are some issues around.
        
    1. Typing ``'`` with some text will cause the text to reindent.

TODO
====

1. Make autotype auto write articles.
2. Make autotype auto write programs.

And before, there are some ``misc`` things need to do.
You can find one thing and contribute to it at github_

    1. [X] 2014-08-31 Add local context support for commands and variables
    2. [X] 2014-08-30 Add Comment Tag And Block And Syntax.
    3. [X] 2014-08-28 Make input with Special Keys more workable.
    4. [X] 2014-08-29 Make Literal-String and Constant-String always working.
    5. [X] 2014-08-31 Add ``INCLUDE`` TAG
    6. [X] 2014-08-31 Add Striping Syntax like ``{%- and -%}``.
    7. [X] 2014-08-31 Make typing output like typing in insert mode.
    8. Make more autotype sources.
    9. Make it more stable and useful.
    10. Helping others.


.. _github: https://github.com/Rykka/autotype.vim
.. _InstantRst: https://github.com/Rykka/InstantRst
