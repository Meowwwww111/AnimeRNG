"""Offline Lua 5.4 syntax + pure regression runner, NOT a Roblox simulator."""
from pathlib import Path
import ctypes
import ctypes.util
import sys
root = Path(__file__).resolve().parents[1]
libpath = ctypes.util.find_library('lua5.4')
if not libpath:
    raise SystemExit('liblua5.4 is required for this offline check. Use Studio for engine tests.')
lua = ctypes.CDLL(libpath)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate(); lua.luaL_openlibs(state)
def err():
    msg = lua.lua_tolstring(state, -1, None)
    return msg.decode() if msg else 'unknown Lua error'
try:
    paths = sorted((root/'src').rglob('*.luau'))
    for path in paths:
        if lua.luaL_loadfilex(state, str(path).encode(), None):
            raise RuntimeError(f'{path}: {err()}')
        lua.lua_settop(state, 0)
    print(f'Lua-compatible syntax: {len(paths)} files pass', flush=True)
    import os
    os.chdir(root)
    for name in ['tests/presentation.spec.lua', 'tests/visual-build.spec.lua']:
        path = root/name
        if not path.exists():
            raise RuntimeError(f'Missing regression suite: {name}')
        if lua.luaL_loadfilex(state, str(path).encode(), None) or lua.lua_pcallk(state, 0, 0, 0, 0, None):
            raise RuntimeError(f'{name}: {err()}')
finally:
    lua.lua_close(state)
