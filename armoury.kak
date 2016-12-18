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
# def armoury-equip %{
#   mawww/kak-ycmd
# # add any packages from github in the same way
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
 echo ${XDG_CONFIG_HOME:-$HOME/.config}/kak/autoload
}

decl int _install_current_line 0

def armoury-update -docstring 'Update all the equipped armoury packages' %{ %sh{
  output=$(mktemp -d -t kak-armoury-update.XXXXXXXX)/fifo
  mkfifo $output

  for package in $kak_opt_armourydir/*; do
    if [ -d "$package" ]; then
      (echo "Updating $package" > $output 2>&1) > /dev/null 2>&1 < /dev/null &
      (cd "$package" && git pull origin master > $output 2>&1) > /dev/null 2>&1 < /dev/null &
    fi
  done

  printf %s\\n "try %{
    edit! -fifo $output -scroll *armoury*
    set buffer filetype text
    set buffer _install_current_line 0
    hook -group fifo buffer BufCloseFifo .* %{
      nop %sh{ rm -r $(dirname $output) }
      rmhooks buffer fifo
    }
  }"
} }

def armoury-clean -docstring 'Remove unused packages' %{ %sh{
  cache=$kak_opt_armourydir/.armoury_cache
  for package in $kak_opt_armourydir; do
    repo=$kak_opt_armourydir/$package
    if grep -Fxqv "$repo" $cache; then
      rm -r $repo
    fi
  done
} }

def armoury-equip -hidden -params 1 -docstring 'Fetch and load all equipped packages' %{
  %sh{
    mkdir -p $kak_opt_armourydir 
    cache=$kak_opt_armourydir/.armoury_cache
    output=$(mktemp -d -t kak-armoury-install.XXXXXXXX)/fifo
    mkfifo $output

    while read -r package; do
      repo=$kak_opt_armourydir/$(basename "$package")
      if [ ! -d $repo ]; then
        (echo "Installing $package" > $output 2>&1) > /dev/null 2>&1 < /dev/null &
        (git clone --depth=1 git@github.com:$package $repo > $output 2>&1) > /dev/null 2>&1 < /dev/null &
        echo $repo >> $cache
      fi
    done <<< "$1"

    printf %s\\n "try %{
      edit! -fifo $output -scroll *armoury*
      set buffer filetype text
      set buffer _install_current_line 0
      hook -group fifo buffer BufCloseFifo .* %{
        nop %sh{ rm -r $(dirname $output) }
        rmhooks buffer fifo
      }
    }"
  }

  armoury-autoload
}

def armoury-autoload -hidden %{ %sh{
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
