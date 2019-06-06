defmodule SpellTest do
  use ExUnit.Case, async: true

  doctest Spell

  test "correction/1" do
    assert Spell.correction("speling") == "spelling"
    assert Spell.correction("korrectud") == "corrected"
    assert Spell.correction("bycycle") == "bicycle"
    assert Spell.correction("inconvient") == "inconvenient"
    assert Spell.correction("arrainged") == "arranged"
    assert Spell.correction("peotry") == "poetry"
    assert Spell.correction("peotryy") == "poetry"
    assert Spell.correction("word") == "word"
    assert Spell.correction("quintessential") == "quintessential"
  end

  test "probability/1" do
    assert Spell.probability("quintessential") == 0
    assert Spell.probability("the") > 0.07 and Spell.probability("the") < 0.08
  end

  test "dictionary/0" do
    dictionary = Spell.dictionary()
    assert map_size(dictionary) == 32_198
    assert dictionary |> Map.values() |> Enum.sum() == 1_115_585
    assert Map.get(dictionary, "the") == 79_809
  end

  test "most_common/1" do
    assert Spell.most_common(10) == [
             {"the", 79_809},
             {"of", 40_024},
             {"and", 38_312},
             {"to", 28_765},
             {"in", 22_023},
             {"a", 21_124},
             {"that", 12_512},
             {"he", 12_401},
             {"was", 11_410},
             {"it", 10_681}
           ]
  end

  test "performance for development set" do
    expected_results = %{good_rate: 76, n: 270, unknown_rate: 6}

    assert "fixtures/spell-testset1.txt"
           |> Path.expand(__DIR__)
           |> process_file()
           |> Map.delete(:words_second)
           |> Map.equal?(expected_results)
  end

  test "performance for final test set" do
    expected_results = %{good_rate: 69, n: 400, unknown_rate: 11}

    assert "fixtures/spell-testset2.txt"
           |> Path.expand(__DIR__)
           |> process_file()
           |> Map.delete(:words_second)
           |> Map.equal?(expected_results)
  end

  defp parse(lines) do
    for line <- lines,
        [right, wrongs] = String.split(line, ": ", parts: 2),
        wrong <- String.split(wrongs, " "),
        do: {right, wrong}
  end

  defp report(tests) do
    start = System.monotonic_time()

    n = Enum.count(tests)

    {good, unknown} =
      Enum.reduce(tests, {0, 0}, fn {right, wrong}, {good, unknown} ->
        word = Spell.correction(wrong)

        cond do
          word == right ->
            {good + 1, unknown}

          Map.has_key?(Spell.dictionary(), right) ->
            {good, unknown}

          true ->
            {good, unknown + 1}
        end
      end)

    dt = System.monotonic_time() - start
    seconds = System.convert_time_unit(dt, :native, :second)
    good_rate = trunc(round(good / n * 100))
    unknown_rate = trunc(round(unknown / n * 100))
    words_second = trunc(round(n / seconds))

    %{good_rate: good_rate, n: n, unknown_rate: unknown_rate, words_second: words_second}
  end

  defp process_file(file) do
    file
    |> File.read!()
    |> String.trim()
    |> String.split("\n")
    |> parse()
    |> report()
  end
end
