package Lexing

import str "core:strings"

//Symbols
SymbolToken :: union
{
    LeftBraceToken,
    RightBraceToken,
    LeftParenToken,
    RightParenToken,
    CommaToken,
    DotToken,
    ColonToken,
    SemicolonToken,
    DollarToken,

    //Operators
    AdditionToken,
    AdditionAssignToken,
    SubtractToken,
    SubtractAssignToken,
    MultiplyToken,
    MultiplyAssignToken,
    DivideToken,
    DivideAssignToken,
} 
LeftBraceToken :: distinct TokenBase
RightBraceToken :: distinct TokenBase

LeftParenToken :: distinct TokenBase
RightParenToken :: distinct TokenBase

CommaToken :: distinct TokenBase
DotToken :: distinct TokenBase
SemicolonToken :: distinct TokenBase
ColonToken :: distinct TokenBase
DollarToken :: distinct TokenBase

AdditionToken :: distinct TokenBase
AdditionAssignToken :: distinct TokenBase
SubtractToken :: distinct TokenBase
SubtractAssignToken :: distinct TokenBase
MultiplyToken :: distinct TokenBase
MultiplyAssignToken :: distinct TokenBase
DivideToken :: distinct TokenBase
DivideAssignToken :: distinct TokenBase

get_symbol_token :: proc(input : ^str.Reader, pos : ^TokenPos) -> (ret : SymbolToken)
{
    copy, endPos := input^, pos^
    r, _ := read_rune(&copy, &endPos)
    switch r
    {
        case '{': ret = LeftBraceToken{pos^}
        case '}': ret = RightBraceToken{pos^}
        case '(': ret = LeftParenToken{pos^}
        case ')': ret = RightParenToken{pos^}
        case ',': ret = CommaToken{pos^}
        case '.': ret = DotToken{pos^}
        case ':': ret = ColonToken{pos^}
        case ';': ret = SemicolonToken{pos^}
        case '$': ret = DollarToken{pos^}
        case '+':
        {
            if is_assignment(&copy, &endPos) do ret = AdditionAssignToken{pos^}
            else do ret = AdditionToken{pos^}
        }
        case '-':
        {
            if is_assignment(&copy, &endPos) do ret = SubtractAssignToken{pos^}
            else do ret = SubtractToken{pos^}
        }
        case '*':
        {
            if is_assignment(&copy, &endPos) do ret = MultiplyAssignToken{pos^}
            else do ret = MultiplyToken{pos^}
        }
        case '/':
        {
            if is_assignment(&copy, &endPos) do ret = DivideAssignToken{pos^}
            else do ret = DivideToken{pos^}
        }
        case:     ret = nil
    }

    input^, pos^ = copy, endPos
    return
}

//Forwards the reader on success
is_assignment :: proc(input : ^str.Reader, pos : ^TokenPos) -> bool
{
    return peek_is_rune(input, pos, '=')
}
//Forwards the reader on success
peek_is_rune :: proc(input : ^str.Reader, pos : ^TokenPos, comp : rune) -> bool
{
    if r, ok := read_rune(input, pos); ok
    {
        if r == comp do return true
        else do unread_rune(input, pos)
    }
    return false
}