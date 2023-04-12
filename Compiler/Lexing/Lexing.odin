package Lexing

import "core:fmt"
import str "core:strings"
import "core:os"
import "core:io"

Either :: union(A : typeid, B : typeid)
{
    A, B
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
    for r in read_rune(&input, &pos)
    {
        if is_whitespace(r) do continue
        if token := get_symbol_token(r, pos); token != nil
        {
            append(&output, token)
            continue
        }
    
        //Check if comment
        if r == '/'
        {
            r, ok := read_rune(&input, &pos)
            if !ok
            {
                panic("AAAAAAAAAAAAAAAAAAAAAAAAAA")
            }

            //Is comment
            if r == '/'
            {
                skip_to_eol(&input, &pos)
                continue
            }
            else
            {
                append(&output, ErrorToken{Position = pos, Message = "Stray / found. Were you perhaps trying to add a comment?"})
                continue
            }
        }

        //IsLiteral
        if is_digit(r)
        {
            token := get_number_token(&input, &pos)
            if token == nil
            {
                panic("Unreachable: get_number_token returned nil")
            }
            if error, is_error := token.(ErrorToken); is_error
            {
                append(&output, error)
                continue
            }
            
            append(&output, token.(LiteralToken))
            continue   
        }

        if word, wordPos, ok := read_word(&input, &pos); ok
        {
            //isKeyword
            if keyword := get_keyword_token(word, wordPos); keyword != nil
            {
                append(&output, keyword)
                continue
            }
           //Identifier
            append(&output, auto_cast IdentfierToken{Position = wordPos, Value = word})
            continue
        }
    }

    return
}

read_word :: proc(input : ^str.Reader, pos : ^TokenPos) -> (word : string, wordPos : TokenPos, ok : bool)
{
    copy := input^
    endPos := pos^

    for r in read_rune(&copy, &endPos)
    {
        sym := get_symbol_token(r, pos^)
        if _, ok := sym.(DiscardToken); ok
        {
            continue
        } 

        if is_whitespace(r) || sym != nil
        {
            break
        }
    }

    str.reader_unread_rune(input)
    unread_rune(&copy, &endPos)
    word, wordPos, ok = input.s[input.i:copy.i], pos^, true
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

skip_to_eol :: proc(input : ^str.Reader, pos : ^TokenPos)
{
    for r in read_rune(input, pos)
    {
        if r == '\n' do break
    }
}