# about-tracker
Tool to add and manage metadata for files and directories.

## Setup

Run the following commands in terminal:

```sh
git clone https://github.com/shashkat/about-tracker.git
cd about-tracker
./install.sh
```

Then source your `.zshrc` or `.bashrc` file (as indicated by the output once you have installed successfully) to activate `about-tracker` in your current shell session.

## Getting started

All about-tracker commands are run through `abt`: `abt ls`, `abt cp`, `abt mv`, `abt rm`, `abt modify` and `abt doctor`. Run `abt help` to see the list.

Now you can go to any directory and for any file or directory in that location, add a metadata file using:
`abt modify file.txt` or `abt modify directory`.
You can also add a metadata for the current directory you are in using `abt modify .`. 
If the metadata file is already existing for the entity, the text editor will open letting you edit the existing file.

Now, whenever you run `abt ls` from any directory, if there are any metadata files of entities inside that directory, or of the current directory (which would be located in the parent folder), they will also be shown in the output:

<!-- ![ls output example](docs/ls_example_ss.png) -->
<img src="docs/ls_example_ss.png" align="center" width="500"/> <br>


Whenver you copy or move a file/directory using `abt cp` or `abt mv`, its metadata file if existing will be copied appropriately automatically. If you try to remove a file/directory using `abt rm` whose metadata file already exists, then you will get warning about the removal of the assisting metadata file too, and you have to confirm that action.

**NOTE: Its very important that the user doesn't move/copy the files through something other than the `abt` commands. Because then, the metadata files won't move along with the file.**

If that has happened (for example, a file was moved in Finder or renamed by another program), `abt doctor` finds the metadata files left behind:

```sh
abt doctor               # checks the current directory
abt doctor some/dir      # checks some/dir
abt doctor -r some/dir   # checks some/dir and all its subdirectories
```

It lists every `.about_<name>.md` file whose `<name>` no longer exists in the same directory, and does not change anything. It exits with `0` if nothing is orphaned, `1` if orphaned metadata files were found, and `2` if the argument is not a directory.

### Replacing the standard commands (optional)

Installing about-tracker doesn't change your standard `ls`, `cp`, `mv` and `rm` commands. If you want those commands to always use about-tracker, add the following aliases to your `.zshrc` or `.bashrc` file:

```sh
alias ls='abt ls'
alias cp='abt cp'
alias mv='abt mv'
alias rm='abt rm'
```

You can still run the original command at any time using `command`, for example `command ls`.



## Running the tests

The tests use [bats-core](https://github.com/bats-core/bats-core) (`brew install bats-core`, or see its install docs). It is only needed for running the tests, not for using about-tracker. From the repo root, run:

```sh
bats tests/          # all tests
bats tests/cp.bats   # tests for a single command
```

The tests always run against the code in this repo (not an installed copy). Every test works in its own temporary copy of `tests/fixtures`, and `install.bats` points `HOME` at a temporary directory, so running the tests never changes the fixtures or your real shell config.
