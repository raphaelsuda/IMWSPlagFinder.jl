# IMWSPlagFinder

[![Build Status](https://github.com/raphaelsuda/IMWSPlagFinder.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/raphaelsuda/IMWSPlagFinder.jl/actions/workflows/CI.yml?query=branch%3Amain)

A Julia package for finding possibly plagiarised files.
The main function compares text files, calculates their Levenshtein distance, and generates an report containing comparisons, which exceed a certain threshold.