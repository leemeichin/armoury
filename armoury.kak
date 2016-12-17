# Armoury
# -------
# Package manager for Kakoune (http://kakoune.org)
#
# Usage:
# ------ 
# 
# Place somewhere inside your kakrc, making sure that armoury is already
# loaded.
#
# ```
# def armoury-packages %{
#   equip mawww/kak-ycmd
# # equip any packages from github in the same way
# }
#
# hook global KakBegin .* %{armoury-init}
# ```
#
# Updating Packages:
# ------------------
#
# Call :armoury-update to fetch the latest versio of all packages.
#
# Configuration:
# --------------
#
# Packages are installed in $XDG_CONFIG_HOME/kak/armoury by default.
# For most users this is the same as ~/.config/kak/armoury.


decl -hidden str armourydir %sh{
 ${XDG_CONFIG_HOME:-$HOME}/kak/armoury
}

def -hidden -allow-override armoury-packages ''

def -hidden -params 1 equip %sh{
  repo=%{kak_opt_armourydir}/%arg{1}
  
  if [ ! -d "$repo" ]; then
    git clone git@github.com:%arg{1} "$repo"
  fi
}

def armoury-update -docstring 'Update all the equipped armoury packages' %sh{
  for repo in %{kak_opt_armourydir}/*; do
    if [ -d "$repo" ]; then
      (cd "$repo" && git pull --rebase origin master)
    fi
  done
}

def armoury-init -docstring 'Fetch and load all equipped packages' %{
  %sh{ mkdir -p %{kak_opt_armourydir} }
  armoury-packages # install any missing packages
  armoury-autoload
}

def -hidden armoury-autoload %sh{
  autoload () {
    local dir=$1

    for kakfile in ${dir}/*.kak; do
      if [ -f "$kakfile" ]; then
        echo "try %{ source '${kakfile}' } catch %{ echo -debug Autoload: could not load '${kakfile}' }";
      fi
    done

    for subdir in ${dir}/*; do
      if [ -d "${subdir}" ]; then
        autoload "$subdir"
      fi
    done
  }

  autoload %{kak_opt_armourydir}
}
