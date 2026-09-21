"""Offline checks for the project's Lua-compatible Luau subset.
Uses liblua5.4 through ctypes: syntax/domain mocks only, NOT the Roblox engine.
Run from the repository root. Real Luau/Rojo checks are in GitHub Actions.
"""
from __future__ import annotations
import ctypes
import ctypes.util
import json
from pathlib import Path

libname = ctypes.util.find_library("lua5.4")
if not libname:
    raise SystemExit("liblua5.4 is required for this optional offline checker. Use the Luau CI instead.")
lua = ctypes.CDLL(libname)
L = ctypes.c_void_p
lua.luaL_newstate.restype = L
lua.luaL_openlibs.argtypes = [L]
lua.luaL_loadfilex.argtypes = [L, ctypes.c_char_p, ctypes.c_char_p]
lua.luaL_loadfilex.restype = ctypes.c_int
lua.luaL_loadstring.argtypes = [L, ctypes.c_char_p]
lua.luaL_loadstring.restype = ctypes.c_int
lua.lua_pcallk.argtypes = [L, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ssize_t, ctypes.c_void_p]
lua.lua_pcallk.restype = ctypes.c_int
lua.lua_tolstring.argtypes = [L, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [L, ctypes.c_int]
lua.lua_close.argtypes = [L]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)

def fail(status: int) -> None:
    if status:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())

try:
    sources = sorted(Path("src").rglob("*.luau"))
    for source in sources:
        fail(lua.luaL_loadfilex(state, str(source).encode(), None))
        lua.lua_settop(state, 0)
    print(f"PASS: {len(sources)} source files parse as the Lua-compatible Luau subset", flush=True)
    config = json.loads(Path("default.project.json").read_text())
    def paths(tree):
        if isinstance(tree, dict):
            for key, value in tree.items():
                if key == "$path":
                    assert Path(value).exists(), f"Missing Rojo path: {value}"
                elif isinstance(value, dict):
                    paths(value)
    paths(config["tree"])
    print("PASS: Rojo JSON and mapped source paths", flush=True)
    boot = b'''package.path = "src/shared/?.luau;" .. package.path
local originalRequire = require
require = function(name)
    if name:sub(1,1) == "." then return assert(loadfile("tests/" .. name .. ".luau"))() end
    return originalRequire(name)
end
dofile("tests/rules.spec.luau")
dofile("tests/data.spec.lua")
'''
    fail(lua.luaL_loadstring(state, boot))
    fail(lua.lua_pcallk(state, 0, 0, 0, 0, None))
finally:
    lua.lua_close(state)
