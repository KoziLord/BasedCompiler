package Lexing

import str "core:strings"
LiteralToken :: union
{
    IntegerLiteralToken,
    FloatLiteralToken,
    StringLiteralToken,
}

IntegerLiteralToken :: distinct LiteralTokenBase
FloatLiteralToken :: distinct LiteralTokenBase
StringLiteralToken :: distinct LiteralTokenBase

LiteralTokenBase :: struct
{
    using Base : TokenBase,
    Value : string,
}

//REFACTOR: Turn into get_literal_token which would then call this when needed
get_number_token :: proc(input : ^str.Reader, pos : ^TokenPos) -> (token : Either(LiteralToken, ErrorToken))
{
    copy := input^
    endPos := pos^
    isFloat := false
    for r in read_rune(&copy, &endPos)
    {
        sym := get_symbol_token(r, pos^)
        if _, ok := sym.(DiscardToken); ok
        {
            sym = nil
        }

        if _, ok := sym.(DotToken); ok
        {
            if isFloat
            {
                if token == nil
                {
                    token = ErrorToken{Position = {endPos.Line, endPos.Column - 1}, Message = "Extra \'.\' found in a float literal"}
                }
            }
            isFloat = true

            sym = nil
        }

        if is_whitespace(r) || sym != nil
        {
            break
        }
    }
    str.reader_unread_rune(input)
    unread_rune(&copy, &endPos)

    word, wordPos := input.s[input.i:copy.i], pos^
    t := LiteralToken{}
    switch isFloat
    {
        case true:  t = FloatLiteralToken{Position = pos^, Value = word}
        case false: t = IntegerLiteralToken{Position = pos^, Value = word}
    }
    if t == nil do token = t
    
    input^ = copy
    pos^ = endPos

    return token
}
