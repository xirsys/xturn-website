### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### XTurn is licensed by Xirsys under the Apache License, Version 2.0.
### See LICENSE for the full license text.
###
### ----------------------------------------------------------------------

defmodule Xirsys.XTurn.Actions.ChannelData do
  @doc """
  Handles incoming channel data. We route this directly to the peers, if they exist and
  have valid channels open.
  """
  require Logger
  alias Xirsys.XTurn.Channels.Store, as: Channels
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn

  def process(%Conn{is_control: true}) do
    Logger.debug("cannot send channel data on control connection")
    false
  end

  def process(%Conn{message: <<channel::16, _length::16, data::binary>>} = conn) do
    Logger.debug(
      "channel data (#{byte_size(data)} bytes) received on channel #{inspect(channel)}"
    )

    proto = :_
    tuple5 = Tuple5.to_map(Tuple5.create(conn, proto))

    case Channels.lookup({channel, tuple5}) do
      {:ok, [[client, _peer_address, socket, channel_cache] | _tail]} ->
        # already short circuited
        AllocateClient.send_channel(client, channel, data, socket, channel_cache)
        conn

      {:error, :not_found} ->
        Logger.debug("channel #{inspect(channel)} does not exist in ETS")
        false
    end
  end
end
