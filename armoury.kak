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
# def armoury-init %{
#   equip mawww/kak-ycmd
# # equip any packages from github in the same way
# }
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
 echo ${XDG_CONFIG_HOME:-$HOME/.config}/kak/armoury
}

def -hidden -params 1 equip %{ %sh{
  repo=$kak_opt_armourydir/$(basename $1)
  
  if [ ! -d "$repo" ]; then
    git clone git@github.com:$1 "$repo"
  fi
} }

def armoury-update -docstring 'Update all the equipped armoury packages' %{ %sh{
  for repo in $kak_opt_armourydir/*; do
    if [ -d "$repo" ]; then
      (cd "$repo" && git pull --rebase origin master)
    fi
  done
} }

def -hidden -params 1 -docstring 'Fetch and load all equipped packages' armoury-init %{
  %sh{ 
    mkdir -p $kak_opt_armourydir 

    while read -r package; do
      echo "try %{ ${package} } catch %{ echo -debug Init: could not '${package}' }"
    done <<< "$1"
  }

  armoury-autoload
}

def -hidden armoury-autoload %{ %sh{
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

  autoload $kak_opt_armourydir
} }
