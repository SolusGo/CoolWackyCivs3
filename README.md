# Cool Wacky Civs 3

![A railway crosses a ravine beside a glasshouse and an amethyst cathedral](docs/artwork/cover.jpg)

26 human-only civilizations for Civilization V: Brave New World with Windows **standalone Community Patch v151**. This pack runs independently.

**Start here** · [Civilization gallery](docs/Civilizations.md) · [Pack guide](Wacky3/README.md) · [Installation](Wacky3/README.md#installation) · [Build and validation](Wacky3/README.md#build-in-modbuddy)

**More packs** · [Cool Wacky Civs](https://github.com/SolusGo/CoolWackyCivs) · [Cool Wacky Civs 2](https://github.com/SolusGo/CoolWackyCivs2)

## Build with ModBuddy

Open [CoolWackyCivs3.civ5sln](CoolWackyCivs3.civ5sln) in **ModBuddy** from the Civilization V SDK. Set the Civilization V game and user paths in ModBuddy, choose **Default**, then **Build → Build Solution** (F6). This packages the mod and deploys it to your configured `MODS` folder.

The solution uses the [Wacky3 project file](Wacky3/CoolWackyCivs3.civ5proj).

The SDK package appears at `Packages/Cool Wacky Civs 3 (v 1).civ5mod`; intermediate files are in `Build/Cool Wacky Civs 3`. These folders are beside this README. Python is only required to regenerate content or update the project inventory after adding/removing files: run `python tools/build_mod.py` from `Wacky3`, then reload the project.
