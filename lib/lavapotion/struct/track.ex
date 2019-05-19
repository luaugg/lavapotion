defmodule LavaPotion.Struct.Track do
  @type t :: %__MODULE__{identifier: String.t(), is_seekable?: boolean(), is_stream?: boolean(),
    author: String.t(), length: integer(), position: integer(), title: String.t(),
    uri: String.t()}

  @doc """
  Defines a new `LavaPotion.Struct.Track` struct.
  Refer to the typedocs to see the types of these fields.

  `:identifier` - The identifier of the track.
  `:is_seekable?` - Whether or not this track is a track which can be seeked through.
  `:is_stream?` - Whether or not this track is a livestream.
  `:author` - The author of this track. For YouTube Videos, this is the channel name.
  `:length` - The length of this track in milliseconds.
  `:position` - The track's current position in milliseconds.
  `:title` - The title/name of this track.
  `:uri` - The direct URI/link to this track.
  """
  defstruct [:identifier, :is_seekable?, :is_stream?, :author, :length, :position, :title, :uri]
end
