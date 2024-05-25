# Setup-linux

This repository contains a script to set up Linux's settings with all the necessary tools and packages.

## Installed Software and Tools

This table summarizes the key software and tools installed through the setup script, along with a brief description of each.

| Category                       | Software/Tools                                               | Description |
|--------------------------------|--------------------------------------------------------------|-------------|
| **System Tools**               | git, curl, wget, vim, zsh, tmux, htop, tree, net-tools, zip, openssh-server | Common utilities for file management, shell operations, and network management. |
| **Programming Languages**      | PHP, Node.js, Python, Java | Core languages for backend development, scripting, and system programming. |
| **Database Tools**             | libpq-dev                                                    | Development files for PostgreSQL, enabling database interactions. |
| **Web Development**            | npm, yarn, Composer                                          | Package managers that facilitate modern web development workflows. |
| **Web Browsers**               | Google Chrome, Firefox                                       | Essential for testing and development across multiple browsers. |
| **Version Control**            | git                                                          | Fundamental for managing code changes in collaborative and individual projects. |
| **IDEs and Editors**           | JetBrains Toolbox                                            | Manages JetBrains IDEs, supporting various programming environments. |
| **Server Tools**               | openssh-server, apache2 (disabled)                           | Tools for remote server management and web servers, with Apache2 disabled by default. |
| **Image Optimization**         | jpegoptim, optipng, webp                                     | Tools for optimizing images, crucial for enhancing web performance. |
| **Security Tools**             | snapd, libnss3-tools                                         | Manage package installations and enhance network security. |
| **Command-Line Environments**  | oh-my-zsh, Powerlevel10k                                     | Enhancements for the Zsh shell, improving usability and aesthetics. |
| **System Libraries**           | Multiple dev libraries (e.g., libicu-dev, libpng-dev)        | Support a wide range of software development tasks, including image processing and internationalization. |

## How to use

1. Clone this repository:

    ```bash
    git clone https://github.com/yourusername/setup-linux.git
    ```

2. Navigate to the repository directory:

    ```bash
    cd setup-linux
    ```

3. Make the script executable (if it is not already):

    ```bash
    chmod +x main.sh
    ```

4. Run the setup script:

    ```bash
    ./main.sh
    ```

## Customization and Version Selection

The script includes options to select specific versions of PHP, Node.js, Python, and Java. When prompted during the script execution, enter the desired version numbers separated by commas.

### Example:

```text
Currently installed Node.js versions: none
Available Node.js versions to install:
22
21
20
19
18
Enter the Node.js versions you want to install : 20, 18
