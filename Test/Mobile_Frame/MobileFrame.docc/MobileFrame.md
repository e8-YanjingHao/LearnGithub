# ``MobileFrame``

## Project Description
``MobileFrame`` project for the company to develop a set of handheld support to access the Dashboard page framework , the use of this framework can be built on the web-based hybrid development model , and provide a native operating experience .

### This framework includes the following functional modules

- webview offline caching
- js interaction
- session management
- dashboard resource management
- web native jump

## Project files

``MobileFrame`` Framework project, used to develop the underlying functionality and logic
``MobileFrameExampleApp`` test project, used to test whether the Framework can run properly
``Pods`` project third-party dependency management

## Component introduction

- Auth
- Core
- Net
- Store
- Utils
- WebView

## Environment configuration

1. Framework minimum support ios10 and above
2. The Framework will not be packaged with the third-party libraries, so developers need to download the dependencies according to the documentation.
3. Compile and run only the real or emulator version of Framework, it is recommended to use the ``Run_script_merge`` Target integrated in the project for packaging.

## Development process

1. Double click the ``MobileFrame.xcworkspace`` entry file to enter the project
2. Develop the framework function in the ``MobileFrame`` directory
3. After the function is developed, import the files that need to be exposed to the outside in Build Phases -- Headers -- Public
4. switch the Taget of ``MobileFrame`` project to ``Run_script_merge``
5. ``Command+B`` to compile, after successful compilation, the Framework library file directory ``MobileFrame_Products`` will pop up in the current window.
6. You can also right-click ``Products`` directory in the project directory and show in folder to see the packaged .framework package file
7. Add the .framework to the Frameworks directory of ``MobileFrameExampleApp``.
8. Conduct the functional test of the Framework development package
