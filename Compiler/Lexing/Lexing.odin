package Lexing

import "core:fmt"
import str "core:strings"
import "core:os"
import "core:io"
import "core:slice"
Either :: union(A : typeid, B : typeid)
{
    A, B,
}
TokenPos :: struct {Line, Column : i32}
TokenBase :: struct
{
    using Position : TokenPos,
}
Token :: union
{
    ErrorToken,
    SymbolToken,
    KeywordToken,
    LiteralToken,
    IdentfierToken,
    CommentToken,
    WhitespaceToken,
}
ErrorToken :: struct
{
    using Base : TokenBase,
    Message : string,
}

IdentfierToken :: struct 
{
    using Base : TokenBase,
    Value : string,
}



lex :: proc(input : str.Reader) -> (output : [dynamic]Token)
{
    input := input
    pos := TokenPos{1, 0}

    for 
    {    
        _, _, error := str.reader_read_rune(&input)
        if error != .None do break
        _ = str.reader_unread_rune(&input)  
        
        if token := get_whitespace_token(&input, &pos); token != nil
        {
            append(&output, token)
        }
               
        if token := get_symbol_token(&input, &pos); token != nil
        {
            append(&output, token)
            continue
        }

        if token := get_comment_token(&input, &pos); token != nil
        {
            append(&output, token)
            continue
        }
    
        if token := get_indentifier_or_keyword(&input, &pos); token != nil
        {
            if t, ok := token.(KeywordToken); ok
            {
                append(&output, t)
            }
            else if t, ok := token.(IdentfierToken); ok
            {
                append(&output, t)
            }

            continue
        }
        fmt.printf("Unhandled rune in lexer(%i, %i)\n", pos.Line, pos.Column)
    }

    return
}

//Keywords are essentially reserved identifiers
get_indentifier_or_keyword :: proc(input : ^str.Reader, pos : ^TokenPos) -> (token : Either(IdentfierToken, KeywordToken))
{
    //NOTE@PERF: Linear Search, could be changed into:
    //           A map for O(1) search
    //           An ordered slice for Binary Search
    @static ILLEGAL_RUNES := []rune {'=',
        '+', '-', '*', '/', '%',
        '!', '?', '.', ',', ':', ';',
        '~', '^', '&', '|',
        '<', '>', '(', ')', '{', '}', '[', ']',
        ' '/*SPACE*/, '	'/*TAB*/, '\n', '\r',
    } 

    copy := input^
    endPos := pos^

    for r in read_rune(&copy, &endPos)
    {
        if _, illegal := slice.linear_search(ILLEGAL_RUNES, r); illegal
        {
            unread_rune(input, pos)
            break
        }
    }

    str.reader_unread_rune(input)
    unread_rune(&copy, &endPos)

    str := input.s[input.i:copy.i]
    if t := get_keyword_token(str, pos^); t != nil
    {
        token = t
    }
    else
    {
        token = IdentfierToken{Position = pos^, Value = str}
    }

    input^ = copy
    pos^ = endPos

    return
}

is_whitespace :: proc(r : rune) -> bool
{
    return r == ' ' || r == '\n' || r == '\r'
}

is_digit :: proc(r : rune) -> bool
{
    return r >= '0' && r <= '9'
}

read_rune :: proc(input : ^str.Reader, pos : ^TokenPos) -> (rune, bool)
{
    r, size, error := str.reader_read_rune(input)
    if r == '\n'
    {
        pos.Line += 1
        pos.Column = 0
    }
    else
    {
        pos.Column += 1
    }
    return r, error == .None
}

unread_rune :: proc(input : ^str.Reader, pos : ^TokenPos)
{
    str.reader_unread_rune(input)
    pos.Column -= 1
}