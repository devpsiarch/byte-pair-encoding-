defmodule Repserver do
  @moduledoc """
  This is supposed to be a server that given a bunch of parts of a string 
  pattern and replacement , it splits the strings to parts and replaces 
  each one of them in parallel, then concatenates them together. 
  """

  def init(),do: spawn(&serve/0)
  def kill(pid),do: Process.exit(pid,:kill)
  def init_pool(n) do
    Enum.reduce(1..n,%{},fn x,acc -> acc |> Map.put(x,init()) end)
  end
  def kill_pool(pool) do
    Enum.each(pool,fn {_index,pid} -> kill(pid) end)
  end

  def serve() do
    {caller,id,result} = receive do
      {:replace,caller,id,content,pattern,rep} -> 
        {caller,id,content |> String.replace(pattern,rep)}
    end
    send(caller,{:ok,id,result})
    serve()
  end

  def send_rep_job(server_pid,id,content,pattern,rep) do
    IO.puts("doing a job ...")
    send(server_pid,{:replace,self(),id,content,pattern,rep})
  end

  def assign_rep_job(pools,id,content,pattern,rep) do
    selected_server_pid = pools |> Map.get(:rand.uniform(map_size(pools)),0)
    send_rep_job(selected_server_pid,id,content,pattern,rep)
  end

  def get_any_result() do
    receive do
      {:ok,_id,result} -> result
    after 
      10_000 -> {:error,:timeout}
    end
  end

  def get_some_result(id) do
    receive do
      {:ok,^id,result} -> result
    after 
      10_000 -> {:error,:timeout}
    end   
  end

  def collect(samples) do 
    Enum.reduce(1..samples,"",fn _id,acc -> acc <> get_any_result() end) 
  end 
end
