--[[ license

  pkgit - package it!

  Copyright (C) 2026 dacctal
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.

]]

--[[ introduction

  this is the pkgit configuration template.
  every configuration file is written in lua,
  the embeddable high-level programming language.

  for info on how to write lua, check out
  this website for documentation:
  https://www.lua.org/pil/contents.html
  
  all variables that are
  set by default are designed to
  work out of the box. be sure to
  keep the global variables global,
  as they need to be global in
  order for them to work with
  each other effectively.

  `local install_directories`, for
  example, will not work well in
  most cases.

]]

--[[ prefix

  the prefix variable is necessary
  for custom install paths, which
  bldit maintainers should be
  respecting with their recipes.

  if you want to install packages
  without root, it's easist to
  create a home variable and
  append that to your prefix.

]]
local home = os.getenv("HOME")
prefix = home.."/.local"

--[[ install_directories

  install_directories is an essential
  table that pkgit needs in order to
  function. this is how it determines
  where you install your packages to.

  it's most convenient when combined
  with `prefix` which allows for a
  more dynamic definition of your
  install directories.

]]
install_directories = {
  bin	    = prefix.."/bin",         -- binaries (executables)
  -- the value of `bin` should also be set in your shell's $PATH
  include	= prefix.."/include",     -- C headers
  lib	    = prefix.."/lib",         -- libraries (shared objects)
  src     = prefix.."/share/pkgit", -- source code
}

--[[ repositories

  this is where all your repos need to
  end up. every repo has a name, which
  can be written out normally
  (`name = {...}`), or for some repos,
  it might be necessary to wrap it in
  quotes (`["name"] = {...}`).
  that name can be used in a pkgit
  command to be installed.
  ( `pkgit --install [repo]` )

  each of these repos must be structured
  as a lua table. the structure is
  demonstrated below.

]]
repositories = {
  pkgit = {
    url = "https://git.symlinx.net/pkgit",
    --[[ repo example

      no targets table or dependencies are actually needed in
      this specific case, pkgit has a bldit.lua which guarantees
      that it will compile & install (as long as `install_directories`
      and `prefix` are set up).

      if you do make a targets table here, it will take priority
      over the bldit.lua in the repo, and your build system
      autodetection config ( `build_systems = {...}` )

      more about `targets` in the global `build_systems` table.

    ]]
    --dependencies = {
    --  name = {
    --    url = {...},
    --    version = "...",
    --    target = "...",
    --  },
    --},
    --targets = {
    --  default = {
    --    build = function()
    --      return os.execute("make")
    --
    --      -- ^ make sure to return the exit code of os.execute ^ --
    --
    --    end,
    --    install = function()
    --      return os.execute("make install PREFIX="..prefix)
    --    end,
    --    uninstall = function()
    --      return os.execute("make uninstall PREFIX="..prefix)
    --    end,
    --  }
    --}
  },
}

--[[ build_systems

  this table contains all of the automatic
  build system detection necessary for pkgit
  to work without bldit.lua or `repositories = {...}`.

  this works by creating a table named after the
  filename associated with the build system that
  is found in the root directory of a package.

  by associating a filename with a build system,
  pkgit can dynamically compile and install any
  package, given that they use the build system
  according to the standard (or otherwise
  generally popular) usage guidelines.

]]
build_systems = {
  ["Makefile"] = {
    --[[ targets

      briefly mentioned above in `repositories`,
      the `targets` subtable is a standard that's
      consistent across all the different methods
      to build a package using pkgit; meaning
      you can write the same `targets` subtable
      in `repositories.<pkg>`, `bldit.lua`, and
      right here in `build_systems`.

      this table comes with two templates;
      `default` and `quiet`. the first is pretty
      self-explanatory; this is what you'd define
      as the default intended behavior of the
      build system.

      `quiet` is similar to `default`, in the sense
      that it inherits the default intended behavior,
      except that it does so while printing nothing
      to the terminal. instead, ideally, it would
      output its logs to a temporary file accessible
      by the user running the command.
      
      this is why the default logs in this example
      are located in `/tmp` and not `/var/log`,
      because the user typically has full access to
      `/tmp`, and normally not `/var/log`.

    ]]
    targets = {
      default = {
        build = function()
          return os.execute("make")
        end,
        install = function()
          return os.execute("make install PREFIX="..prefix)
        end,
        uninstall = function()
          return os.execute("make uninstall PREFIX="..prefix)
        end,
      },
      quiet = {
        build = function()
          return os.execute("make &>/tmp/pkgit_build.log")
        end,
        install = function()
          return os.execute("make install PREFIX="..prefix.." &>/tmp/pkgit_build.log")
        end,
        uninstall = function()
          return os.execute("make uninstall PREFIX="..prefix.." &>/tmp/pkgit_build.log")
        end,
      },
    }
  },
  ["meson.build"] = {
    targets = {
      default = {
        build = function()
          return os.execute("meson setup build --prefix "..prefix.." && meson compile -C build")
        end,
        install = function()
          return os.execute("cd build && meson install")
        end,
        uninstall = function()
          return os.execute("cd build && ninja uninstall")
        end,
      },
      quiet = {
        build = function()
          return os.execute("meson setup build --prefix "..prefix.." &>/tmp/pkgit_build.log && meson compile -C build &>/tmp/pkgit_build.log")
        end,
        install = function()
          return os.execute("cd build && meson install &>/tmp/pkgit_build.log")
        end,
        uninstall = function()
          return os.execute("cd build && ninja uninstall &>/tmp/pkgit_build.log")
        end,
      },
    }
  },
  ["CMakeLists.txt"] = {
    targets = {
      default = {
        build = function()
          return os.execute("cmake -B build && cmake --build build")
        end,
        install = function()
          return os.execute("cmake --build . --target install")
        end,
        uninstall = function()
          return os.execute("xargs rm < install_manifest.txt")
        end,
      },
      quiet = {
        build = function()
          return os.execute("cmake -B build &>/tmp/pkgit_build.log && cmake --build build &>/tmp/pkgit_build.log")
        end,
        install = function()
          return os.execute("cmake --build . --target install &>/tmp/pkgit_build.log")
        end,
        uninstall = function()
          return os.execute("xargs rm < install_manifest.txt &>/tmp/pkgit_build.log")
        end,
      },
    }
  },
}
