# about-tracker
Tool to add and manage metadata for files and directories.

## Why about-tracker?

A file or directory name is often the only place to record what something is, so names end up carrying far more than they should:

```
results_final_v2_fixed_lr0.001_USE_THIS.csv
experiment_3_(same as 2 but new seed, broken - dont use)/
```

Names like these are hard to read, awkward to type, and still leave out the context that matters most: why the file exists, where it came from, what state it is in, and what you should do with it. Putting spaces, brackets or quotes in them to fit more in only makes them harder to use in a terminal. Writing that context in a separate notes file doesn't help much either: nobody opens it, and it goes out of date as soon as files are renamed or moved.

about-tracker lets names stay short and puts the description next to the file instead:

- **Short names, full descriptions.** `abt modify results.csv` opens a small markdown file (`.about_results.csv.md`) in your editor, where you can write as much as you want.
- **The descriptions are shown where you already look.** `abt ls` prints the normal `ls` output followed by the description of the directory and of every entry in it:

  ```
  $ abt ls
  experiment_2  experiment_3  results.csv

  ───────────────about────────────────────
  ▸ project/ (this directory): Effect of learning rate on model accuracy
  ▸ experiment_3: same as experiment_2 but with a new seed. Broken, don't use
  ▸ results.csv: final results (lr=0.001). Use this one for the paper
  ```

    ![ls output example](docs/ls_example_ss.png)
    <!-- <img src="docs/ls_example_ss.png" align="center" width="500"/> <br> -->

- **Descriptions follow their files.** `abt mv`, `abt cp` and `abt rm` move, copy and remove the description along with the file, and `abt doctor` finds descriptions that were left behind when a file was moved some other way.
- **Plain files, no lock-in.** Descriptions are ordinary hidden markdown files, so they can be read without about-tracker, committed to git and synced like any other file.

## Setup

Run the following commands in terminal:

```sh
git clone https://github.com/shashkat/about-tracker.git
cd about-tracker
./install.sh
```

Then source your `.zshrc` or `.bashrc` file (as indicated by the output once you have installed successfully) to activate `about-tracker` in your current shell session.

### Replacing the standard commands (optional but recommended)

Installing about-tracker doesn't change your standard `ls`, `cp`, `mv` and `rm` commands. If you want those commands to always use about-tracker, add the following aliases to your `.zshrc` or `.bashrc` file:

```sh
alias ls='abt ls'
alias cp='abt cp'
alias mv='abt mv'
alias rm='abt rm'
```

You can still run the original command at any time using `command`, for example `command ls`.

## Getting started

All about-tracker commands are run through `abt`: `abt ls`, `abt cp`, `abt mv`, `abt rm`, `abt modify` and `abt doctor`. Run `abt help` for an overview of all commands, or `abt help <command>` (e.g. `abt help mv`) for details on one command.

Now you can go to any directory and for any file or directory in that location, add a metadata file using:
`abt modify file.txt` or `abt modify directory`.
You can also add a metadata for the current directory you are in using `abt modify .`. 
If the metadata file is already existing for the entity, the text editor will open letting you edit the existing file.

Now, whenever you run `abt ls` from any directory, if there are any metadata files of entities inside that directory, or of the current directory (which would be located in the parent folder), they will also be shown in the output:

Whenver you copy or move a file/directory using `abt cp` or `abt mv`, its metadata file if existing will be copied appropriately automatically. If you try to remove a file/directory using `abt rm` whose metadata file already exists, then you will get warning about the removal of the assisting metadata file too, and you have to confirm that action.

<img src="docs/demo.gif" align="center" width="800"/> <br>

**NOTE: If the user moves/copies the files through something other than the `abt` commands, then the metadata files won't move along with the file.**

If that has happened (for example, a file was moved in Finder or renamed by another program), `abt doctor` finds the metadata files left behind:

```sh
abt doctor               # checks the current directory
abt doctor some/dir      # checks some/dir
abt doctor -r some/dir   # checks some/dir and all its subdirectories
```

It lists every `.about_<name>.md` file whose `<name>` no longer exists in the same directory, and does not change anything. It exits with `0` if nothing is orphaned, `1` if orphaned metadata files were found, and `2` if the argument is not a directory.

## Uninstalling

From the cloned repo (or from `~/.local/share/about-tracker`), run:

```sh
./uninstall.sh
```

This removes the about-tracker block from your `.zshrc` and `.bashrc`, and deletes `~/.local/share/about-tracker`. Your `.about_<name>.md` metadata files are not touched. If you added aliases like `alias ls='abt ls'`, the script lists them so you can remove them, since they would stop working. Open a new terminal afterwards, as the current one still has `abt` on its `PATH`.

## Running the tests

The tests use [bats-core](https://github.com/bats-core/bats-core) (`brew install bats-core`, or see its install docs). It is only needed for running the tests, not for using about-tracker. From the repo root, run:

```sh
bats tests/          # all tests
bats tests/cp.bats   # tests for a single command
```

The tests always run against the code in this repo (not an installed copy). Every test works in its own temporary copy of `tests/fixtures`, and `install.bats`/`uninstall.bats` point `HOME` at a temporary directory, so running the tests never changes the fixtures or your real shell config.
