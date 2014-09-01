Autotype.vim
============

:version: 0.10.7

..

    Yes, Vim will work for you.

    -- autotype.vim


An auto typing engine for vim.


.. figure:: https://github.com/Rykka/github_things/raw/master/image/autotype.gif
       :align: center



Install
=======

Download from Github_, Or Using Vundle or NeoBundle.

``Bundle 'Rykka/autotype.vim'``


Useage
======


AutoType [source_file]
   Start auto typing source_file into current buffer

   All contents of that source_file will be typed

   You can use ``Ctrl-C`` to stop.

   When source_file is omitted, all autotype file under '&rtp' will
   be found for you.


Advancing Usage
===============

You can define commands and variables in specific tags.

See below.

:WARNING: Behavior of using commands and mappings are **NOT**
          predictable.

          As users may have different settings.

          And as ``AutoType`` can do mostly everything with your vim.

          So run autotype file always with **DOUBLE CHECKING**.


Syntax Overview
---------------

Files with '.autotype' extensions will be recongized as ``autotype`` filetype.

Default syntax is 'jinja' alike, and can be changed. 

vim commands are used directly in these tags.

Try demo with ``:AutoType syntax``.

File is at ``autotype/syntax.autotype``.

Syntax overview::

    Comments
    {# Comments or Multiline Comments 
       Can be used #}

    Command Tag:
    {% ECHO 'GO START' | NORM! 0  | TYPE 'SOMETHING' | NORM! $ %}

    Code Blocks:
    {@ vim
        let a = 10
        " Insert line number for last 10 lines
        exe 'norm! '.a.'k'
        for i in range(a)
            norm! 0
            INSERT 'LINE '.i.' '
            norm! j
        endfor
    @}
    
    Use python code 
    {@ python
    # Aware the indent.
    # You can access local variables with _
    print _['__file__']
    def Hello(name):
        print name

    Hello('World')
    _['__file__'] = 5
    @}
   
    Variable Tag: 

        Local variable:  a = {{ a }}
        Eval {{ range(10) + [1, 2, 3] }}
        Context variable: {{ __file__ }}

    Simple Command Tag: 
    (^_xxx follow with a space or end of line)

    Yank ^_yy

    Paste and go end of line ^_p$

:Warning: 

      **Work With Moving Commands**

      When using moving command like 
      ``{{% norm 0 %}}`` or ``^_0``

      Following lines will be typed **FROM** that position.
      This will make output totally different from autotype source.

      **BUT IT IS THE DESIRED BEHAVIOR**

      *AS THIS IS AN AUTOTYPE ENGINE, NOT A TEMPLATE ENGINE.*

      So you must always take care what is the correct position
      after a moving command. 

      (Luckily, you can test by typing it directly.)


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

      See demo with ``AutoType position``.

      File is at ``autotype/position.autotype``

Code Block
----------

Code blocks are codes between ``{@ and @}`` tag.
The tag should be in a single line.

The code name must follow by the starting tag.
like ``{@ vim`` or ``{@ python``

The local context are supported for following code.
    Vim: works as using local variable. eg. ``__file__``

    Python: access from dict ``_``. e.g. ``_['__file__']``

    javascript: access from object ``__``. e.g. ``__.__file__``

g:autotype_code_list
    The code can be used in code blocks

    default is 'vim,sh,python,python3,ruby,perl,lua,javascript'

    if you adding a new code type.

    You should define it's runner and syntax.

    See below.

g:autotype_code_syntax
    A dict for the code's vim syntax file to highlight in vim.

    default is 'python3', 'python'

g:autotype_code_cmd
    The file intepreter command for the code block.

    default is {}.

    Then the default codes will be use predefined cmds.

    like 'pyfile' or 'rubyfile' or '!node'.

    You can set it to {'python': '!python2'} to use the python2
    files.

g:autotype_code_runner

    A dict contain functions for you to intepreter the codes.

    @params: 
        lines: a list of string contains the lines

        context: a dict of local context

    @returns
        context: returns the local context if needed.

    to print things, you can use ``echom``
    to print errors, you can just throw them

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
    __sourcing__
        The autotype file currently in sourcing.
    __include__
        A list of included autotype files.
    __arg__
        Argument passed to ``AutoType``
    __line__
        Executing line
    __lnum__
        Executing line number
    __time__
        Start time
    __speed__
        The executing speed

You can set global context variables 
by setting ``g:autotype_global_context``, e.g.::
        
    let g:autotype_global_context = {'__author__': 'AutoType'}

You can get last context with ``g:autotype_last_context``.

Help Commands
-------------

*Commands that can be used both in tags and vim*

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

    You can pass a list:
        Then it will echo with each item.

        e.g.::

            ECHO range(10,1,-1) | 1BLINK 'Go!'

    You can pass a dictionary:
        'hl': hightlight. 
        You can set ``g:autotype_default_hl`` for it.

        'char': '[char]' part.
        You can set ``g:autotype_default_char`` for it.

        'arg': str/lst to print

    e.g.::  

        ECHO {'hl':'String','arg':'Hello', 'char': 'Mike'}

    Add ``n`` to wait ``n`` second.
    Default is dynamic by current speed.

    The things echoed will also be shown in ':message'.


    :XXX: A number passed to ``ECHO`` directly can not be shown.

          Like ``:ECHO 3``,
          will produce ``Argument Required Error``

          So use ``ECHO '3'`` 
          or ``ECHO a`` (assume ``a == 3`` )

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
    Include a autotype source file in command tag/block.

    This command can **NOT** be executed as vim command.

    It searches the source file from 
    ``local>g:autotype_file_directory>&rtp``

    See demo with ``AutoType include``.
    File is at ``autotype/include.autotype``

    When files are recursively included, it will run
    only the first time.
    
Options
=======

g:autotype_speed
    Auto typing speed (char per second), range from (1 to more),
    default is ``30``, which is mankind.

    Slow as turtle? use '2'.

    Fast as swift? use '120'.

    Faster as storm? use '600'.

    Blazing lighting? use '3000' or more.

    You can set it with one of 
    ``turtle,mankind,swift,storm,lighting``,

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

    This is mainly used for updating buffer with InstantRst_

g:autotype_default_char 
    The '[char]' part for ``ECHO|BLINK``

g:autotype_default_hl
    The '[char]' part's highlight for ``ECHO|BLINK``


ISSUES
======

Post issues at github_

You can contribute to them as well.

Currently, there are some issues around.
        
    1. Typing ``'`` with some text will cause the text to reindent.

       This is caused mainly by indent settings
       like '&inde,&indk,&cpo'.
       So you should check them first.

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
    8. [X] 2014-09-01 Add Python Code Block support
    9. [X] 2014-09-01 Add Ruby/Javascript/Perl/Lua/... Code Block
    10. [o] Add Ruby/Javascript/Perl/Lua/... Context support
    11. Make more autotype sources.
    12. Make it more stable and useful.
    13. Helping others.


.. _github: https://github.com/Rykka/autotype.vim
.. _InstantRst: https://github.com/Rykka/InstantRst
