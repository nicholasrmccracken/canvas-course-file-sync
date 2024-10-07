# CarmenCargo

A command-line tool that automates the download and organization of course files from Canvas. Students can always have the latest course materials neatly organized on their local machine, making file management effortless. With CarmenCargo, focus on learning while your course files are delivered directly to you!

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
  - [Yard Documentation](#yard-documenation)
  - [Developer Style Guidelines](#developer-style-guidelines)
- [Testing](#testing)
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
List the current files and folders, with folder ids for each folder.

    ```bash
    ./carmen_cargo.rb ls
    ```

2. **CD:**  
Change the current directory. Use ".." to move up one level, or "/" to go back to the root, or a folder id value to move into that folder.

    ```bash
    ./carmen_cargo.rb cd DIRECTORY
    ```

3. **DOWNLOAD:**  
Download the files in the current course or folder to a specified directory. If no directory is specified, files are downloaded to the default downloads folder. Optionally, specify file extensions to filter which files are downloaded.

    ```bash
    ./carmen_cargo.rb download [OUTPUT_DIRECTORY] [EXTENSIONS]
    ```

View the descriptions of each command in the terminal by running CarmenCargo without any arguments:

```bash
./carmen_cargo.rb
```

## Contributing

### Yard Documenation

View the yard documentation in html form by running the following commands:

```bash
yard doc
open doc/index.html
```

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

## Testing

Test the validity of your Canvas REST API access token by running the following command:

```bash
ruby lib/data_fetcher.rb
```

## Individual Contributions

**Aysha:**  

-

**Christopher:**  

- Created initial cli class to handle initial boot up and user check. Mapped user class and ID values displaying them to the user as initial directory.
- Created user class for token checking and verification. Has some unused methods for displaying user information that was fased out in the final project. Currently used when no token can be found in the .env file. It takes the user to a sub method where they can enter a CANVAS_TOKEN in the command line. The class will save it to the .env for later use.
- Reformatted output and error messages for organization and ease of reading: success tags are greeen, files are blue, locations (partial or final) are teal
- Did small ammounts of error testing after largest merge and program integration. There was a point where we had a full program but it was (more or less) split into two halves. After integration there were some errors we all contributed to fixing
- Inital project idea: Before we decided what our final project would be, we had an idea to make a flashcard generator. Before it was scrapped some code was written. The User class still contains some reminents of the old project but some has also been deleted.

**Nicholas:**  

- Implemented APIClient class
- Implemented DataFetcher class
- Refactored CLI to connected frontend and backend with Thor commands
- Implemented StateManagement class with json file
- Added additional features like extension filtering and defaulting to downloads folder when downloading
- Structured README

**Sanju:**  

- Contributions mostly made in old version
- Logic for handling API rate limiting by implementing retry logic
- Cache file metadata logic
- In CLI class, implemented logic to show user what files have been fetched
- Updated user token and validate token access logic in CLI class
- Logic to zip fetched files
- Implemented error handling forf API calls in user class
- Added tasks to be implemented for old versions of CLI and User classes in design document
