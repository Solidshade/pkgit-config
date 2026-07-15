local home = os.getenv("HOME")
prefix = home .. "/.local"
install_directories = {
	bin = prefix .. "/bin",
	include = prefix .. "/include",
	lib = prefix .. "/lib",
	src = prefix .. "/share/pkgit",
}

repositories = require("repos.init")
build_systems = require("builds.init")
