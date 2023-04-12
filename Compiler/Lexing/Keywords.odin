package Lexing

KeywordToken :: union
{
    ImportToken,
    PackageToken,
    MutToken,
    StructToken,
    FnToken,
    TrueToken,
    FalseToken,
    RequiresToken,
    UseToken,
    UsingToken,

}

ImportToken :: distinct TokenBase
PackageToken :: distinct TokenBase
MutToken :: distinct TokenBase
StructToken :: distinct TokenBase
FnToken :: distinct TokenBase
TrueToken :: distinct TokenBase
FalseToken :: distinct TokenBase
RequiresToken :: distinct TokenBase
UseToken :: distinct TokenBase
UsingToken :: distinct TokenBase

get_keyword_token :: proc(input : string, pos : TokenPos) -> KeywordToken
{
    switch input
    {
        case "import":   return ImportToken{pos}
        case "package":  return PackageToken{pos}
        case "struct":   return StructToken{pos}
        case "fn":       return FnToken{pos}
        case "mut":      return MutToken{pos}
        case "true":     return TrueToken{pos}
        case "false":    return FalseToken{pos}
        case "using":    return UsingToken{pos}
        case "requires": return RequiresToken{pos}
        case "use":      return UseToken{pos}
        case :           return nil
    }
}