package ReplHarness

import "core:fmt"
import str "core:strings"
import "core:os"
import win "core:sys/windows"
import i "core:bufio"
import BD "./Compiler"
import dn "core:dynlib"
import "core:time"
import libc "core:c/libc"

main :: proc()
{
    compilerLib : dn.Library
    lastUpdate := time.Time{}
    update_compiler(&compilerLib, &lastUpdate)
    run := true
    for run
    {
        switch repl()
        {
            case .Quit: run = false
            case .Recompile:
            {
                update_compiler(&compilerLib, &lastUpdate)
            }
            case .None:
        }
        free_all(context.temp_allocator)
    }
}

update_compiler :: proc(compilerLib : ^dn.Library, lastCompilerUpdate : ^time.Time)
{
    fmt.println("\\\\Compiling the compiler...")
    
    //Compile compiler
    libc.system("odin build ./Compiler -build-mode:dll -out:./Compiler.dll")

    fileInfo, errNo := os.stat("./Compiler.dll")
    defer os.file_info_delete(fileInfo)
    modTime := fileInfo.modification_time
    
    fmt.println("\\\\Reloading the compiler...")

    dn.unload_library(compilerLib^)

    dir := os.get_current_directory(context.temp_allocator)
    fileDir := str.concatenate({dir, "/Compiler.dll"}, context.temp_allocator)
    newDir := str.concatenate({dir, "/Compiler_tmp.dll"}, context.temp_allocator)
    win.CopyFileExW(win.utf8_to_wstring(fileDir),
                    win.utf8_to_wstring(newDir), nil, nil, nil, 0)

    lib, libLoaded := dn.load_library("./Compiler_tmp.dll")
    if !libLoaded do panic("Could not load the compiler, exiting...")

    symbol, symbolFound := dn.symbol_address(lib, "repl")
    if !symbolFound do panic("Could not load the repl function, exiting...")
        
    compilerLib^ = lib
    repl = auto_cast symbol
    lastCompilerUpdate^ = modTime

    return   
}

repl : proc() -> BD.ReplSignal