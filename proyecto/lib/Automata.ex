defmodule FiniteAutomaton do
  @moduledoc """
  Implementación del algoritmo de determinización de Rabin-Scott (Powerset Construction).
  Convierte un Autómata Finito No Determinista (NFA) en uno Determinista (DFA).

  Representación del autómata como tupla de 5 elementos:
    {Q, Sigma, delta, q0, F}
    - Q     : lista de estados
    - Sigma : lista de símbolos del alfabeto
    - delta : función de transición como mapa %{{estado, símbolo} => [estados]}
    - q0    : estado inicial
    - F     : lista de estados finales
  """

  # ---------------------------------------------------------------------------
  # 1. NFA de ejemplo del enunciado
  #    Estados: 0, 1, 2, 3
  #    Alfabeto: a, b
  #    Transiciones:
  #      0 --a--> {0, 1}
  #      0 --b--> {0}
  #      1 --b--> {2}
  #      2 --b--> {3}
  #    Estado inicial: 0
  #    Estados finales: {3}
  # ---------------------------------------------------------------------------
  def nfa_example() do
    q      = [0, 1, 2, 3]
    sigma  = [:a, :b]
    delta  = %{
      {0, :a} => [0, 1],
      {0, :b} => [0],
      {1, :b} => [2],
      {2, :b} => [3]
    }
    q0     = 0
    f      = [3]

    {q, sigma, delta, q0, f}
  end

  # ---------------------------------------------------------------------------
  # 2. Algoritmo de determinización (Powerset Construction)
  # ---------------------------------------------------------------------------

  @doc """
  Recibe un NFA {Q, Sigma, delta, q0, F} y devuelve el DFA equivalente
  {Q', Sigma, delta', q0', F'} donde los estados de Q' son subconjuntos de Q.
  """
  def determinize({_q, sigma, delta, q0, f}) do
    # Estado inicial del DFA: {q0}
    start_set = MapSet.new([q0])

    # Explorar estados por BFS
    {dfa_states, dfa_delta} = explore([start_set], sigma, delta, MapSet.new([start_set]), %{})

    # Estados finales del DFA: subconjuntos que intersectan con F
    f_set = MapSet.new(f)
    dfa_f =
      dfa_states
      |> Enum.filter(fn state_set -> not MapSet.disjoint?(state_set, f_set) end)

    dfa_q  = dfa_states
    dfa_q0 = start_set

    {dfa_q, sigma, dfa_delta, dfa_q0, dfa_f}
  end

  # Explora todos los estados del DFA de forma iterativa (BFS)
  defp explore([], _sigma, _delta, _visited, acc_delta), do: {MapSet.to_list(_visited), acc_delta}

  defp explore([current_set | rest], sigma, delta, visited, acc_delta) do
    # Para cada símbolo, calcular δ'(current_set, a) = ⋃ δ(q, a) para q ∈ current_set
    {new_sets, new_delta} =
      Enum.reduce(sigma, {[], acc_delta}, fn symbol, {new_acc, delta_acc} ->
        target_set =
          current_set
          |> MapSet.to_list()
          |> Enum.flat_map(fn q -> Map.get(delta, {q, symbol}, []) end)
          |> MapSet.new()

        updated_delta = Map.put(delta_acc, {current_set, symbol}, target_set)

        if MapSet.member?(visited, target_set) or MapSet.size(target_set) == 0 do
          {new_acc, updated_delta}
        else
          {[target_set | new_acc], updated_delta}
        end
      end)

    new_visited = Enum.reduce(new_sets, visited, &MapSet.put(&2, &1))
    explore(rest ++ new_sets, sigma, delta, new_visited, new_delta)
  end

  # ---------------------------------------------------------------------------
  # 3. Helpers de visualización
  # ---------------------------------------------------------------------------

  @doc "Imprime el autómata de forma legible."
  def print_automaton({q, sigma, delta, q0, f}, label \\ "Autómata") do
    IO.puts("\n========== #{label} ==========")
    IO.puts("Estados Q  : #{inspect(Enum.map(q, &format_state/1))}")
    IO.puts("Alfabeto Σ : #{inspect(sigma)}")
    IO.puts("Inicial q0 : #{format_state(q0)}")
    IO.puts("Finales F  : #{inspect(Enum.map(f, &format_state/1))}")
    IO.puts("Transiciones δ:")

    delta
    |> Enum.sort_by(fn {{s, sym}, _} -> {format_state(s), sym} end)
    |> Enum.each(fn {{state, sym}, targets} ->
      IO.puts("  δ(#{format_state(state)}, #{sym}) = #{format_state(targets)}")
    end)

    IO.puts("=" |> String.duplicate(40))
  end

  defp format_state(%MapSet{} = ms) do
    ms |> MapSet.to_list() |> Enum.sort() |> inspect()
  end
  defp format_state(s), do: inspect(s)

  # ---------------------------------------------------------------------------
  # 4. Tests unitarios
  # ---------------------------------------------------------------------------

  @doc """
  Ejecuta los tests unitarios verificando que el DFA resultante
  acepta/rechaza las mismas cadenas que el NFA original.
  """
  def run_tests() do
    IO.puts("\n========== TESTS UNITARIOS ==========")

    nfa = nfa_example()
    dfa = determinize(nfa)

    # Casos de prueba: {cadena, resultado_esperado}
    test_cases = [
      {[:a, :b, :b],          true,  "abb  → acepta (llega a estado 3)"},
      {[:b, :b, :b],          false, "bbb  → rechaza (nunca llega a 3)"},
      {[:a, :a, :b, :b],      true,  "aabb → acepta"},
      {[:a, :b, :b, :b, :b],  false, "abbbb→ rechaza (desde 3 no hay transición b)"},
      {[:a],                  false, "a    → rechaza (no termina en 3)"},
      {[],                    false, "ε    → rechaza (vacía)"},
      {[:b],                  false, "b    → rechaza"},
      {[:a, :b],              false, "ab   → rechaza (solo 2 pasos)"}
    ]

    results =
      Enum.map(test_cases, fn {input, expected, desc} ->
        got = accepts?(dfa, input)
        status = if got == expected, do: "✅ PASS", else: "❌ FAIL"
        IO.puts("#{status} | #{desc} | esperado=#{expected} obtenido=#{got}")
        got == expected
      end)

    passed = Enum.count(results, & &1)
    total  = length(results)
    IO.puts("\nResultado: #{passed}/#{total} tests pasados.")
    IO.puts("=" |> String.duplicate(40))
  end

  @doc "Simula el DFA con una cadena de entrada; devuelve true si es aceptada."
  def accepts?({_q, _sigma, delta, q0, f}, input) do
    # El estado inicial del DFA siempre es un MapSet
    start = if is_struct(q0, MapSet), do: q0, else: MapSet.new([q0])

    final_state =
      Enum.reduce(input, start, fn symbol, current ->
        Map.get(delta, {current, symbol}, MapSet.new())
      end)

    # Los estados finales del DFA son MapSets; comparamos por igualdad
    final_state in f
  end
end

# ---------------------------------------------------------------------------
# Punto de entrada: ejecutar todo
# ---------------------------------------------------------------------------
nfa = FiniteAutomaton.nfa_example()
FiniteAutomaton.print_automaton(nfa, "NFA Original")

dfa = FiniteAutomaton.determinize(nfa)
FiniteAutomaton.print_automaton(dfa, "DFA Resultante (Powerset Construction)")

FiniteAutomaton.run_tests()
