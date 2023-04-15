package Lexing

import str "core:strings"


WhitespaceTokenBase :: struct
{
    using Base : TokenBase,
    Length : u32, 
}
SpaceToken :: distinct WhitespaceTokenBase
TabToken :: distinct WhitespaceTokenBase
NewlineToken :: distinct WhitespaceTokenBase
WhitespaceToken :: union
{
    SpaceToken,
    TabToken,
    NewlineToken,
}

//IMPORTANT: REWRITE THIS
get_whitespace_token :: proc(input : ^str.Reader, pos : ^TokenPos) -> WhitespaceToken 
{
    r, _ := read_rune(input, pos)
    length := u32(1)

    switch r
    {
        case ' ':
        {
            for a in read_rune(input, pos)
            {
                if a != ' '
                {
                    return SpaceToken{Position = pos^, Length = length}      
                }
                length += 1
            }
        }
        case '\n':
        {
            for a in read_rune(input, pos)
            {
                if a != '\n'
                {
                    return NewlineToken{Position = pos^, Length = length}      
                }
                length += 1
            }
        }
        case '	':
        {
            for a in read_rune(input, pos)
            {
                if a != '	'
                {
                    return TabToken{Position = pos^, Length = length}      
                }
                length += 1
            }
        }
    }
    return nil
}