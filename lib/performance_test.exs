defmodule Spell.Performance do
  @doc """
  Parse 'right: wrong1 wrong2' lines into [{'right', 'wrong1'}, {'right', 'wrong2'}] pairs
  """
  def parse(lines) do
    for line <- lines,
        [right, wrongs] = String.split(line, ": ", parts: 2),
        wrong <- String.split(wrongs, " "),
        do: {right, wrong}
  end

  @doc """
  Run correction(wrong) on all {right, wrong} pairs; report results.
  """
  def report(tests) do
    start = System.monotonic_time()

    n = Enum.count(tests)

    {good, unknown} =
      Enum.reduce(tests, {0, 0}, fn {right, wrong}, {good, unknown} ->
        word = Spell.correction(wrong)

        if word == right do
          {good + 1, unknown}
        else
          if Map.has_key?(Spell.dictionary(), right) do
            {good, unknown}
          else
            {good, unknown + 1}
          end
        end
      end)

    dt = System.monotonic_time() - start
    seconds = System.convert_time_unit(dt, :native, :seconds)
    good_rate = :erlang.float_to_list(good / n * 100, decimals: 0)
    unknown_rate = :erlang.float_to_list(unknown / n * 100, decimals: 0)
    words_second = :erlang.float_to_list(n / seconds, decimals: 0)

    IO.puts(
      "#{good_rate}% of #{n} correct (#{unknown_rate}% unknown) at #{words_second} words per second"
    )
  end

  def run do
    ["lib/spell-testset1.txt", "lib/spell-testset2.txt"]
    |> Enum.each(fn file ->
         file
         |> File.read!()
         |> String.trim()
         |> String.split("\n")
         |> Spell.Performance.parse()
         |> Spell.Performance.report()
       end)
  end
end
