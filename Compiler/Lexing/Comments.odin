package Lexing

import str "core:strings"


CommentToken :: union
{
    LineComment,
    MultiComment,
}

CommentTokenBase :: struct
{
    using Base : TokenBase,
    Comment : string,
}
LineComment :: distinct CommentTokenBase
MultiComment :: distinct CommentTokenBase


get_comment_token :: proc(input : ^str.Reader, pos : ^TokenPos) -> (token : CommentToken)
{
    copy, endPos := input^, pos^
    if r, ok := read_rune(&copy, &endPos); ok
    {
        if peek_is_rune(&copy, &endPos, '/')
        {
            if peek_is_rune(&copy, &endPos, '/')
            {
                for r in read_rune(&copy, &endPos)
                {
                    if r == '\n'
                    {
                        //token = LineComment{Position = pos^, Comment = }
                    }
                }
            }
        }
    }

    return nil
}