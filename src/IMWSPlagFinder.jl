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

function get_sorted_list_from_dict(d::Dict)
    key_list = Array{typeof(collect(keys(d))[1]),1}()
    value_list = Array{typeof(collect(values(d))[1]),1}()
    for k in keys(d)
        i = findfirst(x -> x < d[k], value_list)
        if isnothing(i)
            push!(value_list, d[k])
            push!(key_list, k)
        else
            insert!(value_list, i, d[k])
            insert!(key_list, i, k)
        end
    end
    return key_list, value_list
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

get_name(path, submissions_path, name_depth) = splitpath(path)[name_depth+length(splitpath(submissions_path))]

get_file_name(path) = splitpath(path)[end]

get_sub_path(path, submissions_path, name_depth) = joinpath(splitpath(path)[length(splitpath(submissions_path))+1:name_depth+length(splitpath(submissions_path))-1])

function get_summary(path, submissions_path, name_depth)
    return "$(get_name(path, submissions_path, name_depth)): $(get_file_name(path)) ($(get_sub_path(path, submissions_path, name_depth)))"
end

function summarize(diffs, plags, threshold, report_name)
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
        println("Take a closer look at the submissions, listed in the file $(report_name).txt!")
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
function compare_files(path, compare_from, compare_to, threshold; excluded=[], file_endings=[".m"], dc=[' ', '%'], report_path = "./", report_name="report", name_depth=3)
    database = generate_database(path; file_endings=file_endings, dc=dc)
    diffs = Dict{Tuple, Number}()
    plags = Dict{Tuple, Number}()
    @showprogress 0.1 "Comparing..." for k in keys(database)
        if contains_all_from_array(k, compare_from)
            for k2 in keys(database)
                if contains_one_from_array(k2, excluded)
                    continue
                end
                if k != k2 && contains_all_from_array(k2, compare_to)
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
                        "Alle Dateien, deren Pfad '$(compare_from)' enthält, wurden mit allen anderen Dateien verglichen, deren Pfad '$(compare_to)' enthält.",
                        "Dabei wurden alle Dateien ignoriert, deren Pfad folgende Teile enthält: $(replace("$(excluded)", '"' => "'")).",
                        "",
                        "Es wurden nur Dateien berücksichtigt die folgende Dateiendungen haben: $(replace("$(file_endings)", '"' => "'")).",
                        "Zusätzlich wurden foglende Zeichen beim Vergleich ignoriert: $(dc).",
                        "",
                        "Der Grenzwert der Levenshtein-Distanz wurde mit $(threshold) gewählt.",
                        "Die folgende Liste ist absteigend nach der Levenshtein-Distanz sortiert.",
                        "Eine größere Levenshtein-Distanz bedeutet eine größere Ähnlichkeit der Dateien.",
                        ""]
    sorted_keys_plags, sorted_values_plags = get_sorted_list_from_dict(plags)
    for i in 1:length(sorted_keys_plags)
        push!(out_array,"[] $(get_summary(sorted_keys_plags[i][1], path, name_depth)) -- $(get_summary(sorted_keys_plags[i][2], path, name_depth)) --> $(round(sorted_values_plags[i];digits=4))")
    end
    writedlm(joinpath(report_path,"$(report_name).txt"), out_array)
    summarize(diffs, plags, threshold, report_name)
end
end
