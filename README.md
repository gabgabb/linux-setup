# Setup-linux

This repository contains a script to set up linux's settings with all the necessary tools and packages.

## Installed Software and Tools

This table summarizes the key software and tools installed through the setup script, along with a brief description of each.

| Category                       | Software/Tools                                                   | Description |
|--------------------------------|------------------------------------------------------------------|-------------|
| **System Tools**               | git, curl, wget, vim, zsh, tmux, htop, tree, net-tools, zip, openssh-server | Common utilities for file management, shell operations, and network management. |
| **Programming Languages**      | PHP (7.4, 8.0, 8.1), Node.js, Python (2.7, 3.6-3.10), Java (OpenJDK 8, 11, 17) | Core languages for backend development, scripting, and system programming. |
| **Database Tools**             | libpq-dev                                                        | Development files for PostgreSQL, enabling database interactions. |
| **Web Development**            | npm, yarn, Composer                                              | Package managers that facilitate modern web development workflows. |
| **Web Browsers**               | Google Chrome, Firefox                                           | Essential for testing and development across multiple browsers. |
| **Version Control**            | git                                                              | Fundamental for managing code changes in collaborative and individual projects. |
| **IDEs and Editors**           | JetBrains Toolbox                                                | Manages JetBrains IDEs, supporting various programming environments. |
| **Server Tools**               | openssh-server, apache2 (disabled)                               | Tools for remote server management and web servers, with Apache2 disabled by default. |
| **Image Optimization**         | jpegoptim, optipng, webp                                         | Tools for optimizing images, crucial for enhancing web performance. |
| **Security Tools**             | snapd, libnss3-tools                                             | Manage package installations and enhance network security. |
| **Command-Line Environments**  | oh-my-zsh, Powerlevel10k                                         | Enhancements for the Zsh shell, improving usability and aesthetics. |
| **System Libraries**           | Multiple dev libraries (e.g., libicu-dev, libpng-dev)            | Support a wide range of software development tasks, including image processing and internationalization. |

## How to use

Clone this repository and run 

``` bash
cd setup-linux
sh main.sh
```
