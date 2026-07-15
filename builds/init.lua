local log_file = "/tmp/pkgit_build.log"

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function quiet(command)
	return "(" .. command .. ") > " .. shell_quote(log_file) .. " 2>&1"
end

local function with_path(command)
	local path = install_directories.bin .. ":" .. (os.getenv("PATH") or "")
	return "PATH=" .. shell_quote(path) .. " " .. command
end

local function ensure_install_dirs()
	return table.concat({
		"mkdir -p",
		shell_quote(install_directories.bin),
		shell_quote(install_directories.include),
		shell_quote(install_directories.lib),
		shell_quote(install_directories.src),
	}, " ")
end

local function run(command)
	return os.execute(with_path(command))
end

local function run_quiet(command)
	return os.execute(quiet(with_path(command)))
end

local function run_install(command)
	return run(ensure_install_dirs() .. " && " .. command)
end

local function run_install_quiet(command)
	return run_quiet(ensure_install_dirs() .. " && " .. command)
end

local function path_contains(directory)
	local path = os.getenv("PATH") or ""
	for entry in path:gmatch("[^:]+") do
		if entry == directory then
			return true
		end
	end

	return false
end

local function post_install()
	if path_contains(install_directories.bin) then
		return true
	end

	io.stderr:write(
		"[pkgit] [WARN] add "
			.. install_directories.bin
			.. " to PATH, then run: source ~/.zshrc\n"
	)
	return true
end

local function cargo_package_name()
	local in_package = false

	for line in io.lines("Cargo.toml") do
		local section = line:match("^%s*%[([^%]]+)%]")
		if section then
			in_package = section == "package"
		elseif in_package then
			local name = line:match('^%s*name%s*=%s*"([^"]+)"')
			if name then
				return name
			end
		end
	end

	return nil
end

local function cargo_uninstall_command()
	local name = cargo_package_name()
	if not name then
		return "false"
	end

	return "cargo uninstall --root " .. shell_quote(prefix) .. " " .. shell_quote(name)
end

return {
	["Cargo.toml"] = {
		targets = {
			default = {
				build = function()
					return run("cargo build --release")
				end,
				install = function()
					return run_install("cargo install --path . --root " .. shell_quote(prefix) .. " --force")
				end,
				post_install = post_install,
				uninstall = function()
					return run(cargo_uninstall_command())
				end,
			},
			quiet = {
				build = function()
					return run_quiet("cargo build --release")
				end,
				install = function()
					return run_install_quiet("cargo install --path . --root " .. shell_quote(prefix) .. " --force")
				end,
				post_install = post_install,
				uninstall = function()
					return run_quiet(cargo_uninstall_command())
				end,
			},
		},
	},

	["Makefile"] = {
		targets = {
			default = {
				build = function()
					return run("make")
				end,
				install = function()
					return run_install("make install PREFIX=" .. shell_quote(prefix))
				end,
				post_install = post_install,
				uninstall = function()
					return run("make uninstall PREFIX=" .. shell_quote(prefix))
				end,
			},
			quiet = {
				build = function()
					return run_quiet("make")
				end,
				install = function()
					return run_install_quiet("make install PREFIX=" .. shell_quote(prefix))
				end,
				post_install = post_install,
				uninstall = function()
					return run_quiet("make uninstall PREFIX=" .. shell_quote(prefix))
				end,
			},
		},
	},

	["configure"] = {
		targets = {
			default = {
				build = function()
					return run("./configure --prefix=" .. shell_quote(prefix) .. " && make")
				end,
				install = function()
					return run_install("make install")
				end,
				post_install = post_install,
				uninstall = function()
					return run("make uninstall")
				end,
			},
			quiet = {
				build = function()
					return run_quiet("./configure --prefix=" .. shell_quote(prefix) .. " && make")
				end,
				install = function()
					return run_install_quiet("make install")
				end,
				post_install = post_install,
				uninstall = function()
					return run_quiet("make uninstall")
				end,
			},
		},
	},

	["meson.build"] = {
		targets = {
			default = {
				build = function()
					return run("meson setup build --prefix " .. shell_quote(prefix) .. " && meson compile -C build")
				end,
				install = function()
					return run_install("meson install -C build")
				end,
				post_install = post_install,
				uninstall = function()
					return run("ninja -C build uninstall")
				end,
			},
			quiet = {
				build = function()
					return run_quiet("meson setup build --prefix " .. shell_quote(prefix) .. " && meson compile -C build")
				end,
				install = function()
					return run_install_quiet("meson install -C build")
				end,
				post_install = post_install,
				uninstall = function()
					return run_quiet("ninja -C build uninstall")
				end,
			},
		},
	},

	["CMakeLists.txt"] = {
		targets = {
			default = {
				build = function()
					return run("cmake -S . -B build -DCMAKE_INSTALL_PREFIX=" .. shell_quote(prefix) .. " && cmake --build build")
				end,
				install = function()
					return run_install("cmake --install build")
				end,
				post_install = post_install,
				uninstall = function()
					return run("test -f build/install_manifest.txt && xargs rm < build/install_manifest.txt")
				end,
			},
			quiet = {
				build = function()
					return run_quiet("cmake -S . -B build -DCMAKE_INSTALL_PREFIX=" .. shell_quote(prefix) .. " && cmake --build build")
				end,
				install = function()
					return run_install_quiet("cmake --install build")
				end,
				post_install = post_install,
				uninstall = function()
					return run_quiet("test -f build/install_manifest.txt && xargs rm < build/install_manifest.txt")
				end,
			},
		},
	},
}
