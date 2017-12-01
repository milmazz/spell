defmodule Spell do
  @moduledoc """
  Spell Corrector

  Inspired by Peter Norvig's essay: http://norvig.com/spell-correct.html

  """
  @external_resource "lib/big.txt"

  @pattern Regex.compile!("\\w+")
  @words File.stream!("lib/big.txt")
         |> Stream.flat_map(fn line ->
              @pattern |> Regex.scan(String.downcase(line)) |> List.flatten()
            end)
         |> Enum.reduce(%{}, fn word, acc -> Map.update(acc, word, 1, &(&1 + 1)) end)

  @dictionary_values @words |> Map.values() |> Enum.sum()

  @doc """
  Probability of word
  """
  def probability(word), do: Map.get(@words, word, 0) / @dictionary_values

  @doc """
  Most probable spelling correction for word
  """
  def correction(word), do: word |> candidates() |> Enum.max(&probability/1)

  @doc """
  Generate possible spelling correction for word
  """
  def candidates(word) do
    cond do
      (candidates = known([word])) != [] ->
        candidates

      (candidates = word |> edits1() |> known()) != [] ->
        candidates

      (candidates = word |> edits2() |> known()) != [] ->
        candidates

      true ->
        [word]
    end
  end

  @doc """
  The subset or words that appear in the dictionary of words
  """
  def known(words) do
    for w <- words, Map.has_key?(@words, w), do: w
  end

  @doc """
  All edits that are one edit away from word
  """
  def edits1(word) do
    letters = String.codepoints("abcdefghijklmnopqrstuvwxyz")
    word_length = String.length(word)

    splits =
      for i <- Range.new(0, word_length), do: {
        String.slice(word, 0, i),
        String.slice(word, i, word_length)
      }

    deletes = for {l, r} <- splits, r != "", do: l <> String.slice(r, 1, word_length)

    transposes =
      for {l, r} <- splits,
          String.length(r) > 1,
          do: l <> String.at(r, 1) <> String.at(r, 0) <> String.slice(r, 2, word_length)

    replaces =
      for {l, r} <- splits,
          c <- letters,
          r != "",
          do: l <> c <> String.slice(r, 1, word_length)

    inserts =
      for {l, r} <- splits,
          c <- letters,
          do: l <> c <> r

    Enum.uniq(deletes ++ transposes ++ replaces ++ inserts)
  end

  @doc """
  All edits that are two edits away from word.
  """
  def edits2(word) do
    for e1 <- edits1(word),
        e2 <- edits1(e1),
        do: e2
  end

  ## Helpers
  def dictionary, do: @words

  def most_common(amount) do
    @words
    |> Enum.sort(fn {_, x}, {_, y} -> x >= y end)
    |> Enum.take(amount)
  end
end
