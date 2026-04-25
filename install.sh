#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

detect_opener() {
    case "$(uname -s)" in
        Darwin*)          echo "open" ;;
        Linux*)           echo "xdg-open" ;;
        MINGW*|MSYS*|CYGWIN*) echo "cmd.exe /c start" ;;
        *) echo "" ;;
    esac
}

check_claude_desktop() {
    case "$(uname -s)" in
        Darwin*)
            [ -d "/Applications/Claude.app" ] && return 0
            ;;
        Linux*)
            command -v claude-desktop &>/dev/null && return 0
            [ -d "$HOME/.config/claude-desktop" ] && return 0
            ;;
        MINGW*|MSYS*|CYGWIN*)
            [ -d "$LOCALAPPDATA/Programs/claude-desktop" ] 2>/dev/null && return 0
            ;;
    esac
    return 1
}

find_skills() {
    for d in "$SCRIPT_DIR"/*/; do
        [ -f "$d/SKILL.md" ] && basename "$d"
    done
}

create_skill_file() {
    local name="$1"
    local out="$SCRIPT_DIR/${name}.skill"
    rm -f "$out"
    (cd "$SCRIPT_DIR" && zip -rq "$out" "$name/")
    echo "$out"
}

SELECTED_SKILLS=()

select_skills() {
    local skills=("$@")

    echo "" >&2
    echo -e "${BOLD}Available skills:${RESET}" >&2
    echo "" >&2

    for i in "${!skills[@]}"; do
        echo -e "  ${CYAN}$((i + 1))${RESET}  ${skills[$i]}" >&2
    done

    echo "" >&2
    echo -e "  ${CYAN}*${RESET}  Install all" >&2
    echo "" >&2

    local choice
    read -rp "Pick skills (e.g. 1, 1 3 5, or * for all): " choice

    SELECTED_SKILLS=()

    if [[ "$choice" == "*" ]]; then
        SELECTED_SKILLS=("${skills[@]}")
        return
    fi

    for num in $choice; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#skills[@]}" ]; then
            SELECTED_SKILLS+=("${skills[$((num - 1))]}")
        else
            echo -e "${RED}Invalid choice: $num${RESET}" >&2
            exit 1
        fi
    done
}

install_claude_code() {
    local selected=("$@")

    echo ""
    echo -e "${BOLD}Install scope:${RESET}"
    echo ""
    echo -e "  ${CYAN}1${RESET}  Personal — available in all projects (~/.claude/skills/)"
    echo -e "  ${CYAN}2${RESET}  Project  — available only in a specific project"
    echo ""

    local scope
    read -rp "Choose (1 or 2): " scope

    local target_dir

    if [[ "$scope" == "1" ]]; then
        target_dir="$HOME/.claude/skills"
    elif [[ "$scope" == "2" ]]; then
        echo ""
        read -rp "Project path (e.g. /path/to/your/project): " project_path

        if [ ! -d "$project_path" ]; then
            echo -e "${RED}Directory does not exist: $project_path${RESET}"
            exit 1
        fi

        target_dir="$project_path/.claude/skills"
    else
        echo -e "${RED}Invalid choice.${RESET}"
        exit 1
    fi

    mkdir -p "$target_dir"

    echo ""
    echo -e "${BOLD}Installing ${#selected[@]} skill(s) to ${CYAN}${target_dir}${RESET}...${RESET}"
    echo ""

    for skill in "${selected[@]}"; do
        cp -r "$SCRIPT_DIR/$skill" "$target_dir/"
        echo -e "  ${GREEN}✓${RESET} $skill"
    done

    echo ""
    echo -e "${GREEN}${BOLD}Done!${RESET} Skills installed to ${CYAN}${target_dir}${RESET}"
}

install_claude_desktop() {
    local selected=("$@")

    # Check if Claude Desktop is installed
    if ! check_claude_desktop; then
        echo ""
        echo -e "${YELLOW}Claude Desktop not detected on this machine.${RESET}"
        read -rp "Do you have Claude Desktop installed? (y/n): " has_desktop

        if [[ "$has_desktop" != "y" && "$has_desktop" != "Y" ]]; then
            echo ""
            echo -e "You need to install Claude Desktop before continuing."
            echo -e "Download it from ${CYAN}https://claude.ai/download${RESET} or search for \"Claude Desktop\" online."
            echo -e "Once installed, run ${CYAN}bash install.sh${RESET} again."
            exit 0
        fi
    fi

    local opener
    opener="$(detect_opener)"

    if [ -z "$opener" ]; then
        echo -e "${RED}Error: unsupported OS. Supported: macOS, Linux, Windows (Git Bash/MSYS).${RESET}"
        exit 1
    fi

    if ! command -v zip &>/dev/null; then
        echo -e "${RED}Error: 'zip' command not found. Install it and try again.${RESET}"
        exit 1
    fi

    echo ""
    echo -e "${BOLD}Installing ${#selected[@]} skill(s) via Claude Desktop...${RESET}"
    echo ""

    for skill in "${selected[@]}"; do
        echo -e "  Creating ${CYAN}${skill}.skill${RESET}..."
        local file
        file="$(create_skill_file "$skill")"

        echo -e "  Opening in Claude Desktop..."
        $opener "$file" 2>/dev/null || {
            echo -e "  ${YELLOW}Could not open automatically. Open manually:${RESET}"
            echo -e "  ${CYAN}${file}${RESET}"
        }

        echo ""
        echo -e "  ${YELLOW}→ Confirm the install in Claude Desktop, then come back here.${RESET}"
        read -rp "  Press Enter when done (or s to skip)... " confirm

        if [[ "${confirm:-}" == "s" || "${confirm:-}" == "S" ]]; then
            echo -e "  Skipped."
        else
            echo -e "  ${GREEN}✓${RESET} ${skill} installed."
        fi

        rm -f "$file"
        echo ""
    done

    echo -e "${GREEN}${BOLD}Done!${RESET} Skills are ready in Claude Desktop."
}

main() {
    cd "$SCRIPT_DIR"

    local skills=()
    while IFS= read -r s; do
        skills+=("$s")
    done < <(find_skills)

    if [ ${#skills[@]} -eq 0 ]; then
        echo -e "${RED}No skills found.${RESET}"
        exit 1
    fi

    echo ""
    echo -e "${BOLD}Claude Skills Installer${RESET}"
    echo ""
    echo -e "${BOLD}Where do you want to install?${RESET}"
    echo ""
    echo -e "  ${CYAN}1${RESET}  Claude Code"
    echo -e "  ${CYAN}2${RESET}  Claude Desktop"
    echo ""

    local platform
    read -rp "Choose (1 or 2): " platform

    if [[ "$platform" != "1" && "$platform" != "2" ]]; then
        echo -e "${RED}Invalid choice.${RESET}"
        exit 1
    fi

    select_skills "${skills[@]}"

    if [ ${#SELECTED_SKILLS[@]} -eq 0 ]; then
        echo -e "${RED}No skills selected.${RESET}"
        exit 1
    fi

    if [[ "$platform" == "1" ]]; then
        install_claude_code "${SELECTED_SKILLS[@]}"
    else
        install_claude_desktop "${SELECTED_SKILLS[@]}"
    fi
}

main "$@"
