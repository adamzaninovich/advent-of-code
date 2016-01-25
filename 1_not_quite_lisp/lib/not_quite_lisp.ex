defmodule NotQuiteLisp.State do
  defstruct floor: 0, iteration: 0
end

defmodule NotQuiteLisp do
  use GenServer
  alias NotQuiteLisp.State

  # Client

  def start_link do
    {:ok, pid} = GenServer.start_link(__MODULE__, %State{})
    pid
  end

  def current_floor(pid) do
    GenServer.call(pid, :get_floor)
  end

  def current_iteration(pid) do
    GenServer.call(pid, :get_iteration)
  end

  def process_direction(pid, direction) do
    GenServer.cast(pid, {:direction, direction})
  end

  def process_directions(pid, directions) do
    directions
    |> direction_stream
    |> Enum.each(fn(direction) ->
      NotQuiteLisp.process_direction(pid, direction)
    end)
  end

  def process_directions_stopping_at_basement(pid, directions) do
    directions
    |> direction_stream
    |> Enum.each(fn(direction) ->
      GenServer.cast(pid, {:no_basement, direction})
    end)
  end

  defp direction_stream(directions) do
    directions
    |> Stream.unfold(&String.next_codepoint/1)
  end

  # Server

  def handle_call(:get_floor, _from, state) do
    {:reply, state.floor, state}
  end

  def handle_call(:get_iteration, _from, state) do
    {:reply, state.iteration, state}
  end

  def handle_cast({:no_basement, dir}, state = %State{floor: -1}) do
    {:noreply, state}
  end
  def handle_cast({:no_basement, dir}, %State{floor: floor, iteration: iteration}) do
    state = %State{floor: get_new_floor(floor, dir), iteration: iteration + 1}
    {:noreply, state}
  end

  def handle_cast({:direction, dir}, %State{floor: floor, iteration: iteration}) do
    state = %State{floor: get_new_floor(floor, dir), iteration: iteration + 1}
    {:noreply, state}
  end

  defp get_new_floor(floor, "("), do: floor + 1
  defp get_new_floor(floor, ")"), do: floor - 1
end
