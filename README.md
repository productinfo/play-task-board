shinobiplay: Task Board (Objective-C)
=====================

This project uses the **shinobiessentials** flow layout to create a task board (pin board) where items can be dragged between columns.

![Screenshot](screenshot.png?raw=true)

Cloning or downloading the project
------------------
This project uses git submodules to include some code common to various **shinobiplay** projects.

If you clone this project using GitHub Desktop, the submodules should be checked out automatically for you. Otherwise you can fetch the submodules on the command line using:

    $ git submodule update --init --recursive
    
If you [download the zip](../../archive/master.zip) rather than cloning the project, you'll also have to download the submodule zips:

* Download [play-utils](https://github.com/ShinobiControls/play-utils/archive/master.zip) and extract its contents into the **PinBoard/ShinobiPlayUtils/** directory.

Your directory structure should end up looking something like this:

    .
    └── PinBoard
        ├── PinBoard
        ├── PinBoard.xcodeproj
        └── ShinobiPlayUtils
            └── ShinobiPlayUtils
                ├── ShinobiPlayUtils
                └── ShinobiPlayUtils.xcodeproj
                
Building the project
------------------

In order to build this project you'll need a copy of **shinobiessentials**. If you don't have it yet, you can download a free trial from the [**shinobicontrols** website](https://www.shinobicontrols.com).

You'll need to add the links to the **shinobiessentials** bundle to the project. Open up the project in Xcode, then open your **shinobiessentials** download in finder, and drag ShinobiEssentials.bundle from finder into Xcode's 'frameworks' group.

You'll also need drag ShinobiEssentials.framework into Xcode's 'frameworks' group.

If you're using the trial version you'll need to add your trial key. To do so, open up **PinBoardViewController.m** and add the following line inside `viewDidLoad`:

    [ShinobiEssentials setTrialKey:@"your license key"];

Contributing
------------

We'd love to see your contributions to this project - please go ahead and fork it and send us a pull request when you're done! Or if you have a new project you think we should include here, email info@shinobicontrols.com to tell us about it.

License
-------

The [Apache License, Version 2.0](LICENSE) applies to everything in this repository, and will apply to any user contributionshttps://github.com/ShinobiControls/play-charts-utils.git.
