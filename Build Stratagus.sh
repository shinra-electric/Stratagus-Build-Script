#!/usr/bin/env zsh

# ANSI colour codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

# This just gets the location of the folder where the script is run from. 
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

# Introduction
echo "\n${PURPLE}This script is for compiling a native macOS build of:"
echo "${GREEN}War1gus - ${PURPLE}Warcraft: Orcs and Humans${NC}"
echo "${GREEN}Wargus - ${PURPLE}Warcraft II${NC}"
echo "${GREEN}Stargus - ${PURPLE}Starcraft${RED} Starcraft is currently not playable${NC}"

echo "\n${PURPLE}The app can extract the original game data from an official GoG or BNE game installer${NC}"
echo "\n${PURPLE}Note that due to a bug in the source code, the source folder is required when using the data extraction tool${NC}"
echo "${PURPLE}The source code folder can be safely deleted after you have extracted the game data${NC}"

echo "\n${PURPLE}${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required to build${NC}"
echo "${PURPLE}If they are not present you will be prompted to install them${NC}\n"


# Build Stratagus
build_stratagus() {
	echo "${PURPLE}Checking for Homebrew...${NC}"
	if ! command -v brew &> /dev/null; then
		echo -e "${PURPLE}Homebrew not found. Installing Homebrew...${NC}"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile
		eval "$(/opt/homebrew/bin/brew shellenv)"
	else
		echo -e "${PURPLE}Homebrew found. Updating Homebrew...${NC}"
		brew update
	fi
	
	# Install required dependencies
	echo -e "${PURPLE}Checking for Homebrew dependencies...${NC}"
	brew_dependency_check() {
		if [ -d "$(brew --prefix)/opt/$1" ]; then
			echo -e "${GREEN}Found $1. Checking for updates...${NC}"
				brew upgrade $1
		else
			 echo -e "${PURPLE}Did not find $1. Installing...${NC}"
			brew install $1
		fi
	}
	
	# Required Homebrew packages
	deps=( cmake sdl2 sdl2_mixer sdl2_image lua libpng ffmpeg meson ninja )
	
	for dep in $deps[@]
	do 
		brew_dependency_check $dep
	done
	
	echo "${PURPLE}Building Stratagus...${NC}"
	git clone --recurse-submodules https://github.com/Wargus/stratagus
	cd stratagus
	mkdir build && cd build
	cmake .. -DBUILD_VENDORED_LUA=ON && make	# If there is an issue with libs: -DBUILD_VENDORED_MEDIA_LIBS=ON
	cd ../.. 
	export STRATAGUS_INCLUDE_DIR=${PWD}/stratagus/gameheaders
	export STRATAGUS=${PWD}/stratagus/build/stratagus
}

build_war1gus() {
	echo "${PURPLE}Building War1gus...${NC}"
	git clone --recurse-submodules https://github.com/Wargus/war1gus
	cd war1gus
	mkdir build && cd build
	cmake .. -DSTRATAGUS_INCLUDE_DIR=$STRATAGUS_INCLUDE_DIR -DSTRATAGUS=$STRATAGUS && make
	cd ../mac && ./bundle.sh
	cp -a War1gus.app ../../Warcraft.app && cd ../..
	# Optional: Get a Warcraft icon
	curl -o Warcraft.app/Contents/Resources/war1gus.icns https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/b219394bc1718b8d2858b5977a1f4b8b_Warcraft.icns
}

build_wargus() {
	echo "${PURPLE}Building Wargus...${NC}"
	git clone --recurse-submodules https://github.com/Wargus/wargus
	cd wargus
	mkdir build && cd build
	cmake .. -DSTRATAGUS_INCLUDE_DIR=$STRATAGUS_INCLUDE_DIR -DSTRATAGUS=$STRATAGUS && make
	cd ../mac && ./bundle.sh
	cp -a Wargus.app ../../Warcraft\ II.app && cd ../..
	# Optional: Get a Warcraft II icon
	curl -o Warcraft\ II.app/Contents/Resources/wargus.icns https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/f333e393cb0e0d7dffe4c63401aa9abb_Warcraft_2.icns
}

build_stargus() {
	echo "${PURPLE}Building Stargus...${NC}"
	git clone --recurse-submodules https://github.com/Wargus/stargus
	cd stargus
	meson setup -DSTRATAGUS_INCLUDE_DIR=$STRATAGUS_INCLUDE_DIR -DSTRATAGUS_BIN=$STRATAGUS build
	ninja -C build
	cd mac && ./bundle.sh
	cp -a Stargus.app ../../Starcraft.app && cd ../..
	# Optional: Get a Starcraft icon
	curl -o Starcraft.app/Contents/Resources/stargus.icns https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/f47bfeffe33195d6927476760eb66333_Starcraft.icns
}

PS3='Which game would you like to build? '
OPTIONS=(
	"War1gus"
	"Wargus"
	"Stargus"
	"All"
	"Quit")
select opt in $OPTIONS[@]
do
	case $opt in
		"War1gus")
			build_stratagus
			build_war1gus
			break
			;;
		"Wargus")
			build_stratagus
			build_wargus
			break
			;;
		"Stargus")
			build_stratagus
			build_stargus
			break
			;;
		"All")
			build_stratagus
			build_war1gus
			build_wargus
			build_stargus
			break
			;;
		"Quit")
			echo -e "${RED}Quitting${NC}"
			exit 0
			;;
		*) echo "\"$REPLY\" is not one of the options...";;
	esac
done

# Cleanup
# Note: Not removing the source dir because it is required in order for the extractor tool to work due to a bug. 
echo "${PURPLE}Cleaning up...${NC}"
rm -rf stratagus
