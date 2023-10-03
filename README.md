# IMWSPlagFinder

[![Build Status](https://github.com/raphaelsuda/IMWSPlagFinder.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/raphaelsuda/IMWSPlagFinder.jl/actions/workflows/CI.yml?query=branch%3Amain)

A Julia package for finding possibly plagiarised files.
The main function compares text files, calculates their Levenshtein distance, and generates an report containing comparisons, which exceed a certain threshold.

## Installation
Install within Julia in the Pkg REPL-mode using

```jl
add https://github.com/raphaelsuda/IMWSPlagFinder.jl
```

## Introduction

Start using IMWSPlagFinder by executing `using IMWSPlagFinder` in the REPL or a script.

The core function is `compare_files` with two different methods.
- `compare_files(path, threshold)` and
- `compare_files(path, compare_from, compare_to, threshold)`.

The first method searches for text files in the given `path`, reads those files, deletes all new line characters, and calculates the Levenshtein distance for each combination of two files.
If the Levenshtein distance is larger than the given threshold, the given combination is written to a file `report.txt`, which is saved in the current working directory.

The second method allows for filtering the files, included in the comparison.
The arguments `compare_from` and `compare_to` expect arrays of Strings as input and filter the file results in the following way.
Only those text files in `path`, which contain each string in `compare_from` in their file_path, are compared to all files, which contain each string in `compare_to` in their file path.
The intended use case for this method is to compare recent submissions to a databse of older submissions.

Both methods also take the following additional keyword arguments (values after equal sign are the default values):
- `excluded = []`: Files are excluded from comparison, if their file path contains at least **one** of the Strings in `excluded`.
- `file_endings = [".m"]`: Only files with the given endings in the Array `file_endings` are considered in the comparison.
- `chars_to_delete = [' ', '%']`: Characters included in `chars_to_delete` are removed from the files before comparison.
- `report_path = "./"`: Path, where the report should be saved.
- `report_name = "report"`: Name of the report.
- `name_depth = 3`: Level of the name folder relative to the given `path`. If the file path is `"submissions/WS23/HUE1/name/func.m"` and the input for `path` is `"submissions"`, `name_depth` would be `3`.

