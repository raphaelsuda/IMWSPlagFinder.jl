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

The first method searches for text files in the given `path`, reads those files, and calculates the Levenshtein distance for each combination of two files.
If the Levenshtein distance is larger than the given threshold, the given combination is written to a file `report.txt`, which is saved in the current working directory.

The second method allows for filtering the files, included in the comparison.
The arguments `compare_from` and `compare_to` expect arrays of Strings as input and filter the file results in the following way.
Only those text files in `path`, which contain each string in `compare_from` in their file_path, are compared to all files, which contain each string in `compare_to` in their file path.
The intended use case for this method is to compare recent submissions to a databse of older submissions.