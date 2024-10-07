# CarmenCargo

A command-line tool that automates the download and organization of course files from Canvas. Students can always have the latest course materials neatly organized on their local machine, making file management effortless. With CarmenCargo, focus on learning while your course files are delivered directly to you!

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
  - [Developer Style Guidelines](#developer-style-guidelines)
- [Individual Contributions](#individual-contributions)

## Installation

1. **Install Ruby:**  
Install ruby v3.3.3. You can check your version with:

    ```bash
    ruby -v
    ```

2. **Install Dependencies:**  
Install all required gems by running the following command:

    ```bash
    bundler install
    ```

3. **Setup Permissions**  
Ensure the script has the correct permissions to execute by running the following command:

    ```bash
    chmod +x carmen_cargo.rb
    ```

4. **Obtain API Token:**  
First, create a copy of the ".env.template" file rename it ".env".  
To utilize CarmenCargo, you must acquire a Canvas REST API access token. Follow these steps:

    1. Log into Carmen.
    2. Click on "Account" in the left-hand navigation bar.
    3. Select "Settings", then "New Access Token".
    4. When prompted, enter a description for the token (e.g., "CarmenCargo").
    5. Click "Generate Token" and copy the displayed token.
    6. Paste this token into your .env file, replacing "CANVAS_TOKEN_SECRET".

## Usage

The CarmenCargo CLI tool has three commands:

1. **LS:**  
List the current files and folders.

    ```bash
    ./carmen_cargo.rb ls
    ```

2. **CD:**  
Change the current directory. Use ".." to move up one level, or "/" to go back to the root.

    ```bash
    ./carmen_cargo.rb cd DIRECTORY
    ```

3. **DOWNLOAD:**  
Download the files in the current course or folder to a specified directory. If no directory is specified, files are downloaded to the default downloads folder. Optionally, specify file types to filter which files are downloaded.

    ```bash
    ./carmen_cargo.rb download [OUTPUT_DIRECTORY] [TYPES]
    ```

To get the descriptions of each command programmatically, you can run CarmenCargo without any arguments:

```bash
./carmen_cargo.rb
```

## Contributing

### Developer Style Guidelines

**Code Style:**

- Use Rubocop and a markdown linter for uniform style checking.
  - The Ruby LSP and markdownlint VSCode extensions are highly recommended.
- Use YARD documentation for all methods and classes.
  - Do not include in-method comments unless absolutely necessary.
- Write idiomatic ruby.
- Employ OOP design principles.

**Git Style**:

- Create a branch for features that will not be completed within a single push.
- Prefix branch names with descriptors of work being done and use dashes as separators.
  - ‘feature/deck-card-classes’, ‘bugfix/’
- Rebase branches instead of merging them.
- Commit messages must have subject line (50 char max) and optional body copy (wrapped at 72 columns) separated by a blank line.
- Subject lines should be capitalized, not end in a period, and be written in an imperative mood.
  - 'Add', 'Implement', 'Fix'
- Body copy must only contain what and why explanations, never how. The how should be in documentation.

**Yard Documenation**:

To view yard documentation in html form:
```bash
yard doc
open doc/index.html
```

## Individual Contributions

**Aysha**:

**Christopher**:

**Nicholas**:

**Sanju**:
