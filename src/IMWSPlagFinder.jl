module IMWSPlagFinder
using Dates
using DelimitedFiles
using ProgressMeter
using StringDistances
using Statistics

export compare_files

function contains_one_from_array(haystack::AbstractString, needles::Array)
    for needle in needles
        if contains(haystack, needle)
            return true
        end
    end
    return false
end

function contains_all_from_array(haystack::AbstractString, needles::Array)
    for needle in needles
        if !contains(haystack, needle)
            return false
        end
    end
    return true
end

# Berechnet die Levenshtein-Distanz von zwei Strings
function levenshtein(s1::String,s2::String)
    compare(s1,s2,Levenshtein())
end

# Liest die uebergebene Datei als durchgehenden String ohne Zeilenumbrueche ein
# und loescht alle angegebenen Characters aus diesem String
function func2string(f, dc)
    s = join(readlines(f))
    for c in dc
        s = replace(s,c=>"")
    end
    return s
end

function read_files!(file_dict, path, file_endings, dc)
    files = readdir(path)
    for f in files
        current_path = joinpath(path, f)
        if isdir(current_path)
            read_files!(file_dict, current_path, file_endings, dc)
        else
            for fe in file_endings
                if endswith(f, fe)
                    # @show current_path
                    file_dict[current_path] = func2string(current_path, dc)
                end
            end
        end
    end
end

function generate_database(path; file_endings=[".m"], dc=[' ', '%'])
    file_dict = Dict{AbstractString, AbstractString}()
    read_files!(file_dict, path, file_endings, dc)
    return file_dict
end

function summarize(diffs, plags, threshold)
    # Alle Levenshtein-Distanzen in einem Array sammeln und median bzw 99%-Quantile berechnen
    a = Float64[]
    for n in keys(diffs)
        push!(a,diffs[n])
    end
    median_diff = median(a)
    quantile_99_diff = quantile(a,0.99)
    n_plags = length(values(plags))
    # Zusammenfassung ausgeben
    if n_plags > 0
        println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        println("I found $(n_plags) cases of possible plagiarism!")
        println(" median = $(round(median_diff;digits=3)), q_99 = $(round(quantile_99_diff;digits=3))")
        println("The Levenshtein-threshold was set to $(threshold).")
        println("Take a closer look at the submissions, listed in the files plags_filename.txt!")
        println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    else
        println("-------------------------------------------------------")
        println("I couldn't find any cases of plagiarism.")
        println("I guess that's a good sign,")
        println("but maybe you should change the threshold,")
        println("just to be sure.")
        println("-------------------------------------------------------")
    end
end
function compare_files(path, compare_A, compare_B, threshold; excluded=[], file_endings=[".m"], dc=[' ', '%'], report_path="")
    database = generate_database(path; file_endings=file_endings, dc=dc)
    diffs = Dict{Tuple, Number}()
    plags = Dict{Tuple, Number}()
    @showprogress 0.1 "Comparing..." for k in keys(database)
        if contains_all_from_array(k, compare_A)
            for k2 in keys(database)
                if contains_one_from_array(k2, excluded)
                    continue
                end
                if k != k2 && contains_all_from_array(k2, compare_B)
                    l = levenshtein(database[k], database[k2])
                    diffs[(k, k2)] = l
                    if l >= threshold
                        plags[(k, k2)] = l
                    end
                end
            end
        end
    end
    # Alle vermutlichen Plagiate mit der Levenshtein-Distanz in Datei schreiben
    out_array = String["# Plagiats-Bericht",
                        "$(today())",
                        "",
                        "Alle Dateien, deren Pfad '$(compare_A)' enthält, wurden mit allen anderen Dateien verglichen, deren Pfad '$(compare_B)' enthält.",
                        "Dabei wurden alle Dateien ignoriert, deren Pfad folgende Teile enthält: $(replace("$(excluded)", '"' => "'")).",
                        "",
                        "Es wurden nur Dateien berücksichtigt die folgende Dateiendungen haben: $(replace("$(file_endings)", '"' => "'")).",
                        "Zusätzlich wurden foglende Zeichen beim Vergleich ignoriert: $(dc).",
                        "",
                        "Der Grenzwert der Levenshtein-Distanz wurde mit $(threshold) gewählt.",
                        ""]
    for t in keys(plags)
        push!(out_array,"[] $(t[1]) -- $(t[2]) --> $(round(diffs[t];digits=4))")
    end
    writedlm("plags_$(replace(compare_A, '/' => '_'))_vs_$(replace(compare_B, '/' => '_')).txt", out_array)
    summarize(diffs, plags, threshold)
end
end
