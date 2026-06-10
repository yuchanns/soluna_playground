local lm = require "luamake"
local platform = require "bee.platform"

lm.basedir = lm:path "."
lm.bindir = "."
lm.osbindir = "."
lm.rootdir = lm.basedir

lm:conf {
	c = "c11",
	flags = {
		lm.mode ~= "debug" and "-O2",
	},
	msvc = {
		flags = {
			"-W3",
			"-utf-8",
			"/wd4244",
			"/wd4267",
			"/wd4996",
		},
		defines = {
			"_CRT_SECURE_NO_WARNINGS",
			"_CRT_NONSTDC_NO_DEPRECATE",
			"_CRT_SECURE_NO_DEPRECATE",
		},
	},
	gcc = {
		flags = {
			"-Wall",
			"-fPIC",
		},
	},
	clang = {
		flags = {
			"-Wall",
			"-fPIC",
		},
	},
}

local function shdc_plat()
	if lm.os == "windows" then
		return "win32"
	end
	if lm.os == "linux" then
		return platform.Arch == "arm64" and "linux_arm64" or "linux"
	end
	if lm.os == "macos" then
		return platform.Arch == "arm64" and "osx_arm64" or "osx"
	end
	return "unknown"
end

local shdc_paths = {
	windows = "$PATH/$NAME.exe",
	macos = "$PATH/$NAME",
	linux = "$PATH/$NAME",
}

local shdc = shdc_paths[lm.os]:gsub("%$(%u+)", {
	PATH = tostring(lm.basedir / "soluna/bin/sokol-tools-bin/bin" / shdc_plat()),
	NAME = "sokol-shdc",
})

local function detect_emcc()
	if lm.compiler == "emcc" then
		return true
	end
	return type(lm.cc) == "string" and lm.cc:find("emcc", 1, true) ~= nil
end

local function shader_lang()
	if detect_emcc() then
		return "wgsl"
	end
	if lm.os == "windows" then
		return "hlsl4"
	end
	if lm.os == "macos" then
		return "metal_macos"
	end
	if lm.os == "linux" then
		return "glsl430"
	end
	return "unknown"
end

local function compile_shader(src, name)
	local dep = name .. "_shader"
	local target = lm.builddir .. "/" .. name
	lm:runlua(dep) {
		script = lm.basedir .. "/soluna/clibs/soluna/shader2c.lua",
		inputs = lm.basedir .. "/" .. src,
		outputs = lm.basedir .. "/" .. target,
		args = {
			shdc,
			"$in",
			"$out",
			shader_lang(),
		},
	}
	return dep
end

local rounded_rect_shader = compile_shader("src/rounded_rect.glsl", "rounded_rect.glsl.h")

lm:dll "playground" {
	sources = {
		"soluna/extlua/extlua.c",
		"soluna/extlua/sokolapi.c",
		"soluna/extlua/solunaapi.c",
		"src/*.c",
	},
	objdeps = {
		rounded_rect_shader,
	},
	includes = {
		"soluna/3rd/lua",
		"soluna/3rd",
		"soluna/extlua",
		"build",
	},
}

lm:default "playground"
