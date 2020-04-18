-file("lib/jwp/channel_config.ex", 1).

-module('Elixir.Jwp.ChannelConfig').

-compile([no_auto_import]).

-export(['MACRO-rchan'/1,
         'MACRO-rchan'/2,
         'MACRO-rchan'/3,
         '__info__'/1,
         format/1,
         from_map/1]).

-spec '__info__'(attributes | compile | functions | macros | md5 |
                 module | deprecated) ->
                    any().

'__info__'(module) ->
    'Elixir.Jwp.ChannelConfig';
'__info__'(functions) ->
    [{format, 1}, {from_map, 1}];
'__info__'(macros) ->
    [{rchan, 0}, {rchan, 1}, {rchan, 2}];
'__info__'(Key = attributes) ->
    erlang:get_module_info('Elixir.Jwp.ChannelConfig', Key);
'__info__'(Key = compile) ->
    erlang:get_module_info('Elixir.Jwp.ChannelConfig', Key);
'__info__'(Key = md5) ->
    erlang:get_module_info('Elixir.Jwp.ChannelConfig', Key);
'__info__'(deprecated) ->
    [].

format({rchan, _pt@1, _pd@1, _wj@1, _wl@1}) ->
    <<"#<ChannelConfig presence_track: ",
      case _pt@1 of
          _@1 when is_binary(_@1) ->
              _@1;
          _@1 ->
              'Elixir.String.Chars':to_string(_@1)
      end/binary,
      ", presence_diffs: ",
      case _pd@1 of
          _@2 when is_binary(_@2) ->
              _@2;
          _@2 ->
              'Elixir.String.Chars':to_string(_@2)
      end/binary,
      ", webhook_join: ",
      case _wj@1 of
          _@3 when is_binary(_@3) ->
              _@3;
          _@3 ->
              'Elixir.String.Chars':to_string(_@3)
      end/binary,
      ", webhook_leave: ",
      case _wl@1 of
          _@4 when is_binary(_@4) ->
              _@4;
          _@4 ->
              'Elixir.String.Chars':to_string(_@4)
      end/binary,
      ">">>.

from_map(_map@1) when is_map(_map@1) ->
    {_fields@1, _} =
        'Elixir.Map':split(_map@1,
                           [presence_track, presence_diffs,
                            webhook_join, webhook_leave]),
    'Elixir.Record':'__keyword__'(rchan,
                                  [{presence_track, false},
                                   {presence_diffs, false},
                                   {webhook_join, false},
                                   {webhook_leave, false}],
                                  _fields@1).

'MACRO-rchan'(_@CALLER) ->
    __CALLER__ = elixir_env:linify(_@CALLER),
    'MACRO-rchan'(__CALLER__, []).

'MACRO-rchan'(_@CALLER, _@1) ->
    __CALLER__ = elixir_env:linify(_@CALLER),
    'Elixir.Record':'__access__'(rchan,
                                 [{presence_track, false},
                                  {presence_diffs, false},
                                  {webhook_join, false},
                                  {webhook_leave, false}],
                                 _@1, __CALLER__).

'MACRO-rchan'(_@CALLER, _@1, _@2) ->
    __CALLER__ = elixir_env:linify(_@CALLER),
    'Elixir.Record':'__access__'(rchan,
                                 [{presence_track, false},
                                  {presence_diffs, false},
                                  {webhook_join, false},
                                  {webhook_leave, false}],
                                 _@1, _@2, __CALLER__).

