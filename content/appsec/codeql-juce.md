+++
title = "CodeQL on a JUCE audio app"
date = "2023-03-30"
toc = true
aliases = ["appsec"]
tags = ["codeql"]
categories = ["security", "software", "dev"]
[ author ]
  name = "onereddog"
+++

## Introduction
Over the past few years I've been working on a new software synthensizer. It's written in C++ using the fantastic [JUCE](https://juce.com/) framework. Being C++ has many advantages for this type of
application. It's cross-platform for iOS, MacOS, Windows, and Linux. It's compact. It's efficient for real-time audio processing. But of course, the dark side of the language often gives it a bit of a
tarnished image, particularly compared to newer programming languages. Your app can crash. easily.

I do most of my C++ coding in Xcode for Mac. I have been doing this now since about Xcode 2.0 (I forget the exact version but let's say about 20 years). Xcode has evolved a lot over the years.
It's probably still not as good as Visual Studio, I used that quite regularly in various day jobs, but I know enough Xcode to get by. Apple have also improved a lot of the debugging features. 
Memory allocation issues, stack scribbles, threading race conditions, and so on. All these help to ensure your app is stable. Or as stable as it can be. Writing software synthesizers, and in particular
plugins, also opens you up to tools like `auval` and [pluginval](https://github.com/Tracktion/pluginval). If it doesn't crash in these tools, you have a decent chance you're going to be just fine.

Using three different compilers (llvm, gcc, msvc) can often help with finding issues, as each compiler has its own interpretation of warnings. Also building across different CPU and operating
systems can often highlight subtle memory defects. This is where [CodeQL](https://codeql.github.com/) can come in useful. CodeQL is the code analysis engine developed by GitHub to automate security checks.
What security folk call SAST or Static Application Security Testing. In other words, an advanced lint tool with a rule set that is tailored to look for bugs in your code. CodeQL does this by compiling your
C++ project and directly querying the abstract syntax tree. This gives a deeper view into the data flow, rather than simply running grep's. 

CodeQL was originally developed at the University of Oxford and commercialized by [Semmle Ltd](https://en.wikipedia.org/wiki/Semmle). GitHub (Microsoft) acquired the company in 2019. The QL query language
is a based on Datalog which itself is in the family of Prolog. The queries themselves are challenging to write, but fortunately GitHub provide a comprehensive set of query packs that have been written
and vetted by their security researchers.

As CodeQL treats code like data, you are able to find potential vulnerabilities in your code with greater confidence than traditional static analyzers.

1. You generate a CodeQL database to represent your codebase.
2. Then you run CodeQL queries on that database to identify problems in the codebase.
3. The query results are shown as code scanning alerts in GitHub when you use CodeQL with code scanning, or as CSV or JSON files.


## Installing CodeQL 
If you use Microsoft Visual Studio Code, the easiest way to get started is to install Microsoft's extension [CodeQL for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-codeql).

On the Mac, this extension installs into `$HOME/Library/Application Support/Code/User/globalStorage/github.vscode-codeql/distributionX` where X is some value. This value changes each time the extension is
updated. To make this work from the command line, I have something like the following in my `~/.zshrc` file:

```shell
export CODEQL="$HOME/Library/Application Support/Code/User/globalStorage/github.vscode-codeql/distribution7/codeql"
PATH=$PATH:$CODEQL
```

To test it's working, simply do `codeql -h` and you should see the CodeQL command help info.

## Creating the database
The first step is to build the database. CodeQL needs to be able to compile your code. To facilitate this my JUCE based project builds with `cmake`. This also helps with GitHub Actions and being able to
build cross-platform. I'm not 100% certain what `cmake` commands CodeQL runs but it's clever enough to work out how to build the project.

```shell
$ codeql database create --language="cpp" ./db --overwrite
```

The database is written into the directory `./db` and the `--overwrite` option is used to overwrite any existing database, useful when we are iterating on fixing the findings.

## Analyzing
The second step is to actually analyze the database. This involves running a query pack across the database. I simply use GitHub's `security-and-quality` pack. GitHub provide two packs:

* `security-extended`	Queries from the default suite, plus lower severity and precision queries
* `security-and-quality` Queries from security-extended, plus maintainability and reliability queries

I prefer the second one, as it has more queries.

This command will run the analyzer and download the latest pack. 

```shell
$ codeql database analyze --format=sarif-latest --output=codeql-sec.sarif ./db 'codeql/cpp-queries:codeql-suites/cpp-security-and-quality.qls' --download
```

Results are written to a text file in [SARIF](https://sarifweb.azurewebsites.net/) format. Other options include CSV. This step can take a long time to run, so be patient. As an aside, we really need
to get CodeQL running interactively within the IDE, in the same way InteliiSense does today. Until then, wait for the results.

## Viewing the results
SARIF (Static Analysis Results Interchange Format) is my preferred output format. It's a JSON file so it's supported by a lot of tools. If you have GitHub Advanced Security, you can load the SARIF
file directly into the repository's security tab and view the findings. Alternatively, you can use Microsoft's [Sarif Viewer](https://marketplace.visualstudio.com/items?itemName=MS-SarifVSCode.sarif-viewer)
extension for VSCode. 

Open the `codeql-sec.sarif` file into VSCode, then from the command panel select `SARIF: Show Panel`. The results are nicely structured by query category or by file.

Now simpy go through the findings, treat them like compiler warnings, and fix them.

