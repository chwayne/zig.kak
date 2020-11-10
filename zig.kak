# Detection

hook global BufCreate .*[.](zig) %{
    set-option buffer filetype zig
}

# Highlighters

add-highlighter shared/zig regions
add-highlighter shared/zig/code default-region group
add-highlighter shared/zig/string   region c?"       (?<!\\)(?:\\\\)*" group
add-highlighter shared/zig/mlstring region %{c?\\\\} $                 fill string
add-highlighter shared/zig/char     region c?'       (?<!\\)(?:\\\\)*' group
add-highlighter shared/zig/comment  region //        $                 fill comment

add-highlighter shared/zig/string/   fill string
add-highlighter shared/zig/char/     fill string

nop %sh{
    escape='\\(?:[nrt\\'\''"]|x[a-zA-Z0-9]{2}|u\{[a-zA-Z0-9]+\})'
    cat <<KAK
        add-highlighter shared/zig/string/ regex ${escape} 0:default+b
        add-highlighter shared/zig/char/ regex ${escape} 0:default+b
        add-highlighter shared/zig/char/ regex %{'(?:[^\\]|${escape})([^']+)'} 1:Error
KAK
}

add-highlighter shared/zig/code/ regex \b(const|var|extern|packed|export|pub|noalias|inline|comptime|volatile|align|linksection|callconv|threadlocal|allowzero)\b 0:keyword
add-highlighter shared/zig/code/ regex \b(struct|enum|union|error|opaque)\b 0:keyword
add-highlighter shared/zig/code/ regex \b(break|return|continue|asm|defer|errdefer|unreachable|try|catch|orelse|async|await|suspend|nosuspend|resume|cancel)\b 0:keyword
add-highlighter shared/zig/code/ regex \b(if|else|switch|and|or)\b 0:keyword
add-highlighter shared/zig/code/ regex \b(while|for)\b 0:keyword
add-highlighter shared/zig/code/ regex \b(fn|usingnamespace|test)\b 0:keyword

add-highlighter shared/zig/code/ regex \b(bool|f16|f32|f64|f128|void|noreturn|type)\b 0:type
add-highlighter shared/zig/code/ regex \b(u\d+|i\d+|isize|usize|comptime_int|comptime_float|anytype|anyerror|anyframe)\b 0:type
add-highlighter shared/zig/code/ regex \b(c_short|c_ushort|c_int|c_uint|c_long|c_ulong|c_longlong|c_ulonglong|c_longdouble|c_void)\b 0:type

add-highlighter shared/zig/code/ regex \b(null|undefined)\b 0:variable
add-highlighter shared/zig/code/ regex \b(true|false)\b 0:value
add-highlighter shared/zig/code/ regex \b[0-9]+(?:.[0-9]+)?(?:[eE][+-]?[0-9]+)? 0:value # decimal numeral
add-highlighter shared/zig/code/ regex \b0x[a-fA-F0-9]+(?:[a-fA-F0-9]+(?:[pP][+-]?[0-9]+)?)? 0:value # hexadecimal numeral
add-highlighter shared/zig/code/ regex \b0o[0-7]+ 0:value # octal numeral
add-highlighter shared/zig/code/ regex \b0b[01]+(?:.[01]\+(?:[eE][+-]?[0-9]+)?)?" 0:value # binary numeral

add-highlighter shared/zig/code/ regex @(addWithOverflow|alignCast|alignOf|as|asyncCall|atomicLoad|atomicRmw|atomicStore|bitCast|bitOffsetOf|boolToInt|bitSizeOf|breakpoint|mulAdd|byteSwap|bitReverse|byteOffsetOf|call|cDefine|cImport|cInclude|clz|cmpxchgStrong|cmpxchgWeak|compileError|compileLog|ctz|cUndef|divExact|divFloor|divTrunc|embedFile|enumToInt|errorName|errorReturnTrace|errorToInt|errSetCast|export|fence|field|fieldParentPtr|floatCast|floatToInt|frame|Frame|frameAddress|frameSize|hasDecl|hasField|import|intCast|intToEnum|intToError|intToFloat|intToPtr|memcpy|memset|wasmMemorySize|wasmMemoryGrow|mod|mulWithOverflow|panic|popCount|ptrCast|ptrToInt|rem|returnAddress|setAlignStack|setCold|setEvalBranchQuota|setFloatMode|setRuntimeSafety|shlExact|shlWithOverflow|shrExact|shuffle|sizeOf|splat|reduce|src|sqrt|sin|cos|exp|exp2|log|log2|log10|fabs|floor|ceil|trunc|round|subWithOverflow|tagName|TagType|This|truncate|Type|typeInfo|typeName|TypeOf|unionInit)\b 0:builtin

add-highlighter shared/zig/code/ regex ((\+|-|\*|<<)%?|/|=|\^|&|\?|\||!|>|<|%|>>)=? 0:operator
add-highlighter shared/zig/code/ regex -> 0:operator

# Commands

define-command -hidden zig-filter-around-selections %{
    # remove trailing whitespace
    try %{ execute-keys -draft -itersel <a-x> s\h+$<ret> d }
}

define-command -hidden zig-indent-on-new-line %[
    evaluate-commands -draft -itersel %[
        # copy comment prefix //
        # try %{ execute-keys -draft k <a-x> s^\h*\K///?\h*<ret> y gh j P }
        # preserve indent
        try %{ execute-keys -draft ';' K <a-&> }
        # filter previous line
        try %{ execute-keys -draft k :zig-filter-around-selections<ret> }
        # indent after lines ending with { or (
        try %[ execute-keys -draft k <a-x> <a-k>[{(]\h*$<ret> j <a-gt> ]
    ]
]

define-command -hidden zig-indent-on-closing-curly-brace %[
    evaluate-commands -draft -itersel %[
        # align to opening brace when the closing brace is the only thing on this line
        try %[ execute-keys -draft <a-h> <a-k>^\h+\}$<ret> h m s\A|.\z<ret> 1<a-&> ]
    ]
]

# Initialization

hook -group zig-highlight global WinSetOption filetype=zig %{
    add-highlighter window/zig ref zig

    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/zig
    }
}

hook global BufSetOption filetype=zig %[
    set-option buffer comment_line '//'
    set-option buffer formatcmd 'zig fmt --stdin'
    set-option buffer makecmd 'zig build && echo "Done."'

    hook -group zig-hooks buffer ModeChange insert:.* zig-filter-around-selections
    hook -group zig-indent buffer InsertChar \n zig-indent-on-new-line
    hook -group zig-indent buffer InsertChar \} zig-indent-on-closing-curly-brace

    hook buffer BufWritePre .* %{format}
]
